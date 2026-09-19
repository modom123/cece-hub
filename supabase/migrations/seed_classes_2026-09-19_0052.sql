-- ============================================================================
-- FILE: seed_classes_2026-09-19_0052.sql
-- GENERATED: 2026-09-19_0052 UTC
-- PURPOSE: Create (if needed) and seed the cecespieces Academy `classes` table
--          with the 4-class ladder so the website serves real DB classes
--          (with valid slug IDs) and 'Enroll' reaches Stripe checkout instead
--          of the emailed-payment-link fallback.
-- USAGE:   Paste into Supabase -> SQL Editor -> Run. Idempotent (on conflict
--          do nothing) — safe to re-run; edit prices/dates in the Hub after.
-- ============================================================================

-- Tables + public RLS (no-op if they already exist).
create table if not exists classes (
  id text primary key, created_at timestamptz default now(), track int,
  active boolean default true, title text not null, type text default 'ondemand',
  level text, price text, blurb text, description text, image text,
  instructor text default 'Cece', duration text, start_at timestamptz, join_url text,
  seats int, seats_left int, materials jsonb default '[]'::jsonb, lessons jsonb default '[]'::jsonb
);
alter table classes enable row level security;
drop policy if exists "Public access" on classes;
create policy "Public access" on classes for all using (true) with check (true);

create table if not exists class_enrollments (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  class_id text references classes(id) on delete set null, class_title text, class_type text,
  student_name text not null, student_email text, student_phone text, price text,
  status text default 'pending', source text default 'website', notes text
);
alter table class_enrollments enable row level security;
drop policy if exists "Public access" on class_enrollments;
create policy "Public access" on class_enrollments for all using (true) with check (true);

