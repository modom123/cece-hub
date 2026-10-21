-- ============================================================================
-- FILE: gallery_walk_2026-10-21_2045.sql
-- GENERATED: 2026-10-21_2045 UTC
-- PURPOSE: Storage for the website's Gallery Walk front page. The hub's
--          "Gallery Walk" page saves which 10 pictures hang in the gallery
--          (row id 'walk'); the public website reads it on every visit.
-- ACCESS:  Anyone can READ (the website uses the anon key); only logged-in
--          team members can change it.
-- USAGE:   Supabase -> SQL Editor -> paste -> Run (safe to re-run), or run the
--          "Database — apply migration" GitHub workflow.
-- ============================================================================

create table if not exists gallery (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table gallery enable row level security;

drop policy if exists "Public read gallery" on gallery;
create policy "Public read gallery" on gallery for select using (true);

drop policy if exists "Team write gallery" on gallery;
create policy "Team write gallery" on gallery for all
  to authenticated using (true) with check (true);
