require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const { initDatabase } = require('./db');
const usersRepo = require('./db/usersRepository');
const productsRepo = require('./db/productsRepository');
const cartRepo = require('./db/cartRepository');
const ordersRepo = require('./db/ordersRepository');
const { createStripeRoutes } = require('./routes/stripeRoutes');
const stripeService = require('./services/stripeService');
const paymentConfig = require('./services/paymentConfig');
const translateService = require('./services/translateService');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'ecommerce_secret_key_2026';

app.use(cors());

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access token required' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
}

const { webhookRouter: stripeWebhookRouter, apiRouter: stripeApiRouter } =
  createStripeRoutes(authenticateToken);

app.use('/api/v2/payments/stripe', stripeWebhookRouter);
app.use(express.json());
app.use('/api/v2/payments/stripe', stripeApiRouter);

// Payment routes (registered early so checkout always works)
app.get('/api/v2/payment-methods', authenticateToken, (req, res) => {
  res.status(200).json({
    data: paymentConfig.getPaymentMethods(),
    demoMode: paymentConfig.isDemoMode(),
    stripeEnabled: stripeService.isConfigured(),
  });
});

app.post('/api/v2/payments/demo-checkout', authenticateToken, async (req, res) => {
  try {
    const { paymentMethod = 'card' } = req.body;
    const storedMethod =
      paymentMethod === 'card' ? 'demo_stripe' : `demo_${paymentMethod}`;

    const order = await ordersRepo.checkout(req.user.id, storedMethod);
    res.status(201).json({
      message: 'Demo payment successful (no real charge)',
      data: order,
      demoMode: true,
    });
  } catch (err) {
    if (err.code === 'CART_EMPTY') {
      return res.status(400).json({ message: err.message });
    }
    console.error('Demo checkout error:', err);
    res.status(500).json({ message: 'Demo checkout failed' });
  }
});

// Translation (Google Cloud Translation API)
app.get('/api/v2/translate/status', (req, res) => {
  res.json({
    data: {
      configured: translateService.isConfigured(),
      supported: ['en', 'am'],
    },
  });
});

app.post('/api/v2/translate', authenticateToken, async (req, res) => {
  try {
    const { text, texts, target = 'am', source = 'en' } = req.body;
    const list = texts || (text != null ? [text] : []);

    if (list.length === 0) {
      return res.status(400).json({ message: 'text or texts array is required' });
    }
    if (!['en', 'am'].includes(target)) {
      return res.status(400).json({ message: 'target must be en or am' });
    }

    const translations = await translateService.translateTexts(list, target, source);
    res.json({
      data: {
        translations,
        target,
        source,
        googleTranslate: translateService.isConfigured(),
      },
    });
  } catch (err) {
    console.error('Translate error:', err.message);
    res.status(500).json({ message: err.message || 'Translation failed' });
  }
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
});
const upload = multer({ storage });

// ══════════════════════════════════════════
//  AUTH ROUTES
// ══════════════════════════════════════════

app.post('/api/v2/auth/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const errors = [];

    if (!email) errors.push('Email is required');
    if (!password) errors.push('Password is required');
    if (!name) errors.push('Name is required');
    if (password && password.length < 6) {
      errors.push('Password must be at least 6 characters');
    }

    if (errors.length > 0) {
      return res.status(400).json({ message: errors });
    }

    const existing = await usersRepo.findByEmail(email);
    if (existing) {
      return res.status(400).json({ message: ['Email already exists'] });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await usersRepo.create({
      id: uuidv4(),
      email,
      name,
      password: hashedPassword,
    });

    const access_token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: '7d',
    });

    res.status(201).json({
      data: {
        id: user.id,
        email: user.email,
        name: user.name,
        access_token,
      },
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ message: 'Registration failed' });
  }
});

app.post('/api/v2/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: ['Email and password are required'] });
    }

    const user = await usersRepo.findByEmail(email);
    if (!user) {
      return res.status(401).json({ message: ['Invalid email or password'] });
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      return res.status(401).json({ message: ['Invalid email or password'] });
    }

    const access_token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: '7d',
    });

    res.status(201).json({ data: { access_token } });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Login failed' });
  }
});

app.get('/api/v2/users/me', authenticateToken, async (req, res) => {
  try {
    const user = await usersRepo.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.status(200).json({
      data: { email: user.email, name: user.name },
    });
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({ message: 'Failed to fetch user' });
  }
});

// ══════════════════════════════════════════
//  PRODUCT ROUTES
// ══════════════════════════════════════════

app.get('/api/v2/products', authenticateToken, async (req, res) => {
  try {
    const { search, category, minPrice, maxPrice } = req.query;
    const products = await productsRepo.findAll({
      search,
      category,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
    });
    res.status(200).json({ data: products });
  } catch (err) {
    console.error('List products error:', err);
    res.status(500).json({ message: 'Failed to fetch products' });
  }
});

