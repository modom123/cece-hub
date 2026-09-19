-- ============================================================================
-- FILE: fix_public_rls_2026-09-19_0052.sql
-- GENERATED: 2026-09-19_0052 UTC
-- PURPOSE: Let the PUBLIC website (Supabase anon key) READ the catalog and
--          WRITE leads. If Row-Level Security is on but has no policy, the
--          website reads nothing and silently shows the built-in demo catalog
--          (fake IDs) -> 'Buy Now' hits 'Piece not found' -> inquiry fallback.
--          This adds permissive public policies so real DB rows are served.
-- USAGE:   Paste into Supabase -> SQL Editor -> Run. Safe / idempotent.
-- NOTE:    Reads are public (anyone can browse the shop). Writes here are also
--          public because the website posts inquiries/rentals/enrollments with
--          the anon key. Prices for checkout are still validated server-side by
--          the create-checkout function (service role), so this does not let a
--          visitor tamper with amounts.
-- ============================================================================

-- ── PIECES: public can read the catalog ─────────────────────────────────────
alter table pieces enable row level security;
drop policy if exists "Public read pieces" on pieces;
create policy "Public read pieces" on pieces for select using (true);

-- ── ORDERS: public can create an inquiry/order lead ─────────────────────────
alter table orders enable row level security;
drop policy if exists "Public write orders" on orders;
create policy "Public write orders" on orders for insert with check (true);

-- ── RENTAL BOOKINGS: public can submit a rental request ─────────────────────
alter table rental_bookings enable row level security;
drop policy if exists "Public write rentals" on rental_bookings;
create policy "Public write rentals" on rental_bookings for insert with check (true);

-- ── CLASSES / ENROLLMENTS already get public policies from the classes
--    migration; re-assert here so this file is self-sufficient.
alter table classes enable row level security;
drop policy if exists "Public read classes" on classes;
create policy "Public read classes" on classes for select using (true);

alter table class_enrollments enable row level security;
drop policy if exists "Public write enrollments" on class_enrollments;
create policy "Public write enrollments" on class_enrollments for insert with check (true);

-- Verify what the public role can now read:
--   set role anon;
--   select count(*) from pieces;   -- should be > 0
--   reset role;
