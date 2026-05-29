const { pool } = require('./pool');
const { initSchema } = require('./schema');
const { seedProducts } = require('./seed');

async function initDatabase() {
  await initSchema();
  const productCount = await seedProducts();
  return productCount;
}

module.exports = { pool, initDatabase };
