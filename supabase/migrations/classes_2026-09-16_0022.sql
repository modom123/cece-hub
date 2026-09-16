-- ════════════════════════════════════════════════════════════════
-- FILE: classes_2026-09-16_0022.sql
-- CREATED: 2026-09-16_0022 UTC
-- PURPOSE: Online Classes (cecepieces Academy) — tables the public website
--          and the Business Hub share. Run once in the Supabase SQL Editor.
--          The website reads only classes with active = true; the hub's
--          Classes tab manages what is offered, when (start_at) and the price.
-- ════════════════════════════════════════════════════════════════

-- ── CLASSES ──────────────────────────────────────────────────────
create table if not exists classes (
  id           text primary key,          -- stable slug, e.g. 'cls-resin101'
  created_at   timestamptz default now(),
  track        int,                        -- learning-path order (1=Beginner … 4=Master)
  active       boolean default true,       -- offered on the website?
  title        text not null,
  type         text default 'ondemand',    -- 'ondemand' | 'live'
  level        text,                        -- Beginner | Intermediate | Advanced | Master
  price        text,
  blurb        text,
  description  text,
  image        text,
  instructor   text default 'Cece',
  duration     text,
  start_at     timestamptz,                 -- live sessions only
  join_url     text,                        -- Zoom / Google Meet / YouTube / Twitch link
  seats        int,
  seats_left   int,
  materials    jsonb default '[]'::jsonb,   -- supply list (array of strings)
  lessons      jsonb default '[]'::jsonb    -- [{title,duration,video_url,free_preview}]
);
alter table classes enable row level security;
drop policy if exists "Public access" on classes;
create policy "Public access" on classes for all using (true) with check (true);

-- ── CLASS ENROLLMENTS (student bookings) ─────────────────────────
create table if not exists class_enrollments (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz default now(),
  class_id      text references classes(id) on delete set null,
  class_title   text,
  class_type    text,
  student_name  text not null,
  student_email text,
  student_phone text,
  price         text,
  status        text default 'pending',     -- pending | confirmed | cancelled
  source        text default 'website',
  notes         text
);
alter table class_enrollments enable row level security;
drop policy if exists "Public access" on class_enrollments;
create policy "Public access" on class_enrollments for all using (true) with check (true);

-- ✅ Done. In the hub, open the Classes tab and click
--    "Add the 4 starter classes" to seed the Beginner→Master ladder.
