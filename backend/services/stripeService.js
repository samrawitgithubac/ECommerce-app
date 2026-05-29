const Stripe = require('stripe');

function getStripe() {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  return new Stripe(key);
}

function isConfigured() {
  return Boolean(process.env.STRIPE_SECRET_KEY);
}

function getAppBaseUrl() {
  return process.env.APP_BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
}

async function createCheckoutSession({ userId, userEmail, cart }) {
  const stripe = getStripe();
  if (!stripe) {
    const err = new Error('Stripe is not configured. Add STRIPE_SECRET_KEY to .env');
    err.code = 'STRIPE_NOT_CONFIGURED';
    throw err;
  }

  if (!cart.items || cart.items.length === 0) {
    const err = new Error('Your cart is empty');
    err.code = 'CART_EMPTY';
    throw err;
  }

  const currency = (process.env.STRIPE_CURRENCY || 'usd').toLowerCase();
  const baseUrl = getAppBaseUrl();

  const lineItems = cart.items.map((item) => ({
    quantity: item.quantity,
    price_data: {
      currency,
      unit_amount: Math.round(parseFloat(item.product.price) * 100),
      product_data: {
        name: item.product.name,
        description: item.product.category
          ? `Category: ${item.product.category}`
          : undefined,
        images: item.product.imageUrl ? [item.product.imageUrl] : undefined,
      },
    },
  }));

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    payment_method_types: ['card'],
    line_items: lineItems,
    metadata: {
      userId,
    },
    customer_email: userEmail || undefined,
    success_url: `${baseUrl}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${baseUrl}/payment/cancel`,
  });

  return {
    sessionId: session.id,
    url: session.url,
  };
}

async function retrieveSession(sessionId) {
  const stripe = getStripe();
  if (!stripe) {
    const err = new Error('Stripe is not configured');
    err.code = 'STRIPE_NOT_CONFIGURED';
    throw err;
  }
  return stripe.checkout.sessions.retrieve(sessionId);
}

function constructWebhookEvent(rawBody, signature) {
  const stripe = getStripe();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!stripe || !secret) {
    const err = new Error('Stripe webhook is not configured');
    err.code = 'STRIPE_NOT_CONFIGURED';
    throw err;
  }

  return stripe.webhooks.constructEvent(rawBody, signature, secret);
}

module.exports = {
  isConfigured,
  getAppBaseUrl,
  createCheckoutSession,
  retrieveSession,
  constructWebhookEvent,
};
