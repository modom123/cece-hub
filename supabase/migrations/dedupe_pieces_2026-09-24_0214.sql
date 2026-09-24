-- ============================================================================
-- FILE: dedupe_pieces_2026-09-24_0214.sql
-- GENERATED: 2026-09-24_0214 UTC
-- PURPOSE: Remove duplicate products from the `pieces` table (the same piece
--          published more than once from publish-artworks.html). For each
--          title (case/space-insensitive) the NEWEST row is kept; older copies
--          are deleted. The website already hides duplicates on its own; this
--          cleans the database so the Hub's Collection matches.
-- USAGE:   Supabase -> SQL Editor. Run the PREVIEW first, then the rest.
-- SAFETY:  Wrapped in a transaction. Safe to re-run (no-op when clean).
-- ============================================================================

-- PREVIEW (optional) — rows that WILL BE DELETED:
--   select id, title, price, created_at from (
--     select *, row_number() over (
--       partition by lower(regexp_replace(trim(title), '\s+', ' ', 'g'))
--       order by created_at desc, id desc) as rn
--     from pieces where coalesce(trim(title), '') <> ''
--   ) d where rn > 1 order by title, created_at;

begin;

delete from pieces
where id in (
  select id from (
    select id, row_number() over (
      partition by lower(regexp_replace(trim(title), '\s+', ' ', 'g'))
      order by created_at desc, id desc) as rn
    from pieces
    where coalesce(trim(title), '') <> ''
  ) d
  where rn > 1
);

commit;

-- Verify afterwards (should return no rows):
--   select lower(trim(title)) t, count(*) from pieces group by 1 having count(*) > 1;
