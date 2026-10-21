// create-checkout — Supabase Edge Function
// ---------------------------------------------------------------------------
// Creates a Stripe Checkout Session for either a cecespieces ARTWORK (piece_id)
// or an ACADEMY CLASS (class_id) and returns its URL. The PRICE IS ALWAYS READ
// FROM THE DATABASE (service role), never trusted from the browser, so a visitor
// can't tamper with the amount. It records a pending order (and, for a class, a
// pending enrollment) for the hub; the stripe-webhook function confirms it on pay.
//
// Deploy:  supabase functions deploy create-checkout
// Secrets: supabase secrets set STRIPE_SECRET_KEY=sk_live_...  SITE_URL=https://cecespieces.com
//          (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically)
// ---------------------------------------------------------------------------
// Deno-native Stripe build (Supabase's own examples use esm.sh ?target=deno).
// The npm: build's default Node HTTP client fails in the edge runtime with
// "An error occurred with our connection to Stripe".
import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";

// Strip ALL whitespace from the secret. Pasting the long key into a terminal
// can wrap and inject a newline anywhere (even mid-key); any whitespace makes
// an invalid Authorization header that surfaces as a Stripe "connection error".
// Stripe keys never contain whitespace, so removing it all is safe.
import { appConfig } from "../_shared/config.ts";

// Stripe client built per request from the current key (see _shared/config.ts).
let stripe: Stripe;
let stripeKey = "";
async function initStripe(): Promise<string> {
  const k = (await appConfig("STRIPE_SECRET_KEY")).replace(/\s+/g, "");
  if (!stripe || k !== stripeKey) {
    stripeKey = k;
    stripe = new Stripe(k, { apiVersion: "2024-06-20", httpClient: Stripe.createFetchHttpClient() });
  }
  return k;
}
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

// Create a session; if a synced product id belongs to the other Stripe mode
// (test vs live) or was removed, retry once with a plain product name.
async function createSession(params: Stripe.Checkout.SessionCreateParams, fallbackName: string) {
  try { return await stripe.checkout.sessions.create(params); }
  catch (e) {
    if (!/No such product/i.test(String((e as Error)?.message))) throw e;
    const li = params.line_items![0];
    const { product: _p, ...pd } = li.price_data as Stripe.Checkout.SessionCreateParams.LineItem.PriceData;
    return await stripe.checkout.sessions.create({ ...params, line_items: [{ ...li, price_data: { ...pd, product_data: { name: fallbackName } } }] });
  }
}

