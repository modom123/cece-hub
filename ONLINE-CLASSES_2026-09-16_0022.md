<!--
  FILE: ONLINE-CLASSES_2026-09-16_0022.md
  CREATED: 2026-09-16_0022 UTC
  PURPOSE: How the cecepieces Online Classes (Academy) system works end to end.
-->

# cecepieces Academy — Online Classes System

A complete system for teaching art classes online, spanning the public
website (`cecethepieces`) and the Business Hub / command center (`cece-hub`).

## The 4-class learning ladder (Beginner → Master)

| # | Class | Level | Format | Price |
|---|-------|-------|--------|-------|
| 1 | **Resin 101: Your First Pour** | Beginner | On-demand · 6 lessons | $49 |
| 2 | **Geode & Alcohol Ink Art** | Intermediate | Live workshop | $75 |
| 3 | **Ocean Waves & Memorial Keepsakes** | Advanced | Live workshop | $95 |
| 4 | **The River Table Masterclass** | Master | On-demand · 7 lessons | $129 |

These are seeded from the hub and can be re-priced, rescheduled, hidden or
extended at any time.

## Website (student experience) — `cecethepieces/index.html`

- **Classes page** (new `Classes` nav item): a gold "Academy" section with a
  next-live banner, "how it works", the filterable catalog (All / Live /
  On-Demand / Beginner-Friendly / Advanced), an instructor band, and a
  private-group / gift-a-class CTA.
- **Class detail modal**: full description, curriculum (lessons with a free
  preview), supply list, schedule + seats for live classes, and an **Enroll**
  button.
- **Enrollment** writes to Supabase `class_enrollments` **and** `orders`
  (type `class-enrollment`) so the CRM and Sales agent pick up the lead, then
  emails Cece as a fallback.
- **My Classroom page**: a student enters the email they enrolled with and
  sees every class they own.
  - **On-demand**: a lesson player with per-lesson progress saved on the
    device, a progress bar, and the supply list.
  - **Live**: a countdown, an **Add to Calendar** (.ics) download, and a
    **Join** button that unlocks 15 minutes before start.
  - **Video support**: YouTube, Vimeo and Twitch (VOD + live channel) embed
    inline; Zoom / Google Meet open via a join button (they can't be iframed);
    direct video files play in a native player.

## Command center (Cece) — `cece-hub/cece-hub.html` → **Classes** tab

- **Class Catalog**: each class has an **Offer on site** toggle, an inline
  **price** field, a **type** selector, and — for live workshops — a
  **date/time**, **seats**, and a **join / stream link** (Zoom, Meet, YouTube,
  Twitch). **Save** upserts to Supabase and the website updates within seconds.
- **Full Class Editor** (**+ New Class** / **✏️ Edit full**): build or edit a
  class end to end — title, level, format, price, duration, cover image
  (upload or URL), short blurb, full description, live date/seats/join link,
  the supply list, and a **lessons builder** where each lesson has a title,
  duration, free-preview flag and a video link (YouTube/Vimeo/Twitch embed in
  the classroom; Zoom/Meet become a Join button). Classes can be **deleted**.
- **Add the 4 starter classes**: one click seeds the ladder above.
- **Student Bookings**: lists website enrollments, lets Cece **book a student
  by hand** (phone / gift / private group), mark them **confirmed/paid** or
  **cancelled**, and email them. Stats show classes offered, upcoming live
  sessions, students enrolled and enrolled value.

## Database

Run `supabase/migrations/classes_2026-09-16_0022.sql` once in the Supabase SQL
Editor (the same SQL is also embedded at the bottom of `cece-hub.html`). It
creates two RLS-enabled tables:

- **`classes`** — `id` is a stable text slug; the website shows only rows with
  `active = true`. `materials` and `lessons` are JSON.
- **`class_enrollments`** — one row per student booking.

Until the tables have rows, both apps fall back to the built-in seed, so the
Academy is fully browsable out of the box.
