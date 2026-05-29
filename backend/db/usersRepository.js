const { pool } = require('./pool');
const { rowToUser } = require('./mappers');

async function findByEmail(email) {
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  return rowToUser(rows[0]);
}

async function findById(id) {
  const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  return rowToUser(rows[0]);
}

async function create({ id, email, name, password }) {
  const { rows } = await pool.query(
    `INSERT INTO users (id, email, name, password)
     VALUES ($1, $2, $3, $4)
     RETURNING id, email, name`,
    [id, email, name, password]
  );
  return rows[0];
}

module.exports = { findByEmail, findById, create };