const db = (path: string, init?: RequestInit) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", ...(init?.headers || {}) },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    await initStripe();
    const SITE_URL = ((await appConfig("SITE_URL")) || "https://cecespieces.com").replace(/\/$/, "");
    const body = await req.json().catch(() => ({}));
    const { piece_id, class_id, student_name, student_email } = body;
    // _test: the go-live workflow's smoke test — create the Stripe session but
    // don't log an order, so tests never show up in the hub as real orders.
    const isTest = body._test === true;

    // ── PROBE: POST {"_ping":true} — reports key shape + raw Stripe reachability
    if (body._ping) {
      const raw = await appConfig("STRIPE_SECRET_KEY");
      const clean = raw.replace(/\s+/g, "");
      const out: Record<string, unknown> = {
        raw_len: raw.length,
        clean_len: clean.length,
        had_whitespace: raw.length !== clean.length,
        starts: clean.slice(0, 8),
        ends: clean.slice(-4),
      };
      try {
        const g = await fetch("https://api.stripe.com/v1/balance", {
          headers: { Authorization: `Bearer ${clean}` },
        });
        out.stripe_status = g.status;
        out.stripe_body = (await g.text()).slice(0, 150);
      } catch (e) { out.stripe_fetch_error = String((e as Error)?.message || e); }
      return json(out);
    }


    // ─────────────────────────── CLASS PURCHASE ───────────────────────────
    if (class_id) {
      const r = await db(`classes?id=eq.${encodeURIComponent(class_id)}&select=*`);
      const rows = await r.json();
      const cls = Array.isArray(rows) ? rows[0] : null;
      if (!cls) return json({ error: "Class not found" }, 404);
      if (cls.active === false) return json({ error: "This class isn't open for enrollment right now." }, 409);
      if (cls.type === "live" && cls.seats_left != null && Number(cls.seats_left) <= 0)
        return json({ error: "This live class is full — join the waitlist." }, 409);

      const amount = Math.round(parseFloat(cls.price) * 100);
      if (!amount || amount < 50) return json({ error: "This class has no price set — please inquire." }, 400);

      const session = await createSession({
        mode: "payment",
        line_items: [{
          quantity: 1,
          price_data: {
            currency: "usd",
            unit_amount: amount,
            ...(cls.stripe_product_id ? { product: cls.stripe_product_id } : { product_data: { name: `${cls.title} — cecespieces Academy` } }),
          },
        }],
        customer_email: student_email || undefined,
        success_url: `${SITE_URL}/?checkout=success&type=class`,
        cancel_url: `${SITE_URL}/?checkout=cancel&type=class`,
        metadata: { class_id: String(class_id), student_name: student_name || "", student_email: student_email || "" },
      }, `${cls.title} — cecespieces Academy`);

      // Pending enrollment (so the hub roster + student classroom see it) …
      if (!isTest) db(`class_enrollments`, {
        method: "POST", headers: { Prefer: "return=minimal" },
        body: JSON.stringify({
          class_id, class_title: cls.title, class_type: cls.type, price: cls.price,
          student_name: student_name || null, student_email: student_email || null,
          status: "pending", source: "stripe checkout", notes: `Stripe session ${session.id}`,
        }),
      }).catch(() => {});
      // … and a pending order for the CRM / Sales agent.
      if (!isTest) db(`orders`, {
        method: "POST", headers: { Prefer: "return=minimal" },
        body: JSON.stringify({
          piece_title: `${cls.title} (Class Enrollment)`, price: cls.price,
          type: "class-enrollment", status: "pending", source: "stripe checkout",
          customer_name: student_name || null, customer_email: student_email || null,
          notes: `Stripe session ${session.id}`,
        }),
      }).catch(() => {});

      return json({ url: session.url });
    }

    // ─────────────────────────── ARTWORK PURCHASE ─────────────────────────
    // A piece with a `deposit` set is a CUSTOM / commission piece: Buy Now
    // charges the deposit (down payment) and the balance is invoiced later,
    // once Cece confirms the final price. Otherwise the full price is charged.
    if (!piece_id) return json({ error: "Missing piece_id or class_id" }, 400);

    // select=* so this keeps working whether or not the Stripe-id columns exist yet.
    const r = await db(`pieces?id=eq.${encodeURIComponent(piece_id)}&select=*`);
    const rows = await r.json();
    const piece = Array.isArray(rows) ? rows[0] : null;
    if (!piece) return json({ error: "Piece not found" }, 404);
    if (piece.status === "sold") return json({ error: "This piece has already sold." }, 409);

    const priceC   = Math.round((parseFloat(piece.price) || 0) * 100);
    const depositC = Math.round((parseFloat(piece.deposit) || 0) * 100);
    const isDeposit = depositC > 0 && (priceC === 0 || depositC < priceC);
    const amount = isDeposit ? depositC : priceC;
    if (!amount || amount < 50) return json({ error: "This piece has no price set — please inquire." }, 400);

    const session = await createSession({
      mode: "payment",
      line_items: [{
        quantity: 1,
        price_data: {
          currency: "usd",
          unit_amount: amount,
          // Full purchases are booked against the piece's synced catalog product
          // (sync-stripe-catalog); the AMOUNT still comes from the database.
          ...(!isDeposit && piece.stripe_product_id
            ? { product: piece.stripe_product_id }
            : { product_data: { name: isDeposit ? `Deposit — ${piece.title} (custom)` : (piece.title || "cecespieces original") } }),
        },
      }],
      // Full purchases collect shipping now; deposits collect it with the balance.
      ...(isDeposit ? {} : { shipping_address_collection: { allowed_countries: ["US", "CA"] } }),
      success_url: `${SITE_URL}/?checkout=success${isDeposit ? "&kind=deposit" : ""}`,
      cancel_url: `${SITE_URL}/?checkout=cancel`,
      metadata: { piece_id: String(piece_id), kind: isDeposit ? "deposit" : "full" },
    }, piece.title || "cecespieces original");

    // Log a pending order so it shows in the hub. For a deposit, record the
    // deposit paid and the balance still due so Cece can confirm & invoice it.
    const balanceStr = isDeposit ? ((priceC - depositC) / 100).toFixed(2) : null;
    if (!isTest) db(`orders`, {
      method: "POST", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        piece_id, piece_title: piece.title,
        price: isDeposit ? piece.deposit : piece.price,
        type: isDeposit ? "deposit" : "purchase",
        status: isDeposit ? "deposit-paid-pending" : "pending",
        source: "stripe checkout",
        notes: isDeposit
          ? `Deposit $${piece.deposit} paid · balance $${balanceStr} due on confirmation · Stripe session ${session.id}`
          : `Stripe session ${session.id}`,
      }),
    }).catch(() => {});

    return json({ url: session.url });
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500);
  }
});