-- The 4 starter classes (Beginner -> Master).
insert into classes (id, track, active, title, type, level, price, blurb, description, image, instructor, duration, start_at, join_url, seats, seats_left, materials, lessons)
values ($cece$cls-resin101$cece$, 1, true, $cece$Resin 101: Your First Pour$cece$, $cece$ondemand$cece$, $cece$Beginner$cece$, $cece$49$cece$, $cece$Start here. The complete self-paced foundation — mixing, coloring, killing bubbles, and a glass-smooth finish.$cece$, $cece$Everything a total beginner needs, on your own schedule. Watch each lesson as many times as you like, then follow along at your kitchen table. By the end you'll have poured a clean, professional-looking piece and understand exactly why it worked — the perfect first rung of the cecespieces path.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4034.jpeg$cece$, $cece$Cece$cece$, $cece$1 hr 40 min · 6 lessons$cece$, NULL, NULL, NULL, NULL, $cece$["2-part epoxy resin (starter 16 oz)", "A few mica pigments", "Small wood panels or coasters", "Gloves, cups, stir sticks", "Heat gun or torch lighter"]$cece$::jsonb, $cece$[{"title": "What resin is & choosing the right kind", "duration": "12 min", "video_url": "", "free_preview": true}, {"title": "Measuring & mixing without mistakes", "duration": "18 min", "video_url": ""}, {"title": "Coloring: pigments, inks & how much", "duration": "16 min", "video_url": ""}, {"title": "Killing bubbles & controlling cells", "duration": "15 min", "video_url": ""}, {"title": "Your first full pour, step by step", "duration": "25 min", "video_url": ""}, {"title": "Curing, demolding & finishing", "duration": "14 min", "video_url": ""}]$cece$::jsonb)
on conflict (id) do nothing;

insert into classes (id, track, active, title, type, level, price, blurb, description, image, instructor, duration, start_at, join_url, seats, seats_left, materials, lessons)
values ($cece$cls-geode$cece$, 2, true, $cece$Geode & Alcohol Ink Art — Live Workshop$cece$, $cece$live$cece$, $cece$Intermediate$cece$, $cece$75$cece$, $cece$Pour a sparkling crystal geode and bloom petri-style ink art, live with Cece in one relaxed evening.$cece$, $cece$Your next step up: a camera-on evening where we build a crystal geode and play with blooming alcohol inks together, start to finish. I cover cell-making, the crystal edge, and metallic accents, pausing for your questions the whole way. Assumes you've poured at least once (or finished Resin 101).$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/81746D25-6F5A-426B-8BB6-6EC446155E6D.jpeg$cece$, $cece$Cece$cece$, $cece$2 hours$cece$, $cece$2026-09-26T22:00:00Z$cece$::timestamptz, $cece$$cece$, 12, 6, $cece$["2-part epoxy resin (16 oz)", "Mica pigment powders (3–4 colors)", "Alcohol inks (2–3 colors)", "Wooden or canvas panel, 8\"–12\"", "Clear crystals / crushed glass", "Nitrile gloves, cups, stir sticks", "Heat gun or torch lighter"]$cece$::jsonb, $cece$[{"title": "Welcome + safety & workspace setup", "duration": "15 min", "video_url": "", "free_preview": true}, {"title": "Mixing, coloring & the geode base", "duration": "40 min", "video_url": ""}, {"title": "Crystal edge, cells & alcohol-ink blooms", "duration": "40 min", "video_url": ""}, {"title": "Metallics, finishing & live Q&A", "duration": "25 min", "video_url": ""}]$cece$::jsonb)
on conflict (id) do nothing;

insert into classes (id, track, active, title, type, level, price, blurb, description, image, instructor, duration, start_at, join_url, seats, seats_left, materials, lessons)
values ($cece$cls-coastal$cece$, 3, true, $cece$Ocean Waves & Memorial Keepsakes — Live$cece$, $cece$live$cece$, $cece$Advanced$cece$, $cece$95$cece$, $cece$Sculpt lacing waves, a sandy shoreline, and learn to preserve flowers & keepsakes in resin, live.$cece$, $cece$An advanced live session in two parts: first the white lacing-wave technique over real sand for a coastal scene, then the respectful craft of preserving flowers, sand or a keepsake into a memorial piece. Faster paced — best once you're comfortable timing a pour.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4036.jpeg$cece$, $cece$Cece$cece$, $cece$2.5 hours$cece$, $cece$2026-10-04T22:00:00Z$cece$::timestamptz, $cece$$cece$, 10, 4, $cece$["2-part epoxy resin (24 oz)", "White + blue/teal pigments", "Real fine beach sand", "Dried / pressed flowers or a keepsake", "Wood panel, tray or silicone mold", "Heat gun, gloves, cups, stir sticks"]$cece$::jsonb, $cece$[{"title": "The coastal color plan & base layer", "duration": "30 min", "video_url": "", "free_preview": true}, {"title": "The lacing wave technique", "duration": "40 min", "video_url": ""}, {"title": "Preserving flowers & keepsakes, respectfully", "duration": "45 min", "video_url": ""}, {"title": "Finishing, personalization & Q&A", "duration": "25 min", "video_url": ""}]$cece$::jsonb)
on conflict (id) do nothing;

insert into classes (id, track, active, title, type, level, price, blurb, description, image, instructor, duration, start_at, join_url, seats, seats_left, materials, lessons)
values ($cece$cls-river$cece$, 4, true, $cece$The River Table Masterclass$cece$, $cece$ondemand$cece$, $cece$Master$cece$, $cece$129$cece$, $cece$The signature cecespieces look. Live-edge wood + a deep resin river, taught end to end. Our deepest course.$cece$, $cece$The full masterclass on my signature framed river pieces — from prepping live-edge wood and building a leak-proof dam, to the deep colored pour, the druzy crystal heart, sanding back to glass, and the flawless flood coat. The most in-depth course in the Academy and the top of the path.$cece$, $cece$https://raw.githubusercontent.com/modom123/cecethepieces/main/IMG_4026.jpeg$cece$, $cece$Cece$cece$, $cece$2 hr 10 min · 7 lessons$cece$, NULL, NULL, NULL, NULL, $cece$["Live-edge wood slab or board", "Deep-pour epoxy resin (32 oz+)", "Tuck tape & melamine for a dam", "Pigments + druzy crystals", "Orbital sander & finishing supplies", "Heat gun, gloves, cups"]$cece$::jsonb, $cece$[{"title": "Choosing & prepping the wood", "duration": "18 min", "video_url": "", "free_preview": true}, {"title": "Building a leak-proof dam", "duration": "16 min", "video_url": ""}, {"title": "Coloring the river & planning depth", "duration": "18 min", "video_url": ""}, {"title": "The deep pour (and avoiding overheating)", "duration": "22 min", "video_url": ""}, {"title": "Setting the druzy crystal heart", "duration": "20 min", "video_url": ""}, {"title": "Sanding back to glass", "duration": "18 min", "video_url": ""}, {"title": "The flood coat & final seal", "duration": "18 min", "video_url": ""}]$cece$::jsonb)
on conflict (id) do nothing;

-- Verify:
--   select id, track, title, type, level, price, active, seats_left from classes order by track;