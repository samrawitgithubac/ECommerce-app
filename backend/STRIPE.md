# Stripe payment setup

Card payments use **Stripe Checkout** (secure hosted payment page).

## 1. Create a Stripe account

1. Go to https://dashboard.stripe.com/register
2. Open **Developers → API keys**
3. Copy:
   - **Publishable key** (`pk_test_...`)
   - **Secret key** (`sk_test_...`)

## 2. Add keys to `backend/.env`

```env
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_CURRENCY=usd
APP_BASE_URL=http://localhost:3000
```

## 3. Webhook (optional but recommended)

For automatic order creation when payment completes:

1. Install [Stripe CLI](https://stripe.com/docs/stripe-cli)
2. Run:

```bash
stripe listen --forward-to localhost:3000/api/v2/payments/stripe/webhook
```

3. Copy the webhook signing secret (`whsec_...`) to `.env`:

```env
STRIPE_WEBHOOK_SECRET=whsec_...
```

Without webhooks, the app still works: after paying, return to the app and tap **Confirm payment**.

## 4. Test card

Use Stripe test card:

- Number: `4242 4242 4242 4242`
- Expiry: any future date
- CVC: any 3 digits

## 5. Restart backend

```bash
npm install
npm start
```

Check: http://localhost:3000/health should show `"stripe": true`
