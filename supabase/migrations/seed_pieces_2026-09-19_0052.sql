-- ============================================================================
-- FILE: seed_pieces_2026-09-19_0052.sql
-- GENERATED: 2026-09-19_0052 UTC
-- PURPOSE: Seed the cecespieces `pieces` table with the real catalog so the
--          website serves DB rows (with valid IDs) instead of the built-in
--          demo catalog. This is what makes 'Buy Now' reach Stripe checkout
--          instead of falling back to the inquiry form ('Piece not found').
-- USAGE:   Paste into Supabase -> SQL Editor -> Run. Safe to re-run
--          (idempotent: skips any piece whose title already exists).
-- NOTE:    Prices are the demo prices shown on the site today — edit them
--          here (or later in the Business Hub) to your real prices.
-- SCHEMA:  Columns match publish-artworks.html's insert. The ALTERs below
--          add any optional columns that may be missing; `id` and
--          `created_at` are left to their table defaults.
-- ============================================================================

alter table pieces add column if not exists deposit      numeric;
alter table pieces add column if not exists variations   jsonb;
alter table pieces add column if not exists for_sale     boolean default true;
alter table pieces add column if not exists for_rent     boolean default false;

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Resin River Wall Plaque$cece$, $cece$Resin Art$cece$, $cece$225$cece$, NULL, $cece$Walnut wood, epoxy resin, alcohol inks, gold leaf, druzy crystal$cece$, $cece$A live-edge walnut river runs through a pour of deep resin, opening into a heart of blue-and-silver druzy crystal like a geode split by hand. Gilded botanical leaves climb the border. Poured one at a time — no two are ever alike.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4026.jpeg$cece$, 'available', true, false, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4027.jpeg", "label": "Golden"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4028.jpeg", "label": "Ivory & Gold"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4029.jpeg", "label": "Blush"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4024.jpeg", "label": "Teal (Square)"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4030.jpeg", "label": "Teal & Gold"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Resin River Wall Plaque$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Resin River Wall Art — Framed$cece$, $cece$Resin Art$cece$, $cece$550$cece$, NULL, $cece$Walnut & epoxy resin on a framed panel, druzy crystal, metallic leaf$cece$, $cece$The Resin River composition on a larger framed panel — a live-edge walnut river and a druzy geode heart set behind a sleek metallic frame, ready to hang as a statement wall piece.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4034.jpeg$cece$, 'available', true, false, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4033.jpeg", "label": "Teal & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4035.jpeg", "label": "Ivory Float"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Resin River Wall Art — Framed$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Beach Shore Memorial Block$cece$, $cece$Memorial Piece$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin, real beach sand, seashells & sea glass$cece$, $cece$A single ocean wave caught mid-break above real beach sand, tiny shells and a piece of sea glass — a quiet keepsake. Can be personalized with a name and dates. Choose an Emerald, Amethyst, or Black tide.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4036.jpeg$cece$, 'available', true, false, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4037.jpeg", "label": "Amethyst"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4038.jpeg", "label": "Black"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4041.jpeg", "label": "Emerald — Personalized"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4039.jpeg", "label": "Black — With Name"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4040.jpeg", "label": "Black — Name & Dates"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Beach Shore Memorial Block$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Emerald Beach Memorial Coasters$cece$, $cece$Memorial Piece$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin, real beach sand & shells — set of coasters$cece$, $cece$A set of coasters carrying the same emerald shoreline as the memorial blocks — real sand, tiny shells, a curl of white surf, and an optional gold name.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4044.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Emerald Beach Memorial Coasters$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Geode Statement Panel$cece$, $cece$Statement Panel$cece$, $cece$1145$cece$, NULL, $cece$Epoxy resin, mica pigments, crushed glass & crystal geodes on a large panel$cece$, $cece$A large-format geode pour — rivers of colour split open by silver-and-gold crystal caverns. A statement wall piece that also makes a showstopping wedding or event backdrop (available to rent).$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/81746D25-6F5A-426B-8BB6-6EC446155E6D.jpeg$cece$, 'available', true, true, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4085.jpeg", "label": "Blush & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4082.jpeg", "label": "Blue & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4081.jpeg", "label": "Coral & Gold"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4080.jpeg", "label": "Black & Silver"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Geode Statement Panel$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Cremation Ash Keychain$cece$, $cece$Memorial Piece$cece$, $cece$45$cece$, NULL, $cece$Epoxy resin with cremation ash & crystal, metal keyring$cece$, $cece$A geode keepsake keychain holding a loved one's ashes with tiny crystals — carry them with you everywhere. Heart or round, in several colours.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4091.jpeg$cece$, 'available', true, false, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4095.jpeg", "label": "Rose Red"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4097.jpeg", "label": "Emerald"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4098.jpeg", "label": "Amethyst"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Cremation Ash Keychain$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$DAD Memorial Keepsake$cece$, $cece$Memorial Piece$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin with cremation ash, raised DAD lettering$cece$, $cece$A hexagon keepsake swirled with cremation ash and finished with a raised “DAD” in gold or silver — a quiet tribute for a shelf or desk.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4046.jpeg$cece$, 'available', true, false, $cece$[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4047.jpeg", "label": "Silver Lettering"}]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$DAD Memorial Keepsake$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Lavender Ash Ornament$cece$, $cece$Memorial Piece$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin, pressed lavender & cremation ash, hanging cord$cece$, $cece$A round hanging ornament with real pressed lavender and a whisper of ash suspended in clear resin — light-catching and gentle.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4063.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Lavender Ash Ornament$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Floral Preservation Block$cece$, $cece$Preservation$cece$, $cece$150$cece$, NULL, $cece$Epoxy resin preserving your real flowers, personalized lettering$cece$, $cece$Send me your wedding or anniversary bouquet and I'll preserve it forever inside a crystal-clear resin block, personalized with names and a date. Made to order.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4069.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Floral Preservation Block$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Personalized Ornament$cece$, $cece$Seasonal Gift$cece$, $cece$55$cece$, NULL, $cece$Resin ornament with personalized name & character, ribbon$cece$, $cece$Personalized keepsake ornaments — a name, a character, a little glitter. Perfect for stockings, gift tags and the tree.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4066.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Personalized Ornament$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Botanical Memory Frame$cece$, $cece$Preservation$cece$, $cece$150$cece$, NULL, $cece$Round wood frame, real pressed flowers & feathers, glass keepsake vial, resin$cece$, $cece$Real pressed flowers, delicate feathers and a tiny glass keepsake vial arranged inside a round wooden frame — a botanical memory kept under glass. Made to order from your own blooms and mementos.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/botanical-memory-frame_2026-09-11_1302.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Botanical Memory Frame$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Ocean Islands — Resin & Moss$cece$, $cece$Mixed Media$cece$, $cece$1450$cece$, $cece$400$cece$, $cece$Epoxy resin, preserved moss & lichen, gold leaf, crushed minerals on a large panel$cece$, $cece$An aerial view of an emerald archipelago — islands of preserved moss and gold rimmed by rivers of blue-green resin. A true mixed-media original, made to order in your size and palette (and available to rent as an event backdrop).$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/Gemini_Generated_Image_391xt6391xt6391x.jpg$cece$, 'available', true, true, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Ocean Islands — Resin & Moss$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Forest Landscape Block$cece$, $cece$Resin Art$cece$, $cece$145$cece$, NULL, $cece$Hand-painted forest landscape sealed in a clear epoxy resin block$cece$, $cece$A hand-painted evergreen forest at golden hour — pines mirrored in a still river under a blush sky — sealed inside a crystal-clear resin block that catches the light from every side.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/forest-landscape-block_2026-09-11_1302.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Forest Landscape Block$cece$);

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select $cece$Feather Heart Keychain$cece$, $cece$Memorial Piece$cece$, $cece$45$cece$, NULL, $cece$Epoxy resin with a real feather or pressed flower, metal keyring$cece$, $cece$A little resin keepsake keychain holding a real feather or a pressed flower — carried in a heart or a round charm. A quiet way to keep something meaningful close.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/feather-heart-keychain_2026-09-11_1302.jpeg$cece$, 'available', true, false, $cece$[]$cece$::jsonb
where not exists (select 1 from pieces where title = $cece$Feather Heart Keychain$cece$);
