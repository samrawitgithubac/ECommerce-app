const { pool } = require('./pool');
const { v4: uuidv4 } = require('uuid');
const { rowToProduct } = require('./mappers');
const stripeService = require('../services/stripeService');

async function findByStripeSessionId(sessionId) {
  const { rows } = await pool.query(
    'SELECT id, user_id FROM orders WHERE stripe_session_id = $1',
    [sessionId]
  );
  return rows[0] || null;
}

async function checkout(userId, paymentMethod, stripeSessionId = null) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const cartResult = await client.query(
      `SELECT ci.id AS cart_item_id, ci.product_id, ci.quantity,
              p.name, p.price, p.image_url, p.category
       FROM cart_items ci
       JOIN products p ON p.id = ci.product_id
       WHERE ci.user_id = $1`,
      [userId]
    );

    if (cartResult.rows.length === 0) {
      const err = new Error('Your cart is empty');
      err.code = 'CART_EMPTY';
      throw err;
    }

    const total = cartResult.rows.reduce(
      (sum, row) => sum + parseFloat(row.price) * row.quantity,
      0
    );

    const orderId = uuidv4();
    const roundedTotal = Math.round(total * 100) / 100;

    await client.query(
      `INSERT INTO orders (id, user_id, total, payment_method, status, stripe_session_id)
       VALUES ($1, $2, $3, $4, 'paid', $5)`,
      [orderId, userId, roundedTotal, paymentMethod, stripeSessionId]
    );

    for (const row of cartResult.rows) {
      await client.query(
        `INSERT INTO order_items (id, order_id, product_id, quantity, unit_price)
         VALUES ($1, $2, $3, $4, $5)`,
        [uuidv4(), orderId, row.product_id, row.quantity, row.price]
      );
    }

    await client.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);

    await client.query('COMMIT');

    return {
      id: orderId,
      total: roundedTotal,
      paymentMethod,
      status: 'paid',
      itemCount: cartResult.rows.length,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function findByUserId(userId) {
  const { rows } = await pool.query(
    `SELECT o.id, o.total, o.payment_method, o.status, o.created_at,
            COUNT(oi.id)::int AS item_count
     FROM orders o
     LEFT JOIN order_items oi ON oi.order_id = o.id
     WHERE o.user_id = $1
     GROUP BY o.id
     ORDER BY o.created_at DESC`,
    [userId]
  );

  return rows.map((row) => ({
    id: row.id,
    total: parseFloat(row.total),
    paymentMethod: row.payment_method,
    status: row.status,
    createdAt: row.created_at,
    itemCount: row.item_count,
  }));
}

async function findById(orderId, userId) {
  const orderResult = await pool.query(
    `SELECT id, total, payment_method, status, created_at
     FROM orders WHERE id = $1 AND user_id = $2`,
    [orderId, userId]
  );

  if (orderResult.rows.length === 0) return null;

  const order = orderResult.rows[0];
  const itemsResult = await pool.query(
    `SELECT oi.quantity, oi.unit_price, p.id, p.name, p.description, p.image_url, p.category, p.rating, p.stock
     FROM order_items oi
     JOIN products p ON p.id = oi.product_id
     WHERE oi.order_id = $1`,
    [orderId]
  );

  return {
    id: order.id,
    total: parseFloat(order.total),
    paymentMethod: order.payment_method,
    status: order.status,
    createdAt: order.created_at,
    items: itemsResult.rows.map((row) => ({
      quantity: row.quantity,
      unitPrice: parseFloat(row.unit_price),
      product: rowToProduct({
        id: row.id,
        name: row.name,
        description: row.description,
        price: row.unit_price,
        image_url: row.image_url,
        category: row.category,
        rating: row.rating,
        stock: row.stock,
      }),
    })),
  };
}

async function fulfillStripeSession(sessionId, userId) {
  const existing = await findByStripeSessionId(sessionId);
  if (existing) {
    return findById(existing.id, userId);
  }

  const session = await stripeService.retrieveSession(sessionId);

  if (session.payment_status !== 'paid') {
    const err = new Error('Payment not completed yet');
    err.code = 'PAYMENT_INCOMPLETE';
    throw err;
  }

  if (session.metadata?.userId !== userId) {
    const err = new Error('Invalid payment session');
    err.code = 'FORBIDDEN';
    throw err;
  }

  const order = await checkout(userId, 'stripe', sessionId);
  return findById(order.id, userId);
}

module.exports = {
  checkout,
  findByUserId,
  findById,
  findByStripeSessionId,
  fulfillStripeSession,
};
