const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'ecommerce_secret_key_2026';

app.use(cors());
app.use(express.json());
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

// ── In-memory database ──

const users = [];

const products = [
  {
    id: '1',
    name: 'Classic Leather Oxford',
    description: 'Handcrafted genuine leather oxford shoes with a timeless design. Features a cushioned insole for all-day comfort and a durable rubber outsole. Perfect for formal occasions and business settings.',
    price: 189.99,
    imageUrl: 'https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.8,
    stock: 15,
  },
  {
    id: '2',
    name: 'Air Sport Running Shoes',
    description: 'Lightweight mesh upper with responsive foam cushioning for maximum comfort during runs. Breathable design keeps feet cool, while the rubber waffle outsole provides excellent traction on any surface.',
    price: 129.99,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.6,
    stock: 32,
  },
  {
    id: '3',
    name: 'Slim Fit Denim Jacket',
    description: 'Classic denim jacket with a modern slim fit silhouette. Made from premium stretch denim with copper button closures. Features two chest pockets and side pockets for functionality.',
    price: 89.99,
    imageUrl: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.5,
    stock: 20,
  },
  {
    id: '4',
    name: 'Wireless Noise-Cancelling Headphones',
    description: 'Premium over-ear headphones with active noise cancellation and 35-hour battery life. Hi-Res Audio certified with deep bass and crystal-clear treble. Foldable design with premium carrying case included.',
    price: 249.99,
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.9,
    stock: 8,
  },
  {
    id: '5',
    name: 'Canvas Weekender Bag',
    description: 'Spacious weekender bag crafted from durable waxed canvas with genuine leather accents. Interior laptop sleeve fits up to 15-inch laptops. Adjustable shoulder strap and reinforced handles.',
    price: 74.99,
    imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.3,
    stock: 25,
  },
  {
    id: '6',
    name: 'Chronograph Steel Watch',
    description: 'Elegant chronograph watch with a brushed stainless steel case and sapphire crystal glass. Japanese quartz movement with date display. Water resistant to 100 meters.',
    price: 329.99,
    imageUrl: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.7,
    stock: 10,
  },
  {
    id: '7',
    name: 'Premium Cotton T-Shirt',
    description: 'Ultra-soft 100% organic cotton crew-neck t-shirt. Pre-shrunk fabric with reinforced stitching for durability. Available in a relaxed fit for everyday comfort.',
    price: 34.99,
    imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.4,
    stock: 50,
  },
  {
    id: '8',
    name: 'Polarized Aviator Sunglasses',
    description: 'Classic aviator sunglasses with polarized lenses for 100% UV protection. Lightweight metal frame with adjustable nose pads. Includes microfiber cleaning cloth and hard case.',
    price: 59.99,
    imageUrl: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.2,
    stock: 40,
  },
  {
    id: '9',
    name: 'Wireless Earbuds Pro',
    description: 'True wireless earbuds with adaptive noise cancellation and spatial audio. IPX5 water resistant with 8-hour battery life per charge. Wireless charging case provides additional 24 hours.',
    price: 179.99,
    imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.6,
    stock: 18,
  },
  {
    id: '10',
    name: 'Suede Chelsea Boots',
    description: 'Premium suede chelsea boots with elastic side panels and pull tab. Leather-lined interior with cushioned footbed. Stacked leather heel and durable rubber sole.',
    price: 159.99,
    imageUrl: 'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.5,
    stock: 12,
  },
  {
    id: '11',
    name: 'Leather Crossbody Bag',
    description: 'Compact crossbody bag made from full-grain leather with antique brass hardware. Multiple interior pockets and card slots. Adjustable strap for comfortable wear.',
    price: 94.99,
    imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.4,
    stock: 22,
  },
  {
    id: '12',
    name: 'Hooded Puffer Jacket',
    description: 'Warm insulated puffer jacket with detachable hood. Water-resistant outer shell with synthetic fill for lightweight warmth. Two-way front zip with internal storm flap.',
    price: 149.99,
    imageUrl: 'https://images.unsplash.com/photo-1544923246-77307dd270b9?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.6,
    stock: 14,
  },
  {
    id: '13',
    name: 'Smart Fitness Tracker',
    description: 'Advanced fitness tracker with heart rate monitoring, sleep tracking, and GPS. AMOLED display with always-on option. 7-day battery life with rapid charging support.',
    price: 119.99,
    imageUrl: 'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.3,
    stock: 28,
  },
  {
    id: '14',
    name: 'Cashmere Blend Scarf',
    description: 'Luxuriously soft cashmere-wool blend scarf with fringed edges. Generously sized for multiple styling options. Naturally temperature regulating for year-round comfort.',
    price: 64.99,
    imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.7,
    stock: 30,
  },
  {
    id: '15',
    name: 'Minimalist Leather Wallet',
    description: 'Slim bifold wallet crafted from Italian full-grain leather. RFID blocking technology protects your cards. Six card slots, two bill compartments, and an ID window.',
    price: 49.99,
    imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.5,
    stock: 35,
  },
];

const carts = {};

// ── Helper: verify JWT token ──

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

// ══════════════════════════════════════════
//  AUTH ROUTES
// ══════════════════════════════════════════

app.post('/api/v2/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  const errors = [];

  if (!email) errors.push('Email is required');
  if (!password) errors.push('Password is required');
  if (!name) errors.push('Name is required');
  if (password && password.length < 6) errors.push('Password must be at least 6 characters');

  if (errors.length > 0) {
    return res.status(400).json({ message: errors });
  }

  if (users.find((u) => u.email === email)) {
    return res.status(400).json({ message: ['Email already exists'] });
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = { id: uuidv4(), email, name, password: hashedPassword };
  users.push(user);

  res.status(201).json({
    data: { id: user.id, email: user.email, name: user.name },
  });
});

