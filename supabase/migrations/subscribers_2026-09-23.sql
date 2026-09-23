-- ============================================================================
-- FILE: subscribers_2026-09-23.sql
-- GENERATED: 2026-09-23 UTC
-- PURPOSE: Newsletter list for the "Studio Drop". The website footer sign-up
--          writes here; the Business Hub -> Studio Drop page reads it.
-- USAGE:   Paste into Supabase -> SQL Editor -> Run. Safe to re-run.
-- ============================================================================

create table if not exists subscribers (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  email      text not null,
  name       text,
  source     text default 'website'
);

-- One row per email (case-insensitive) so repeat sign-ups don't duplicate.
create unique index if not exists subscribers_email_uq on subscribers (lower(email));

-- Public can subscribe (insert) and the Hub can read the list.
alter table subscribers enable row level security;
drop policy if exists "Public subscribe" on subscribers;
create policy "Public subscribe" on subscribers for insert with check (true);
drop policy if exists "Public read subscribers" on subscribers;
create policy "Public read subscribers" on subscribers for select using (true);
