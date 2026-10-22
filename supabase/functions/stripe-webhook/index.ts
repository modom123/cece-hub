// stripe-webhook — Supabase Edge Function
// ---------------------------------------------------------------------------
// Stripe calls this after a successful payment.
//  • ARTWORK (piece_id): marks the piece SOLD and flips its pending order to
//    "confirmed" with the buyer's name/email.
//  • CLASS (class_id): flips the pending enrollment + order to "confirmed" with
//    the student's name/email and decrements the live class's remaining seats.
// So the hub reflects every sale automatically.
//  • DONATION / SPONSORSHIP: flips its pending order to "confirmed".
//  • Every paid checkout: emails the buyer Stripe's receipt (see sendReceipt).
//    Added 2026-10-22_2149 UTC.
//
// Deploy (JWT check OFF — Stripe can't send a Supabase token):
//   supabase functions deploy stripe-webhook --no-verify-jwt
// Secrets:
//   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
//   (STRIPE_SECRET_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY already set)
// Then in the Stripe dashboard → Developers → Webhooks, add an endpoint:
//   https://tssicoxzxcfijdlvtpqm.supabase.co/functions/v1/stripe-webhook
//   event: checkout.session.completed   → copy its signing secret (whsec_...)
// ---------------------------------------------------------------------------
import Stripe from "npm:stripe@17";

// Deno's runtime needs Stripe's fetch-based HTTP client; the default Node
// client fails with "An error occurred with our connection to Stripe".
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

const hdr = { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json" };
const patch = (path: string, body: unknown) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, { method: "PATCH", headers: { ...hdr, Prefer: "return=minimal" }, body: JSON.stringify(body) });
const get = (path: string) => fetch(`${SUPABASE_URL}/rest/v1/${path}`, { headers: hdr }).then((r) => r.json());

// Email the buyer Stripe's receipt (amount, item, card, receipt number). In
// live mode Stripe sends a receipt whenever a payment's receipt_email is set,
// whatever the Dashboard's "Customer emails" setting is. Skipped if the
// payment already has that receipt email, so nobody gets two. Best-effort:
// a failure here never blocks marking the order paid.
async function sendReceipt(s: Stripe.Checkout.Session, email: string | null) {
  const pi = typeof s.payment_intent === "string" ? s.payment_intent : s.payment_intent?.id;
  if (!pi || !email || s.payment_status !== "paid") return;
  try {
    const intent = await stripe.paymentIntents.retrieve(pi, { expand: ["latest_charge"] });
    const charge = intent.latest_charge as Stripe.Charge | null;
    if (intent.receipt_email === email || charge?.receipt_email === email) return;
    await stripe.paymentIntents.update(pi, { receipt_email: email });
  } catch (e) { console.warn("receipt email failed", (e as Error)?.message); }
}

Deno.serve(async (req) => {
  const sig = req.headers.get("stripe-signature");
  const raw = await req.text();
  let event: Stripe.Event;
  try {
    await initStripe();
    event = await stripe.webhooks.constructEventAsync(raw, sig!, await appConfig("STRIPE_WEBHOOK_SECRET"));
  } catch (e) {
    return new Response(`Bad signature: ${(e as Error).message}`, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const s = event.data.object as Stripe.Checkout.Session;
    const name  = s.customer_details?.name ?? s.metadata?.student_name ?? null;
    const email = s.customer_details?.email ?? s.metadata?.student_email ?? null;
    await sendReceipt(s, email);

    // ─── Donation / sponsorship paid (added 2026-10-22_2245) ───
    const kind = s.metadata?.kind;
    if (kind === "donation" || kind === "sponsorship") {
      await patch(`orders?notes=like.*${s.id}*`, { status: "confirmed", customer_name: name, customer_email: email });
      return new Response("ok", { status: 200 });
    }

    // ─── Class enrollment paid ───
    const classId = s.metadata?.class_id;
    if (classId) {
      // Confirm the enrollment we recorded when checkout started (matched by session id).
      await patch(`class_enrollments?notes=like.*${s.id}*`, { status: "confirmed", student_name: name, student_email: email });
      await patch(`orders?notes=like.*${s.id}*`, { status: "confirmed", customer_name: name, customer_email: email });
      // Decrement remaining seats for a live class (best-effort, non-atomic).
      try {
        const rows = await get(`classes?id=eq.${encodeURIComponent(classId)}&select=type,seats_left`);
        const c = Array.isArray(rows) ? rows[0] : null;
        if (c && c.type === "live" && c.seats_left != null && Number(c.seats_left) > 0) {
          await patch(`classes?id=eq.${encodeURIComponent(classId)}`, { seats_left: Number(c.seats_left) - 1 });
        }
      } catch (_) { /* ignore */ }
      return new Response("ok", { status: 200 });
    }

    // ─── Artwork purchased ───
    const pieceId = s.metadata?.piece_id;
    if (pieceId) {
      if (s.metadata?.kind === "deposit") {
        // Custom piece: deposit paid. Reserve the piece (not sold yet) and flip
        // its order to deposit-paid so Cece can confirm the final price & invoice
        // the balance. Store the customer so we can email/invoice them.
        await patch(`pieces?id=eq.${encodeURIComponent(pieceId)}`, { status: "reserved" });
        await patch(`orders?notes=like.*${s.id}*`, { status: "deposit-paid", customer_name: name, customer_email: email });
      } else {
        await patch(`pieces?id=eq.${encodeURIComponent(pieceId)}`, { status: "sold" });
        await patch(`orders?notes=like.*${s.id}*`, { status: "confirmed", customer_name: name, customer_email: email });
      }
    }
  }

  // ─── Balance invoice paid (custom piece) ───
  // The hub sends a Stripe invoice for the remaining balance; when the customer
  // pays it, mark the piece sold and confirm its deposit order.
  if (event.type === "invoice.paid" || event.type === "invoice.payment_succeeded") {
    const inv = event.data.object as Stripe.Invoice;
    const pieceId = (inv.metadata as Record<string, string> | null)?.piece_id;
    const email = inv.customer_email ?? null;
    if (pieceId) {
      await patch(`pieces?id=eq.${encodeURIComponent(pieceId)}`, { status: "sold" });
      await patch(`orders?piece_id=eq.${encodeURIComponent(pieceId)}&type=eq.deposit`, {
        status: "confirmed",
        notes: `Balance invoice ${inv.id} paid in full`,
        ...(email ? { customer_email: email } : {}),
      });
    }
  }

  return new Response("ok", { status: 200 });
});
