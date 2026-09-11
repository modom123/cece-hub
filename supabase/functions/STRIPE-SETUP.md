# Stripe Checkout setup (cecepieces)

Real "Buy Now" buttons that take card payments. Two small Edge Functions do the
work; you deploy them once and paste a couple of keys. ~20 minutes.

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
supabase secrets set SITE_URL=https://cecepieces.com        # your live website URL
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
After a successful payment this marks the piece **sold** and flips the order to
**confirmed** with the buyer's name, email and shipping address — automatically
visible in the hub.

## 6. Test
Use Stripe **test mode** first (test keys + card `4242 4242 4242 4242`, any future
date/CVC). Buy a piece → you land back on the site with a thank-you → the hub
shows the order confirmed and the piece marked sold. Then switch to live keys.
