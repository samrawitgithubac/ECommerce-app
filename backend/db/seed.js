const { pool } = require('./pool');

const SEED_PRODUCTS = [
  {
    id: '1',
    name: 'Classic Leather Oxford',
    description:
      'Handcrafted genuine leather oxford shoes with a timeless design. Features a cushioned insole for all-day comfort and a durable rubber outsole.',
    price: 189.99,
    imageUrl:
      'https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.8,
    stock: 15,
  },
  {
    id: '2',
    name: 'Air Sport Running Shoes',
    description:
      'Lightweight mesh upper with responsive foam cushioning for maximum comfort during runs.',
    price: 129.99,
    imageUrl:
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.6,
    stock: 32,
  },
  {
    id: '3',
    name: 'Slim Fit Denim Jacket',
    description:
      'Classic denim jacket with a modern slim fit silhouette. Made from premium stretch denim.',
    price: 89.99,
    imageUrl:
      'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.5,
    stock: 20,
  },
  {
    id: '4',
    name: 'Wireless Noise-Cancelling Headphones',
    description:
      'Premium over-ear headphones with active noise cancellation and 35-hour battery life.',
    price: 249.99,
    imageUrl:
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.9,
    stock: 8,
  },
  {
    id: '5',
    name: 'Canvas Weekender Bag',
    description:
      'Spacious weekender bag crafted from durable waxed canvas with genuine leather accents.',
    price: 74.99,
    imageUrl:
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.3,
    stock: 25,
  },
  {
    id: '6',
    name: 'Chronograph Steel Watch',
    description:
      'Elegant chronograph watch with a brushed stainless steel case and sapphire crystal glass.',
    price: 329.99,
    imageUrl:
      'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.7,
    stock: 10,
  },
  {
    id: '7',
    name: 'Premium Cotton T-Shirt',
    description: 'Ultra-soft 100% organic cotton crew-neck t-shirt.',
    price: 34.99,
    imageUrl:
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.4,
    stock: 50,
  },
  {
    id: '8',
    name: 'Polarized Aviator Sunglasses',
    description: 'Classic aviator sunglasses with polarized lenses for 100% UV protection.',
    price: 59.99,
    imageUrl:
      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.2,
    stock: 40,
  },
  {
    id: '9',
    name: 'Wireless Earbuds Pro',
    description: 'True wireless earbuds with adaptive noise cancellation and spatial audio.',
    price: 179.99,
    imageUrl:
      'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.6,
    stock: 18,
  },
  {
    id: '10',
    name: 'Suede Chelsea Boots',
    description: 'Premium suede chelsea boots with elastic side panels and pull tab.',
    price: 159.99,
    imageUrl:
      'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=600&h=400&fit=crop',
    category: 'Shoes',
    rating: 4.5,
    stock: 12,
  },
  {
    id: '11',
    name: 'Leather Crossbody Bag',
    description: 'Compact crossbody bag made from full-grain leather with antique brass hardware.',
    price: 94.99,
    imageUrl:
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.4,
    stock: 22,
  },
  {
    id: '12',
    name: 'Hooded Puffer Jacket',
    description: 'Warm insulated puffer jacket with detachable hood.',
    price: 149.99,
    imageUrl:
      'https://images.unsplash.com/photo-1544923246-77307dd270b9?w=600&h=400&fit=crop',
    category: 'Clothing',
    rating: 4.6,
    stock: 14,
  },
  {
    id: '13',
    name: 'Smart Fitness Tracker',
    description: 'Advanced fitness tracker with heart rate monitoring, sleep tracking, and GPS.',
    price: 119.99,
    imageUrl:
      'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=600&h=400&fit=crop',
    category: 'Electronics',
    rating: 4.3,
    stock: 28,
  },
  {
    id: '14',
    name: 'Cashmere Blend Scarf',
    description: 'Luxuriously soft cashmere-wool blend scarf with fringed edges.',
    price: 64.99,
    imageUrl:
      'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.7,
    stock: 30,
  },
  {
    id: '15',
    name: 'Minimalist Leather Wallet',
    description: 'Slim bifold wallet crafted from Italian full-grain leather.',
    price: 49.99,
    imageUrl:
      'https://images.unsplash.com/photo-1627123424574-724758594e93?w=600&h=400&fit=crop',
    category: 'Accessories',
    rating: 4.5,
    stock: 35,
  },
];

async function seedProducts() {
  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM products');
  if (rows[0].count > 0) return rows[0].count;

  for (const p of SEED_PRODUCTS) {
    await pool.query(
      `INSERT INTO products (id, name, description, price, image_url, category, rating, stock)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (id) DO NOTHING`,
      [p.id, p.name, p.description, p.price, p.imageUrl, p.category, p.rating, p.stock]
    );
  }

  const countResult = await pool.query('SELECT COUNT(*)::int AS count FROM products');
  return countResult.rows[0].count;
}

module.exports = { seedProducts, SEED_PRODUCTS };
