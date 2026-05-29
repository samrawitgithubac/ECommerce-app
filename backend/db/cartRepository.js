const { pool } = require('./pool');
const { rowToProduct } = require('./mappers');

async function getCartWithProducts(userId) {
  const { rows } = await pool.query(
    `SELECT ci.id, ci.product_id, ci.quantity,
            p.id AS p_id, p.name, p.description, p.price, p.image_url,
            p.category, p.rating, p.stock
     FROM cart_items ci
     JOIN products p ON p.id = ci.product_id
     WHERE ci.user_id = $1`,
    [userId]
  );

  const items = rows.map((row) => ({
    id: row.id,
    productId: row.product_id,
    quantity: row.quantity,
    product: rowToProduct({
      id: row.p_id,
      name: row.name,
      description: row.description,
      price: row.price,
      image_url: row.image_url,
      category: row.category,
      rating: row.rating,
      stock: row.stock,
    }),
  }));

  const total = items.reduce(
    (sum, item) => sum + item.product.price * item.quantity,
    0
  );

  return { items, total: Math.round(total * 100) / 100 };
}

async function addItem(userId, productId, quantity) {
  const itemId = require('uuid').v4();

  await pool.query(
    `INSERT INTO cart_items (id, user_id, product_id, quantity)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id, product_id)
     DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity`,
    [itemId, userId, productId, quantity]
  );

  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM cart_items WHERE user_id = $1',
    [userId]
  );
  return rows[0].count;
}

async function removeItem(userId, itemId) {
  await pool.query('DELETE FROM cart_items WHERE user_id = $1 AND id = $2', [
    userId,
    itemId,
  ]);
}

async function clearCart(userId) {
  await pool.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);
}

module.exports = { getCartWithProducts, addItem, removeItem, clearCart };
