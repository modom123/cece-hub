// stripe-webhook — Supabase Edge Function
// ---------------------------------------------------------------------------
// Stripe calls this after a successful payment. It marks the piece SOLD and
// flips the pending order to "confirmed" with the buyer's name/email, so the
// hub reflects the sale automatically.
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

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, { apiVersion: "2024-06-20" });
const WHSEC        = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const patch = (path: string, body: unknown) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: "PATCH",
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", Prefer: "return=minimal" },
    body: JSON.stringify(body),
  });

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
    const pieceId = s.metadata?.piece_id;
    if (pieceId) {
      await patch(`pieces?id=eq.${encodeURIComponent(pieceId)}`, { status: "sold" });
      await patch(`orders?notes=like.*${s.id}*`, {
        status: "confirmed",
        customer_name: s.customer_details?.name ?? null,
        customer_email: s.customer_details?.email ?? null,
      });
    }
  }
  return new Response("ok", { status: 200 });
});