app.get('/api/v2/products/categories', authenticateToken, async (req, res) => {
  try {
    const categories = await productsRepo.getCategories();
    res.status(200).json({ data: categories });
  } catch (err) {
    console.error('Categories error:', err);
    res.status(500).json({ message: 'Failed to fetch categories' });
  }
});

app.get('/api/v2/products/:id', authenticateToken, async (req, res) => {
  try {
    const product = await productsRepo.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json({ data: product });
  } catch (err) {
    console.error('Get product error:', err);
    res.status(500).json({ message: 'Failed to fetch product' });
  }
});

app.post('/api/v2/products', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    const { name, description, price } = req.body;

    if (!name || !description || !price) {
      return res.status(400).json({ message: 'name, description, and price are required' });
    }

    const imageUrl = req.file
      ? `http://localhost:${PORT}/uploads/${req.file.filename}`
      : req.body.imageUrl ||
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=400&fit=crop';

    const product = await productsRepo.create({
      id: uuidv4(),
      name,
      description,
      price: parseFloat(price),
      imageUrl,
      category: req.body.category || 'General',
      rating: parseFloat(req.body.rating) || 0,
      stock: parseInt(req.body.stock, 10) || 10,
      sellerId: req.user.id,
    });

    res.status(201).json({ data: product });
  } catch (err) {
    console.error('Create product error:', err);
    res.status(500).json({ message: 'Failed to create product' });
  }
});

app.put('/api/v2/products/:id', authenticateToken, async (req, res) => {
  try {
    const existing = await productsRepo.findById(req.params.id);
    if (!existing) return res.status(404).json({ message: 'Product not found' });

    const { name, description, price } = req.body;
    const product = await productsRepo.update(req.params.id, {
      name,
      description,
      price: price !== undefined ? parseFloat(price) : undefined,
    });

    res.status(200).json({ data: product });
  } catch (err) {
    console.error('Update product error:', err);
    res.status(500).json({ message: 'Failed to update product' });
  }
});

app.delete('/api/v2/products/:id', authenticateToken, async (req, res) => {
  try {
    const deleted = await productsRepo.remove(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json({ message: 'Product deleted successfully' });
  } catch (err) {
    console.error('Delete product error:', err);
    res.status(500).json({ message: 'Failed to delete product' });
  }
});

// ══════════════════════════════════════════
//  CART ROUTES
// ══════════════════════════════════════════

app.get('/api/v2/cart', authenticateToken, async (req, res) => {
  try {
    const cart = await cartRepo.getCartWithProducts(req.user.id);
    res.status(200).json({ data: cart });
  } catch (err) {
    console.error('Get cart error:', err);
    res.status(500).json({ message: 'Failed to fetch cart' });
  }
});

app.post('/api/v2/cart', authenticateToken, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;

    const product = await productsRepo.findById(productId);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    const itemCount = await cartRepo.addItem(req.user.id, productId, quantity);
    res.status(201).json({ message: 'Added to cart', data: { itemCount } });
  } catch (err) {
    console.error('Add to cart error:', err);
    res.status(500).json({ message: 'Failed to add to cart' });
  }
});

app.delete('/api/v2/cart/:itemId', authenticateToken, async (req, res) => {
  try {
    await cartRepo.removeItem(req.user.id, req.params.itemId);
    res.status(200).json({ message: 'Item removed from cart' });
  } catch (err) {
    console.error('Remove cart item error:', err);
    res.status(500).json({ message: 'Failed to remove item' });
  }
});

app.delete('/api/v2/cart', authenticateToken, async (req, res) => {
  try {
    await cartRepo.clearCart(req.user.id);
    res.status(200).json({ message: 'Cart cleared' });
  } catch (err) {
    console.error('Clear cart error:', err);
    res.status(500).json({ message: 'Failed to clear cart' });
  }
});

// ══════════════════════════════════════════
//  PAYMENT & ORDERS
// ══════════════════════════════════════════

