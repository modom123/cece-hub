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
select 'Resin River Wall Plaque', 'Resin Art', '225', NULL, 'Walnut wood, epoxy resin, alcohol inks, gold leaf, druzy crystal', 'A live-edge walnut river runs through a pour of deep resin, opening into a heart of blue-and-silver druzy crystal like a geode split by hand. Gilded botanical leaves climb the border. Poured one at a time — no two are ever alike.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4026.jpeg', 'available', true, false, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4027.jpeg", "label": "Golden"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4028.jpeg", "label": "Ivory & Gold"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4029.jpeg", "label": "Blush"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4024.jpeg", "label": "Teal (Square)"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4030.jpeg", "label": "Teal & Gold"}]'::jsonb
where not exists (select 1 from pieces where title = 'Resin River Wall Plaque');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Resin River Wall Art — Framed', 'Resin Art', '550', NULL, 'Walnut & epoxy resin on a framed panel, druzy crystal, metallic leaf', 'The Resin River composition on a larger framed panel — a live-edge walnut river and a druzy geode heart set behind a sleek metallic frame, ready to hang as a statement wall piece.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4034.jpeg', 'available', true, false, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4033.jpeg", "label": "Teal & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4035.jpeg", "label": "Ivory Float"}]'::jsonb
where not exists (select 1 from pieces where title = 'Resin River Wall Art — Framed');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Beach Shore Memorial Block', 'Memorial Piece', '150', NULL, 'Epoxy resin, real beach sand, seashells & sea glass', 'A single ocean wave caught mid-break above real beach sand, tiny shells and a piece of sea glass — a quiet keepsake. Can be personalized with a name and dates. Choose an Emerald, Amethyst, or Black tide.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4036.jpeg', 'available', true, false, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4037.jpeg", "label": "Amethyst"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4038.jpeg", "label": "Black"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4041.jpeg", "label": "Emerald \u2014 Personalized"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4039.jpeg", "label": "Black \u2014 With Name"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4040.jpeg", "label": "Black \u2014 Name & Dates"}]'::jsonb
where not exists (select 1 from pieces where title = 'Beach Shore Memorial Block');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Emerald Beach Memorial Coasters', 'Memorial Piece', '150', NULL, 'Epoxy resin, real beach sand & shells — set of coasters', 'A set of coasters carrying the same emerald shoreline as the memorial blocks — real sand, tiny shells, a curl of white surf, and an optional gold name.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4044.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Emerald Beach Memorial Coasters');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Geode Statement Panel', 'Statement Panel', '1145', NULL, 'Epoxy resin, mica pigments, crushed glass & crystal geodes on a large panel', 'A large-format geode pour — rivers of colour split open by silver-and-gold crystal caverns. A statement wall piece that also makes a showstopping wedding or event backdrop (available to rent).', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/81746D25-6F5A-426B-8BB6-6EC446155E6D.jpeg', 'available', true, true, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4085.jpeg", "label": "Blush & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4082.jpeg", "label": "Blue & Silver"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4081.jpeg", "label": "Coral & Gold"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4080.jpeg", "label": "Black & Silver"}]'::jsonb
where not exists (select 1 from pieces where title = 'Geode Statement Panel');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Cremation Ash Keychain', 'Memorial Piece', '45', NULL, 'Epoxy resin with cremation ash & crystal, metal keyring', 'A geode keepsake keychain holding a loved one''s ashes with tiny crystals — carry them with you everywhere. Heart or round, in several colours.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4091.jpeg', 'available', true, false, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4095.jpeg", "label": "Rose Red"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4097.jpeg", "label": "Emerald"}, {"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4098.jpeg", "label": "Amethyst"}]'::jsonb
where not exists (select 1 from pieces where title = 'Cremation Ash Keychain');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'DAD Memorial Keepsake', 'Memorial Piece', '150', NULL, 'Epoxy resin with cremation ash, raised DAD lettering', 'A hexagon keepsake swirled with cremation ash and finished with a raised “DAD” in gold or silver — a quiet tribute for a shelf or desk.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4046.jpeg', 'available', true, false, '[{"image": "https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4047.jpeg", "label": "Silver Lettering"}]'::jsonb
where not exists (select 1 from pieces where title = 'DAD Memorial Keepsake');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Lavender Ash Ornament', 'Memorial Piece', '150', NULL, 'Epoxy resin, pressed lavender & cremation ash, hanging cord', 'A round hanging ornament with real pressed lavender and a whisper of ash suspended in clear resin — light-catching and gentle.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4063.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Lavender Ash Ornament');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Floral Preservation Block', 'Preservation', '150', NULL, 'Epoxy resin preserving your real flowers, personalized lettering', 'Send me your wedding or anniversary bouquet and I''ll preserve it forever inside a crystal-clear resin block, personalized with names and a date. Made to order.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4069.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Floral Preservation Block');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Personalized Ornament', 'Seasonal Gift', '55', NULL, 'Resin ornament with personalized name & character, ribbon', 'Personalized keepsake ornaments — a name, a character, a little glitter. Perfect for stockings, gift tags and the tree.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4066.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Personalized Ornament');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Botanical Memory Frame', 'Preservation', '150', NULL, 'Round wood frame, real pressed flowers & feathers, glass keepsake vial, resin', 'Real pressed flowers, delicate feathers and a tiny glass keepsake vial arranged inside a round wooden frame — a botanical memory kept under glass. Made to order from your own blooms and mementos.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/botanical-memory-frame_2026-09-11_1302.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Botanical Memory Frame');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Ocean Islands — Resin & Moss', 'Mixed Media', '1450', '400', 'Epoxy resin, preserved moss & lichen, gold leaf, crushed minerals on a large panel', 'An aerial view of an emerald archipelago — islands of preserved moss and gold rimmed by rivers of blue-green resin. A true mixed-media original, made to order in your size and palette (and available to rent as an event backdrop).', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/Gemini_Generated_Image_391xt6391xt6391x.jpg', 'available', true, true, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Ocean Islands — Resin & Moss');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Forest Landscape Block', 'Resin Art', '145', NULL, 'Hand-painted forest landscape sealed in a clear epoxy resin block', 'A hand-painted evergreen forest at golden hour — pines mirrored in a still river under a blush sky — sealed inside a crystal-clear resin block that catches the light from every side.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/forest-landscape-block_2026-09-11_1302.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Forest Landscape Block');

insert into pieces (title, type, price, deposit, materials, description, image, status, for_sale, for_rent, variations)
select 'Feather Heart Keychain', 'Memorial Piece', '45', NULL, 'Epoxy resin with a real feather or pressed flower, metal keyring', 'A little resin keepsake keychain holding a real feather or a pressed flower — carried in a heart or a round charm. A quiet way to keep something meaningful close.', 'https://raw.githubusercontent.com/modom123/cecethepieces/main/feather-heart-keychain_2026-09-11_1302.jpeg', 'available', true, false, '[]'::jsonb
where not exists (select 1 from pieces where title = 'Feather Heart Keychain');
