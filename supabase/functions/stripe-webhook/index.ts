// stripe-webhook — Supabase Edge Function
// ---------------------------------------------------------------------------
// Stripe calls this after a successful payment.
//  • ARTWORK (piece_id): marks the piece SOLD and flips its pending order to
//    "confirmed" with the buyer's name/email.
//  • CLASS (class_id): flips the pending enrollment + order to "confirmed" with
//    the student's name/email and decrements the live class's remaining seats.
// So the hub reflects every sale automatically.
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
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});
const WHSEC        = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const hdr = { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json" };
const patch = (path: string, body: unknown) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, { method: "PATCH", headers: { ...hdr, Prefer: "return=minimal" }, body: JSON.stringify(body) });
const get = (path: string) => fetch(`${SUPABASE_URL}/rest/v1/${path}`, { headers: hdr }).then((r) => r.json());

Deno.serve(async (req) => {
  const sig = req.headers.get("stripe-signature");
  const raw = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(raw, sig!, WHSEC);
  } catch (e) {
    return new Response(`Bad signature: ${(e as Error).message}`, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const s = event.data.object as Stripe.Checkout.Session;
    const name  = s.customer_details?.name ?? s.metadata?.student_name ?? null;
    const email = s.customer_details?.email ?? s.metadata?.student_email ?? null;

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
