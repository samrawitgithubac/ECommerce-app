const { pool } = require('./pool');
const { rowToProduct } = require('./mappers');

async function findAll(filters = {}) {
  const conditions = [];
  const values = [];
  let paramIndex = 1;

  if (filters.search) {
    conditions.push(
      `(LOWER(name) LIKE $${paramIndex} OR LOWER(description) LIKE $${paramIndex})`
    );
    values.push(`%${filters.search.toLowerCase()}%`);
    paramIndex++;
  }
  if (filters.category) {
    conditions.push(`LOWER(category) = $${paramIndex}`);
    values.push(filters.category.toLowerCase());
    paramIndex++;
  }
  if (filters.minPrice !== undefined) {
    conditions.push(`price >= $${paramIndex}`);
    values.push(filters.minPrice);
    paramIndex++;
  }
  if (filters.maxPrice !== undefined) {
    conditions.push(`price <= $${paramIndex}`);
    values.push(filters.maxPrice);
    paramIndex++;
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const { rows } = await pool.query(
    `SELECT * FROM products ${where} ORDER BY created_at DESC`,
    values
  );
  return rows.map(rowToProduct);
}

async function findById(id) {
  const { rows } = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
  return rowToProduct(rows[0]);
}

async function getCategories() {
  const { rows } = await pool.query(
    'SELECT DISTINCT category FROM products ORDER BY category'
  );
  return rows.map((r) => r.category);
}

async function create(product) {
  const { rows } = await pool.query(
    `INSERT INTO products (id, name, description, price, image_url, category, rating, stock, seller_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *`,
    [
      product.id,
      product.name,
      product.description,
      product.price,
      product.imageUrl,
      product.category,
      product.rating,
      product.stock,
      product.sellerId || null,
    ]
  );
  return rowToProduct(rows[0]);
}

async function update(id, fields) {
  const updates = [];
  const values = [];
  let paramIndex = 1;

  if (fields.name !== undefined) {
    updates.push(`name = $${paramIndex++}`);
    values.push(fields.name);
  }
  if (fields.description !== undefined) {
    updates.push(`description = $${paramIndex++}`);
    values.push(fields.description);
  }
  if (fields.price !== undefined) {
    updates.push(`price = $${paramIndex++}`);
    values.push(fields.price);
  }
  if (fields.imageUrl !== undefined) {
    updates.push(`image_url = $${paramIndex++}`);
    values.push(fields.imageUrl);
  }
  if (fields.category !== undefined) {
    updates.push(`category = $${paramIndex++}`);
    values.push(fields.category);
  }
  if (fields.rating !== undefined) {
    updates.push(`rating = $${paramIndex++}`);
    values.push(fields.rating);
  }
  if (fields.stock !== undefined) {
    updates.push(`stock = $${paramIndex++}`);
    values.push(fields.stock);
  }

  if (updates.length === 0) return findById(id);

  values.push(id);
  const { rows } = await pool.query(
    `UPDATE products SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
    values
  );
  return rowToProduct(rows[0]);
}

async function remove(id) {
  const { rowCount } = await pool.query('DELETE FROM products WHERE id = $1', [id]);
  return rowCount > 0;
}

async function count() {
  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM products');
  return rows[0].count;
}

module.exports = {
  findAll,
  findById,
  getCategories,
  create,
  update,
  remove,
  count,
};
