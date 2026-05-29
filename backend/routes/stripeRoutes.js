const express = require('express');
const stripeService = require('../services/stripeService');
const cartRepo = require('../db/cartRepository');
const usersRepo = require('../db/usersRepository');
const ordersRepo = require('../db/ordersRepository');

function createStripeRoutes(authenticateToken) {
  const webhookRouter = express.Router();
  const apiRouter = express.Router();

  webhookRouter.post(
    '/webhook',
    express.raw({ type: 'application/json' }),
    async (req, res) => {
      try {
        const signature = req.headers['stripe-signature'];
        const event = stripeService.constructWebhookEvent(req.body, signature);

        if (event.type === 'checkout.session.completed') {
          const session = event.data.object;
          const userId = session.metadata?.userId;

          if (userId && session.payment_status === 'paid') {
            const existing = await ordersRepo.findByStripeSessionId(session.id);
            if (!existing) {
              await ordersRepo.checkout(userId, 'stripe', session.id);
            }
          }
        }

        res.json({ received: true });
      } catch (err) {
        console.error('Stripe webhook error:', err.message);
        res.status(400).send(`Webhook Error: ${err.message}`);
      }
    }
  );

  apiRouter.get('/config', authenticateToken, (req, res) => {
    res.json({
      data: {
        enabled: stripeService.isConfigured(),
        publishableKey: process.env.STRIPE_PUBLISHABLE_KEY || '',
        currency: (process.env.STRIPE_CURRENCY || 'usd').toUpperCase(),
      },
    });
  });

  apiRouter.post('/create-checkout-session', authenticateToken, async (req, res) => {
    try {
      if (!stripeService.isConfigured()) {
        return res.status(503).json({
          message: 'Stripe is not configured. Add STRIPE_SECRET_KEY to backend/.env',
        });
      }

      const cart = await cartRepo.getCartWithProducts(req.user.id);
      const user = await usersRepo.findById(req.user.id);

      const session = await stripeService.createCheckoutSession({
        userId: req.user.id,
        userEmail: user?.email,
        cart,
      });

      res.status(201).json({ data: session });
    } catch (err) {
      if (err.code === 'CART_EMPTY') {
        return res.status(400).json({ message: err.message });
      }
      console.error('Stripe checkout session error:', err);
      res.status(500).json({ message: err.message || 'Failed to create Stripe session' });
    }
  });

  apiRouter.get('/verify-session', authenticateToken, async (req, res) => {
    try {
      const { session_id: sessionId } = req.query;
      if (!sessionId) {
        return res.status(400).json({ message: 'session_id is required' });
      }

      const order = await ordersRepo.fulfillStripeSession(sessionId, req.user.id);
      res.status(200).json({
        message: 'Payment verified and order placed',
        data: {
          id: order.id,
          total: order.total,
          paymentMethod: order.paymentMethod,
          status: order.status,
          itemCount: order.items.length,
        },
      });
    } catch (err) {
      if (err.code === 'PAYMENT_INCOMPLETE') {
        return res.status(402).json({ message: err.message });
      }
      if (err.code === 'FORBIDDEN') {
        return res.status(403).json({ message: err.message });
      }
      console.error('Verify Stripe session error:', err);
      res.status(500).json({ message: 'Failed to verify payment' });
    }
  });

  return { webhookRouter, apiRouter };
}

module.exports = { createStripeRoutes };
