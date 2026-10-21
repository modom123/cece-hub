-- ============================================================================
-- FILE: security_lockdown_2026-10-21_2345.sql
-- GENERATED: 2026-10-21_2345 UTC
-- PURPOSE: Close the public-key holes found by the go-live audit. Before this,
--          anyone with the website's public (anon) key could READ customer
--          contacts, orders and the hub's API-key settings, and could EDIT or
--          DELETE pieces (incl. prices). After this:
--            • the public website can only: read pieces, classes and the
--              gallery; submit orders, rental requests, class enrollments and
--              newsletter sign-ups; and look up its own classes by email
--              through my_enrollments().
--            • everything else needs a signed-in hub user (Supabase Auth).
--          The Edge Functions use the service role and are unaffected.
-- USAGE:   Supabase -> SQL Editor -> Run, or the "Database — apply migration"
--          workflow. Safe to re-run.
-- ============================================================================

-- Drop every existing policy on these tables, then add the intended ones.
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies
           where schemaname = 'public'
             and tablename in ('pieces','orders','rental_bookings','contacts','settings','post_queue',
                               'hub_activity','classes','class_enrollments','subscribers',
                               'team_members','user_social_keys','user_social_settings')
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- RLS on for all of them (tables that don't exist are skipped).
do $$
declare t text;
begin
  foreach t in array array['pieces','orders','rental_bookings','contacts','settings','post_queue',
                           'hub_activity','classes','class_enrollments','subscribers',
                           'team_members','user_social_keys','user_social_settings']
  loop
    if to_regclass('public.'||t) is not null then
      execute format('alter table public.%I enable row level security', t);
      -- signed-in hub team: full access
      execute format('create policy "Team full access" on public.%I for all to authenticated using (true) with check (true)', t);
    end if;
  end loop;
end $$;

-- Public website: read the catalog
create policy "Public read pieces"   on public.pieces  for select to anon using (true);
create policy "Public read classes"  on public.classes for select to anon using (true);

-- Public website: submit forms (insert only — cannot read them back)
create policy "Public submit orders"      on public.orders            for insert to anon with check (true);
create policy "Public submit rentals"     on public.rental_bookings   for insert to anon with check (true);
create policy "Public submit enrollments" on public.class_enrollments for insert to anon with check (true);
create policy "Public subscribe"          on public.subscribers       for insert to anon with check (true);

-- "My Classroom": a student sees only the classes for the email they type.
create or replace function public.my_enrollments(p_email text)
returns table (class_id text, student_name text)
language sql
stable
security definer
set search_path = public
as $$
  select e.class_id::text, e.student_name
  from class_enrollments e
  where lower(e.student_email) = lower(trim(p_email))
    and coalesce(e.status, 'pending') <> 'cancelled'
$$;
revoke all on function public.my_enrollments(text) from public;
grant execute on function public.my_enrollments(text) to anon, authenticated;
