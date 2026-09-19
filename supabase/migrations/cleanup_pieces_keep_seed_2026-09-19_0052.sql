-- ============================================================================
-- FILE: cleanup_pieces_keep_seed_2026-09-19_0052.sql
-- GENERATED: 2026-09-19_0052 UTC
-- PURPOSE: De-duplicate the `pieces` table by keeping ONLY the Claude-seeded
--          catalog (rows whose image is a cecethepieces repo URL) and removing
--          the older Hub rows. Then re-insert the 3 seed pieces that were
--          skipped earlier because a same-titled Hub row already existed.
-- SAFETY:  Wrapped in a transaction. Run the SELECT preview first if you want
--          to see exactly which rows will be deleted before committing.
-- ============================================================================

-- PREVIEW (optional) — rows that WILL BE DELETED:
--   select title, price, image from pieces
--   where image is null
--      or image not like 'https://raw.githubusercontent.com/modom123/cecethepieces/main/%';

begin;

-- 1) Remove every row that did NOT come from the seed.
delete from pieces
where image is null
   or image not like 'https://raw.githubusercontent.com/modom123/cecethepieces/main/%';

-- 2) Re-insert the 3 seed pieces that were skipped during the initial seed.
insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Geode Statement Panel$cece$, $cece$Statement Panel$cece$, $cece$1145$cece$, NULL, $cece$Epoxy resin, mica pigments, crushed glass & crystal geodes on a large panel$cece$, $cece$A large-format geode pour — rivers of colour split open by silver-and-gold crystal caverns. A statement wall piece that also makes a showstopping wedding or event backdrop (available to rent).$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/81746D25-6F5A-426B-8BB6-6EC446155E6D.jpeg$cece$, $cece$available$cece$, true, true, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4085.jpeg", "label": "Blush & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4082.jpeg", "label": "Blue & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4081.jpeg", "label": "Coral & Gold"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4080.jpeg", "label": "Black & Silver"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Geode Statement Panel$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Floral Preservation Block$cece$, $cece$Preservation$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin preserving your real flowers, personalized lettering$cece$, $cece$Send me your wedding or anniversary bouquet and I'll preserve it forever inside a crystal-clear resin block, personalized with names and a date. Made to order.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4069.jpeg$cece$, $cece$available$cece$, true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Floral Preservation Block$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Personalized Ornament$cece$, $cece$Seasonal Gift$cece$, $cece$55$cece$, NULL, $cece$Resin ornament with personalized name & character, ribbon$cece$, $cece$Personalized keepsake ornaments — a name, a character, a little glitter. Perfect for stockings, gift tags and the tree.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4066.jpeg$cece$, $cece$available$cece$, true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Personalized Ornament$cece$);

commit;

-- Verify afterwards:
--   select title, price, deposit, status from pieces order by title;