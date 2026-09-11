// create-checkout — Supabase Edge Function
// ---------------------------------------------------------------------------
// Creates a Stripe Checkout Session for one cecepieces artwork and returns its
// URL. The PRICE IS READ FROM THE DATABASE (service role), never trusted from
// the browser, so a visitor can't tamper with the amount. Records a pending
// "purchase" order for the hub; the stripe-webhook function confirms it on pay.
//
// Deploy:  supabase functions deploy create-checkout
// Secrets: supabase secrets set STRIPE_SECRET_KEY=sk_live_...  SITE_URL=https://cecepieces.com
//          (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically)
// ---------------------------------------------------------------------------
import Stripe from "npm:stripe@17";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, { apiVersion: "2024-06-20" });
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SITE_URL     = (Deno.env.get("SITE_URL") || "https://cecepieces.com").replace(/\/$/, "");

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { piece_id } = await req.json();
    if (!piece_id) return json({ error: "Missing piece_id" }, 400);

    // Authoritative piece data from the DB (service role bypasses RLS).
    const r = await fetch(
      `${SUPABASE_URL}/rest/v1/pieces?id=eq.${encodeURIComponent(piece_id)}&select=id,title,price,status`,
      { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` } },
    );
    const rows = await r.json();
    const piece = Array.isArray(rows) ? rows[0] : null;
    if (!piece) return json({ error: "Piece not found" }, 404);
    if (piece.status === "sold") return json({ error: "This piece has already sold." }, 409);

    const amount = Math.round(parseFloat(piece.price) * 100);
    if (!amount || amount < 50) return json({ error: "This piece has no price set — please inquire." }, 400);

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{
        quantity: 1,
        price_data: {
          currency: "usd",
          unit_amount: amount,
          product_data: { name: piece.title || "cecepieces original" },
        },
      }],
      // Collect the buyer's shipping address for the physical artwork.
      shipping_address_collection: { allowed_countries: ["US", "CA"] },
      success_url: `${SITE_URL}/?checkout=success`,
      cancel_url: `${SITE_URL}/?checkout=cancel`,
      metadata: { piece_id: String(piece_id) },
    });

    // Best-effort: log a pending purchase so it shows in the hub's Orders.
    fetch(`${SUPABASE_URL}/rest/v1/orders`, {
      method: "POST",
      headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", Prefer: "return=minimal" },
      body: JSON.stringify({
        piece_id, piece_title: piece.title, price: piece.price,
        type: "purchase", status: "pending", source: "stripe checkout",
        notes: `Stripe session ${session.id}`,
      }),
    }).catch(() => {});

    return json({ url: session.url });
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500);
  }
});
