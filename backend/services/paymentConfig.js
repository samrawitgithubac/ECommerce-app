const stripeService = require('./stripeService');

function isDemoMode() {
  if (process.env.DEMO_MODE === 'true') return true;
  if (process.env.DEMO_MODE === 'false') return false;
  // No Stripe secret key → demo mode (no real charges)
  return !stripeService.isConfigured();
}

function getPaymentMethods() {
  const demo = isDemoMode();

  return [
    {
      id: 'card',
      name: demo ? 'Card (Demo – Stripe test)' : 'Credit / Debit Card (Stripe)',
      description: demo
        ? 'Simulated card payment. No real money. Optional: add Stripe test keys for full checkout.'
        : 'Secure payment via Stripe',
    },
    {
      id: 'paypal',
      name: 'PayPal (Demo)',
      description: 'Simulated PayPal – demo only',
    },
    {
      id: 'mobile',
      name: 'Mobile Money (Demo)',
      description: 'Simulated mobile payment – demo only',
    },
    {
      id: 'cod',
      name: 'Cash on Delivery',
      description: 'Pay when you receive the order',
    },
  ];
}

module.exports = { isDemoMode, getPaymentMethods };
