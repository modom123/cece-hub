// sync-stripe-catalog — Supabase Edge Function            (added 2026-10-21_2120 UTC)
// ---------------------------------------------------------------------------
// Keeps the Stripe product catalog in step with the hub, automatically.
//  • Every artwork (pieces) and Academy class (classes) is a Stripe Product
//    (metadata piece_id / class_id) with its current Price as default_price.
//  • A price change creates a new Stripe Price and archives the old one
//    (Stripe prices can't be edited). Sold pieces / inactive classes are
//    archived; deleted rows archive their product.
//  • Product + price ids are written back to the row (stripe_product_id,
//    stripe_price_id) so checkout sales land on the right catalog product.
//
// Called by:
//  • the database triggers in migrations/stripe_catalog_sync_*.sql on every
//    insert / update / delete  → {op, table, id, stripe_product_id?}
//  • the hub's "Sync to Stripe" button and the go-live workflow → {full:true}
// Auth: header x-sync-secret == the secret in the stripe_sync_config table
//       (created by the migration; the triggers send it), or a logged-in
//       hub user's token (the "Sync to Stripe" button).
//
// Deploy:  supabase functions deploy sync-stripe-catalog --no-verify-jwt
// Secrets: STRIPE_SECRET_KEY (set by the go-live workflow)
// ---------------------------------------------------------------------------
import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";

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
const ANON_KEY     = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-sync-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
const db = (path: string, init?: RequestInit) =>
  fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", ...(init?.headers || {}) },
  });

type Kind = "piece" | "class";
const TABLE: Record<Kind, string> = { piece: "pieces", class: "classes" };

async function authorized(req: Request): Promise<boolean> {
  const sent = req.headers.get("x-sync-secret");
  if (sent) {
    const r = await db(`stripe_sync_config?id=eq.1&select=secret`);
    const rows = r.ok ? await r.json() : [];
    return !!(Array.isArray(rows) && rows[0]?.secret && rows[0].secret === sent);
  }
  const tok = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!tok || tok === ANON_KEY) return false;
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, { headers: { apikey: ANON_KEY || SERVICE_KEY, Authorization: `Bearer ${tok}` } });
  return r.ok;   // a signed-in hub team member
}

const cents = (v: unknown) => Math.round((parseFloat(String(v ?? "").replace(/[^0-9.]/g, "")) || 0) * 100);
const httpImage = (u: unknown) => (typeof u === "string" && /^https:\/\//.test(u) && u.length < 2000 ? [u] : []);

async function findProduct(kind: Kind, id: string, storedId?: string | null): Promise<Stripe.Product | null> {
  if (storedId) {
    try { const p = await stripe.products.retrieve(storedId); if (!(p as any).deleted) return p; } catch (_) { /* other mode / removed */ }
  }
  const key = kind === "piece" ? "piece_id" : "class_id";
  try {
    const res = await stripe.products.search({ query: `metadata['${key}']:'${String(id).replace(/'/g, "")}'`, limit: 1 });
    return res.data[0] ?? null;
  } catch (_) { return null; }
}

// Sync one row. Returns a short status line for the summary.
async function syncRow(kind: Kind, row: Record<string, any>): Promise<string> {
  const id = String(row.id);
  const isPiece = kind === "piece";
  const name = isPiece ? (row.title || "cecespieces original") : `${row.title || "Class"} — cecespieces Academy`;
  const active = isPiece ? (row.status || "available") !== "sold" : row.active !== false;
  const amount = cents(row.price);
  const meta: Record<string, string> = isPiece
    ? { piece_id: id, type: String(row.type || ""), status: String(row.status || "available"), deposit: String(row.deposit || "") }
    : { class_id: id, type: String(row.type || ""), level: String(row.level || "") };
  const description = String((isPiece ? row.description : (row.blurb || row.description)) || "").slice(0, 1000) || undefined;

  let product = await findProduct(kind, id, row.stripe_product_id);
  const fields = { name: String(name).slice(0, 250), active, metadata: meta, images: httpImage(row.image), ...(description ? { description } : {}) };
  product = product
    ? await stripe.products.update(product.id, fields)
    : await stripe.products.create(fields);

  // Price: reuse the default price if the amount matches, else create a new one.
  let priceId: string | null = null;
  if (amount >= 50) {
    const curId = typeof product.default_price === "string" ? product.default_price : product.default_price?.id;
    let cur: Stripe.Price | null = null;
    if (curId) { try { cur = await stripe.prices.retrieve(curId); } catch (_) { cur = null; } }
    if (cur && cur.unit_amount === amount && cur.currency === "usd" && cur.active) {
      priceId = cur.id;
    } else {
      const np = await stripe.prices.create({ product: product.id, unit_amount: amount, currency: "usd", metadata: meta });
      await stripe.products.update(product.id, { default_price: np.id });
      if (cur && cur.active) { try { await stripe.prices.update(cur.id, { active: false }); } catch (_) { /* ignore */ } }
      priceId = np.id;
    }
  }

  if (row.stripe_product_id !== product.id || (row.stripe_price_id || null) !== priceId) {
    await db(`${TABLE[kind]}?id=eq.${encodeURIComponent(id)}`, {
      method: "PATCH", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ stripe_product_id: product.id, stripe_price_id: priceId }),
    });
  }
  return `${isPiece ? "piece" : "class"} "${row.title}" → ${product.id}${priceId ? ` @ $${(amount / 100).toFixed(2)}` : " (no price)"}${active ? "" : " [archived]"}`;
}

async function archive(kind: Kind, id: string, storedId?: string | null): Promise<string> {
  const p = await findProduct(kind, id, storedId);
  if (!p) return `${kind} ${id} removed (no Stripe product)`;
  await stripe.products.update(p.id, { active: false });
  return `${kind} ${id} removed → archived ${p.id}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!(await authorized(req))) return json({ error: "Not authorized" }, 401);
  if (!(await initStripe())) return json({ error: "STRIPE_SECRET_KEY is not set" }, 500);

  const body = await req.json().catch(() => ({}));
  const log: string[] = [];
  try {
    if (body.full) {
      for (const kind of ["piece", "class"] as Kind[]) {
        const r = await db(`${TABLE[kind]}?select=*`);
        const rows = r.ok ? await r.json() : [];
        for (const row of Array.isArray(rows) ? rows : []) {
          try { log.push(await syncRow(kind, row)); }
          catch (e) { log.push(`⚠️ ${kind} "${row.title}": ${(e as Error).message}`); }
        }
      }
      return json({ ok: true, synced: log.length, log });
    }

    const kind: Kind | null = body.table === "pieces" ? "piece" : body.table === "classes" ? "class" : null;
    if (!kind || body.id == null) return json({ error: "Expected {full:true} or {table, id, op}" }, 400);
    if (body.op === "DELETE") return json({ ok: true, log: [await archive(kind, String(body.id), body.stripe_product_id)] });

    const r = await db(`${TABLE[kind]}?id=eq.${encodeURIComponent(String(body.id))}&select=*`);
    const rows = r.ok ? await r.json() : [];
    const row = Array.isArray(rows) ? rows[0] : null;
    if (!row) return json({ ok: true, log: [`${kind} ${body.id} not found — skipped`] });
    return json({ ok: true, log: [await syncRow(kind, row)] });
  } catch (e) {
    return json({ error: String((e as Error)?.message || e), log }, 500);
  }
});
