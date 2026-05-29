function rowToProduct(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    price: parseFloat(row.price),
    imageUrl: row.image_url,
    category: row.category,
    rating: parseFloat(row.rating),
    stock: row.stock,
  };
}

function rowToUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    password: row.password,
  };
}

module.exports = { rowToProduct, rowToUser };
