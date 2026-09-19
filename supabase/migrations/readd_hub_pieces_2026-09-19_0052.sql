-- ============================================================================
-- FILE: readd_hub_pieces_2026-09-19_0052.sql
-- GENERATED: 2026-09-19_0052 UTC
-- PURPOSE: Re-add the Hub products that the de-dup cleanup removed. Only their
--          TITLE and PRICE were recoverable (from the table dump), so these
--          rows have NO image/description/variations yet — open each in the
--          Business Hub afterward to add its photo and details.
-- NOTE:    If a Supabase backup / PITR from before the cleanup exists, RESTORE
--          THAT INSTEAD — it brings these rows back with their photos intact.
-- SAFETY:  Idempotent (skips a title that already exists). Wrapped in a txn.
-- ============================================================================

begin;

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Beach Memorial Block$cece$, $cece$225$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Beach Memorial Block$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Beach Memorial Coasters$cece$, $cece$245$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Beach Memorial Coasters$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Botanical Frame$cece$, $cece$150$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Botanical Frame$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$CECE 1$cece$, $cece$2379$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$CECE 1$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$DAD Keepsake$cece$, $cece$195$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$DAD Keepsake$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Feather Keychain$cece$, $cece$75$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Feather Keychain$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Geode Ash Keychain$cece$, $cece$145$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Geode Ash Keychain$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$Lavender Ornament$cece$, $cece$150$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$Lavender Ornament$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$River Wall Art — Framed$cece$, $cece$550$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$River Wall Art — Framed$cece$);

insert into pieces (title, price, status, for_sale, for_rent)
select $cece$River Wall Plaque$cece$, $cece$325$cece$, $cece$available$cece$, true, false
where not exists (select 1 from pieces where title = $cece$River Wall Plaque$cece$);

commit;

-- ── OPTIONAL: your original Hub prices for the 3 shared-title pieces ──────────
-- The seed set these to demo prices. Uncomment to restore YOUR prices:
--   update pieces set price = $cece$1645$cece$ where title = $cece$Geode Statement Panel$cece$;
--   update pieces set price = $cece$275$cece$  where title = $cece$Floral Preservation Block$cece$;
--   update pieces set price = $cece$95$cece$   where title = $cece$Personalized Ornament$cece$;

-- Verify:
--   select title, price, image from pieces order by title;
