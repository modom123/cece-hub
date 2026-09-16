# Stripe Checkout setup (cecespieces)

Real card payments for **both artwork and Academy classes**. Two small Edge
Functions do the work; you deploy them once and paste a couple of keys. ~20 min.

- **Buy art** → the piece's price is charged, shipping address collected, the
  piece is marked **sold** and the order **confirmed** in the hub.
- **Buy a class** → the class price is charged, the enrollment is **confirmed**
  in the hub roster, a live class's remaining **seats** tick down, and the
  student's class appears in **My Classroom** automatically.

Both read the price from the database inside the function, so amounts can't be
tampered with in the browser. (Classes need the `classes` and
`class_enrollments` tables — run `migrations/classes_*.sql` first.)

## What you need
- A **Stripe account** with a bank connected (stripe.com → activate payments).
- The **Supabase CLI** on your computer: https://supabase.com/docs/guides/cli
  (`npm i -g supabase`, then `supabase login`).

## 1. Link the CLI to your project
```
supabase link --project-ref tssicoxzxcfijdlvtpqm
```

## 2. Set the secrets (from Stripe → Developers → API keys)
```
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxx
supabase secrets set SITE_URL=https://cecespieces.com       # your live website URL
```
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided automatically — don't set them.

## 3. Deploy the checkout function
```
supabase functions deploy create-checkout
```
It will be live at:
```
https://tssicoxzxcfijdlvtpqm.supabase.co/functions/v1/create-checkout
```

## 4. Turn on the website Buy buttons
In the website `index.html`, set:
```js
const STRIPE_CHECKOUT_URL = 'https://tssicoxzxcfijdlvtpqm.supabase.co/functions/v1/create-checkout';
```
(Ask me and I'll flip this for you.) Now any piece **with a price** shows a real
**Buy Now — $X** button → Stripe secure checkout. Pieces with no price still say
"Inquire". The price is read from the database inside the function, so it can't
be tampered with in the browser.

## 5. (Recommended) Auto-mark pieces sold — the webhook
```
supabase functions deploy stripe-webhook --no-verify-jwt
```
Then in **Stripe → Developers → Webhooks → Add endpoint**:
- URL: `https://tssicoxzxcfijdlvtpqm.supabase.co/functions/v1/stripe-webhook`
- Event: `checkout.session.completed`
- Copy the endpoint's **Signing secret** (`whsec_...`) and set it:
```
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
```
After a successful payment this marks a **piece sold** (and confirms its order),
or **confirms a class enrollment** and drops the live seat count — automatically
visible in the hub, with the buyer's name, email and (for art) shipping address.

## 5b. Custom pieces — deposit now, balance invoiced later

Some pieces are **custom / commissions**: the buyer pays a **deposit** up front,
and the **balance** is billed once you confirm the final piece. To enable this:

1. In the hub, give the piece a **Deposit** (Publish form or the piece's
   ✏️ edit). Its **Buy Now** button becomes **"Pay Deposit — $X"** and the
   website explains the balance is invoiced on confirmation.
2. When the deposit is paid, the piece is marked **reserved** and a **deposit**
   order appears in **Website Orders** (filter: *Deposits*).
3. Open that order → **adjust the Final price** if it changed → **Confirm &
   email balance invoice**. This deploys a third function:
   ```
   supabase functions deploy send-balance-invoice
   ```
   It emails the customer a **Stripe invoice** for `final price − deposit`.
4. Add the **`invoice.paid`** event to your Stripe webhook endpoint (alongside
   `checkout.session.completed`). When they pay the invoice, the piece is
   marked **sold** and the order **confirmed** automatically.

## 6. Test
Use Stripe **test mode** first (test keys + card `4242 4242 4242 4242`, any future
date/CVC). Buy a piece → you land back on the site with a thank-you → the hub
shows the order confirmed and the piece marked sold. Then switch to live keys.
