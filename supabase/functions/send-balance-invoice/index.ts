// send-balance-invoice — Supabase Edge Function
// ---------------------------------------------------------------------------
// Called from the HUB when Cece confirms a custom piece. It:
//   1. (optionally) updates the piece's FINAL price,
//   2. emails the customer a Stripe INVOICE for the remaining balance
//      (final price − deposit already paid),
//   3. marks the deposit order "balance-invoiced".
// Stripe emails a hosted invoice with a Pay button; paying it fires
// invoice.paid → stripe-webhook marks the piece sold & the order confirmed.
//
// Deploy:  supabase functions deploy send-balance-invoice
// Secrets: STRIPE_SECRET_KEY (already set). Add the `invoice.paid` event to your
//          Stripe webhook endpoint so balance payments are recorded.
// ---------------------------------------------------------------------------
import Stripe from "npm:stripe@17";

// Deno's runtime needs Stripe's fetch-based HTTP client; the default Node
// client fails with "An error occurred with our connection to Stripe".
const stripe = new Stripe((Deno.env.get("STRIPE_SECRET_KEY") ?? "").trim(), {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
const db = (path: string, init?: RequestInit) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, { ...init, headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", ...(init?.headers || {}) } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { piece_id, final_price, customer_email, customer_name } = await req.json().catch(() => ({}));
    if (!piece_id) return json({ error: "Missing piece_id" }, 400);

    // Optionally set the confirmed final price first.
    if (final_price != null && final_price !== "") {
      await db(`pieces?id=eq.${encodeURIComponent(piece_id)}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ price: String(final_price) }) });
    }

    const pr = await db(`pieces?id=eq.${encodeURIComponent(piece_id)}&select=id,title,price,deposit`);
    const piece = (await pr.json())?.[0];
    if (!piece) return json({ error: "Piece not found" }, 404);

    const priceC   = Math.round((parseFloat(piece.price) || 0) * 100);
    const depositC = Math.round((parseFloat(piece.deposit) || 0) * 100);
    const balanceC = priceC - depositC;
    if (balanceC < 50) return json({ error: "Balance is zero or too small to invoice." }, 400);

    // Find the customer email from the deposit order if not supplied.
    let email = customer_email, name = customer_name;
    if (!email) {
      const or = await db(`orders?piece_id=eq.${encodeURIComponent(piece_id)}&type=eq.deposit&order=created_at.desc&select=customer_email,customer_name&limit=1`);
      const o = (await or.json())?.[0];
      email = o?.customer_email; name = name || o?.customer_name;
    }
    if (!email) return json({ error: "No customer email on file for this piece." }, 400);

    const customer = await stripe.customers.create({ email, name: name || undefined });
    await stripe.invoiceItems.create({
      customer: customer.id, amount: balanceC, currency: "usd",
      description: `Balance — ${piece.title} (final $${(priceC/100).toFixed(2)} − $${(depositC/100).toFixed(2)} deposit)`,
    });
    let invoice = await stripe.invoices.create({
      customer: customer.id, collection_method: "send_invoice", days_until_due: 7,
      auto_advance: true, metadata: { piece_id: String(piece_id) },
      description: `Your cecespieces custom piece "${piece.title}" is confirmed — remaining balance.`,
    });
    invoice = await stripe.invoices.finalizeInvoice(invoice.id);
    invoice = await stripe.invoices.sendInvoice(invoice.id);

    await db(`orders?piece_id=eq.${encodeURIComponent(piece_id)}&type=eq.deposit`, {
      method: "PATCH", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ status: "balance-invoiced", notes: `Balance invoice ${invoice.id} sent to ${email} · $${(balanceC/100).toFixed(2)}` }),
    });

    return json({ url: invoice.hosted_invoice_url, invoice_id: invoice.id, balance: (balanceC/100).toFixed(2), email });
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500);
  }
});