app.post('/api/v2/orders/checkout', authenticateToken, async (req, res) => {
  try {
    const { paymentMethod } = req.body;

    if (!paymentMethod) {
      return res.status(400).json({ message: 'paymentMethod is required' });
    }

    const valid = paymentConfig.getPaymentMethods().some((m) => m.id === paymentMethod);
    if (!valid) {
      return res.status(400).json({ message: 'Invalid payment method' });
    }

    if (paymentMethod === 'card') {
      if (paymentConfig.isDemoMode()) {
        const order = await ordersRepo.checkout(req.user.id, 'demo_stripe');
        return res.status(201).json({
          message: 'Demo payment successful',
          data: order,
          demoMode: true,
        });
      }
      return res.status(400).json({
        message: 'Use Pay with Stripe or add STRIPE_SECRET_KEY to .env for card payments',
      });
    }

    const order = await ordersRepo.checkout(req.user.id, paymentMethod);
    res.status(201).json({
      message: 'Order placed successfully',
      data: order,
    });
  } catch (err) {
    if (err.code === 'CART_EMPTY') {
      return res.status(400).json({ message: err.message });
    }
    console.error('Checkout error:', err);
    res.status(500).json({ message: 'Checkout failed' });
  }
});

app.get('/api/v2/orders', authenticateToken, async (req, res) => {
  try {
    const orders = await ordersRepo.findByUserId(req.user.id);
    res.status(200).json({ data: orders });
  } catch (err) {
    console.error('List orders error:', err);
    res.status(500).json({ message: 'Failed to fetch orders' });
  }
});

app.get('/api/v2/orders/:id', authenticateToken, async (req, res) => {
  try {
    const order = await ordersRepo.findById(req.params.id, req.user.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    res.status(200).json({ data: order });
  } catch (err) {
    console.error('Get order error:', err);
    res.status(500).json({ message: 'Failed to fetch order' });
  }
});

// ── Legacy v1 support ──

app.get('/api/v1/products', authenticateToken, async (req, res) => {
  try {
    const products = await productsRepo.findAll();
    res.status(200).json({ data: products });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch products' });
  }
});

app.get('/api/v1/products/:id', authenticateToken, async (req, res) => {
  try {
    const product = await productsRepo.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json({ data: product });
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch product' });
  }
});

// ── Stripe return pages (browser redirect after payment) ──

app.get('/payment/success', async (req, res) => {
  const sessionId = req.query.session_id;
  let message = 'Payment received! Return to the ECOM app and tap "Confirm payment".';

  if (sessionId && stripeService.isConfigured()) {
    try {
      const session = await stripeService.retrieveSession(sessionId);
      if (session.payment_status === 'paid') {
        message = 'Payment successful! You can close this tab and return to the app.';
      }
    } catch {
      // ignore
    }
  }

  res.send(`<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Payment success</title>
<style>body{font-family:system-ui;display:flex;align-items:center;justify-content:center;min-height:100vh;background:#f9fafb;margin:0}
.box{background:#fff;padding:40px;border-radius:16px;text-align:center;max-width:420px;box-shadow:0 4px 24px rgba(0,0,0,.08)}
h1{color:#3F51F3}p{color:#555;line-height:1.6}</style></head>
<body><div class="box"><h1>✓ Payment successful</h1><p>${message}</p></div></body></html>`);
});

app.get('/payment/cancel', (req, res) => {
  res.send(`<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Payment cancelled</title>
<style>body{font-family:system-ui;display:flex;align-items:center;justify-content:center;min-height:100vh;background:#f9fafb;margin:0}
.box{background:#fff;padding:40px;border-radius:16px;text-align:center;max-width:420px;box-shadow:0 4px 24px rgba(0,0,0,.08)}
h1{color:#FF5252}p{color:#555}</style></head>
<body><div class="box"><h1>Payment cancelled</h1><p>Your cart was not charged. Return to the app to try again.</p></div></body></html>`);
});

// ── Health check ──

app.get('/health', async (req, res) => {
  try {
    const count = await productsRepo.count();
    res.json({
      status: 'ok',
      database: 'postgresql',
      products: count,
      stripe: stripeService.isConfigured(),
    });
  } catch {
    res.status(503).json({ status: 'error', database: 'unavailable' });
  }
});

// ── Start server ──

async function start() {
  try {
    const productCount = await initDatabase();
    const categories = await productsRepo.getCategories();

    app.listen(PORT, () => {
      console.log(`\n  Backend running at http://localhost:${PORT}`);
      console.log(`  PostgreSQL connected`);
      console.log(`  ${productCount} products across ${categories.length} categories`);
      console.log(`  Payments: ${paymentConfig.isDemoMode() ? 'DEMO mode (no real charges)' : 'live Stripe'}`);
      console.log(`  Stripe: ${stripeService.isConfigured() ? 'enabled' : 'not configured'}\n`);
    });
  } catch (err) {
    console.error('\n  Failed to connect to PostgreSQL.\n');
    console.error(`  ${err.message}\n`);
    console.error('  1. Start PostgreSQL (Windows Services or pgAdmin)');
    console.error('  2. Create database: run setup.sql in pgAdmin (see DATABASE.md)');
    console.error('  3. Check DATABASE_URL in backend/.env\n');
    process.exit(1);
  }
}

start();