app.post('/api/v2/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: ['Email and password are required'] });
  }

  const user = users.find((u) => u.email === email);
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
});

app.get('/api/v2/users/me', authenticateToken, (req, res) => {
  const user = users.find((u) => u.id === req.user.id);
  if (!user) return res.status(404).json({ message: 'User not found' });

  res.status(200).json({
    data: { email: user.email, name: user.name },
  });
});

// ══════════════════════════════════════════
//  PRODUCT ROUTES
// ══════════════════════════════════════════

app.get('/api/v2/products', authenticateToken, (req, res) => {
  let filtered = [...products];
  const { search, category, minPrice, maxPrice } = req.query;

  if (search) {
    const q = search.toLowerCase();
    filtered = filtered.filter(
      (p) => p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q)
    );
  }
  if (category) {
    filtered = filtered.filter((p) => p.category.toLowerCase() === category.toLowerCase());
  }
  if (minPrice) {
    filtered = filtered.filter((p) => p.price >= parseFloat(minPrice));
  }
  if (maxPrice) {
    filtered = filtered.filter((p) => p.price <= parseFloat(maxPrice));
  }

  res.status(200).json({ data: filtered });
});

app.get('/api/v2/products/categories', authenticateToken, (req, res) => {
  const categories = [...new Set(products.map((p) => p.category))];
  res.status(200).json({ data: categories });
});

app.get('/api/v2/products/:id', authenticateToken, (req, res) => {
  const product = products.find((p) => p.id === req.params.id);
  if (!product) return res.status(404).json({ message: 'Product not found' });
  res.status(200).json({ data: product });
});

app.post('/api/v2/products', authenticateToken, upload.single('image'), (req, res) => {
  const { name, description, price } = req.body;

  if (!name || !description || !price) {
    return res.status(400).json({ message: 'name, description, and price are required' });
  }

  const imageUrl = req.file
    ? `http://localhost:${PORT}/uploads/${req.file.filename}`
    : (req.body.imageUrl || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=400&fit=crop');

  const product = {
    id: uuidv4(),
    name,
    description,
    price: parseFloat(price),
    imageUrl,
    category: req.body.category || 'General',
    rating: 0,
    stock: parseInt(req.body.stock) || 10,
  };

  products.push(product);
  res.status(201).json({ data: product });
});

app.put('/api/v2/products/:id', authenticateToken, (req, res) => {
  const index = products.findIndex((p) => p.id === req.params.id);
  if (index === -1) return res.status(404).json({ message: 'Product not found' });

  const { name, description, price } = req.body;

  if (name) products[index].name = name;
  if (description) products[index].description = description;
  if (price !== undefined) products[index].price = parseFloat(price);

  res.status(200).json({ data: products[index] });
});

app.delete('/api/v2/products/:id', authenticateToken, (req, res) => {
  const index = products.findIndex((p) => p.id === req.params.id);
  if (index === -1) return res.status(404).json({ message: 'Product not found' });

  products.splice(index, 1);
  res.status(200).json({ message: 'Product deleted successfully' });
});

// ══════════════════════════════════════════
//  CART ROUTES
// ══════════════════════════════════════════

app.get('/api/v2/cart', authenticateToken, (req, res) => {
  const userId = req.user.id;
  const cart = carts[userId] || [];
  const items = cart.map((item) => {
    const product = products.find((p) => p.id === item.productId);
    return { ...item, product };
  }).filter((item) => item.product);

  const total = items.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  res.status(200).json({ data: { items, total: Math.round(total * 100) / 100 } });
});

app.post('/api/v2/cart', authenticateToken, (req, res) => {
  const userId = req.user.id;
  const { productId, quantity = 1 } = req.body;

  const product = products.find((p) => p.id === productId);
  if (!product) return res.status(404).json({ message: 'Product not found' });

  if (!carts[userId]) carts[userId] = [];

  const existing = carts[userId].find((item) => item.productId === productId);
  if (existing) {
    existing.quantity += quantity;
  } else {
    carts[userId].push({ id: uuidv4(), productId, quantity });
  }

  res.status(201).json({ message: 'Added to cart', data: { itemCount: carts[userId].length } });
});

app.delete('/api/v2/cart/:itemId', authenticateToken, (req, res) => {
  const userId = req.user.id;
  if (!carts[userId]) return res.status(200).json({ message: 'Cart is empty' });

  carts[userId] = carts[userId].filter((item) => item.id !== req.params.itemId);
  res.status(200).json({ message: 'Item removed from cart' });
});

app.delete('/api/v2/cart', authenticateToken, (req, res) => {
  const userId = req.user.id;
  carts[userId] = [];
  res.status(200).json({ message: 'Cart cleared' });
});

// ── Legacy v1 support ──

app.get('/api/v1/products', authenticateToken, (req, res) => {
  res.status(200).json({ data: products });
});

app.get('/api/v1/products/:id', authenticateToken, (req, res) => {
  const product = products.find((p) => p.id === req.params.id);
  if (!product) return res.status(404).json({ message: 'Product not found' });
  res.status(200).json({ data: product });
});

// ── Start server ──

app.listen(PORT, () => {
  console.log(`\n  Backend running at http://localhost:${PORT}`);
  console.log(`  ${products.length} products loaded across ${[...new Set(products.map(p => p.category))].length} categories\n`);
});
