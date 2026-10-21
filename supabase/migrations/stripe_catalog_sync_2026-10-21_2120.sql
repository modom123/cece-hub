-- ============================================================================
-- FILE: stripe_catalog_sync_2026-10-21_2120.sql
-- GENERATED: 2026-10-21_2120 UTC
-- PURPOSE: (1) Gallery Walk storage for the website front page, and
--          (2) automatic Stripe catalog sync: whenever a piece or class is
--          added, edited (title/price/status/photo/…), or deleted, the
--          database calls the sync-stripe-catalog Edge Function, which
--          updates the matching Stripe Product + Price.
-- USAGE:   Supabase -> SQL Editor -> paste all -> Run. Safe to re-run.
--          Then run GitHub Actions -> "Stripe — go live" (deploys the
--          function and syncs everything once).
-- ============================================================================

-- ── 1. GALLERY WALK (front-page gallery picks; public read, team write) ─────
create table if not exists gallery (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
alter table gallery enable row level security;
drop policy if exists "Public read gallery" on gallery;
create policy "Public read gallery" on gallery for select using (true);
drop policy if exists "Team write gallery" on gallery;
create policy "Team write gallery" on gallery for all to authenticated using (true) with check (true);

-- ── 2. STRIPE IDS on pieces + classes ───────────────────────────────────────
alter table pieces  add column if not exists deposit           text;
alter table pieces  add column if not exists stripe_product_id text;
alter table pieces  add column if not exists stripe_price_id   text;
alter table classes add column if not exists stripe_product_id text;
alter table classes add column if not exists stripe_price_id   text;

-- ── 3. Private secret the triggers send to the sync function ────────────────
-- RLS on with no policies = invisible to the website/anon key; only the
-- database and the Edge Function (service role) can read it.
create table if not exists stripe_sync_config (
  id      int primary key default 1,
  secret  text not null default replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','')
);
alter table stripe_sync_config enable row level security;
insert into stripe_sync_config (id) values (1) on conflict (id) do nothing;

-- ── 4. Trigger: tell the sync function about every change ───────────────────
create extension if not exists pg_net;

create or replace function public.stripe_catalog_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  s    text;
  rid  text;
  spid text;
begin
  select secret into s from stripe_sync_config where id = 1;
  if tg_op = 'DELETE' then
    rid := old.id::text; spid := old.stripe_product_id;
  else
    rid := new.id::text;
  end if;
  perform net.http_post(
    url     := 'https://tssicoxzxcfijdlvtpqm.supabase.co/functions/v1/sync-stripe-catalog',
    headers := jsonb_build_object('Content-Type','application/json','x-sync-secret', s),
    body    := jsonb_build_object('op', tg_op, 'table', tg_table_name, 'id', rid, 'stripe_product_id', spid)
  );
  return coalesce(new, old);
end;
$$;

-- Pieces: new / deleted, or a change customers would see. (The sync writing
-- back stripe ids doesn't match the WHEN clause, so there's no loop.)
drop trigger if exists pieces_stripe_sync     on pieces;
drop trigger if exists pieces_stripe_sync_upd on pieces;
create trigger pieces_stripe_sync after insert or delete on pieces
  for each row execute function public.stripe_catalog_notify();
create trigger pieces_stripe_sync_upd after update on pieces
  for each row when (
    (old.title, old.price, old.status, old.description, old.image, old.type, old.deposit)
    is distinct from
    (new.title, new.price, new.status, new.description, new.image, new.type, new.deposit)
  ) execute function public.stripe_catalog_notify();

-- Classes: same idea.
drop trigger if exists classes_stripe_sync     on classes;
drop trigger if exists classes_stripe_sync_upd on classes;
create trigger classes_stripe_sync after insert or delete on classes
  for each row execute function public.stripe_catalog_notify();
create trigger classes_stripe_sync_upd after update on classes
  for each row when (
    (old.title, old.price, old.active, old.blurb, old.description, old.image, old.type, old.level)
    is distinct from
    (new.title, new.price, new.active, new.blurb, new.description, new.image, new.type, new.level)
  ) execute function public.stripe_catalog_notify();

-- Check: select count(*) from stripe_sync_config;   -- 1
