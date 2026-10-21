// _shared/config.ts                                        (added 2026-10-21_2255 UTC)
// ---------------------------------------------------------------------------
// Reads app settings (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, SITE_URL) for
// the payment functions. Primary source: the locked private.app_secrets table
// (written by the go-live workflow over SQL; readable only through the
// app_secret() function, which only the service role may execute). Falls back
// to Edge Function secrets (Deno.env) so either setup method works.
// Values are cached for 60 s per warm instance, so a rotated key applies fast.
// ---------------------------------------------------------------------------
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const cache: Record<string, { v: string; t: number }> = {};

export async function appConfig(name: string): Promise<string> {
  const hit = cache[name];
  if (hit && Date.now() - hit.t < 60_000) return hit.v;
  let v = "";
  try {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/app_secret`, {
      method: "POST",
      headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ n: name }),
    });
    if (r.ok) v = String((await r.json()) ?? "");
  } catch (_) { /* table not set up yet — use env */ }
  if (!v) v = Deno.env.get(name) ?? "";
  v = v.trim();
  cache[name] = { v, t: Date.now() };
  return v;
}
