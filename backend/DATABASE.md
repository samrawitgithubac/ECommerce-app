# Local PostgreSQL setup (no Docker)

Your app uses **local PostgreSQL** only.

| Setting | Value |
|--------|--------|
| Database name | `ecommercedb` |
| Username | `ecommerce` |
| Password | `12345` |
| Host | `localhost` |
| Port | `5432` |

Connection string (already in `.env`):

```text
postgresql://ecommerce:12345@localhost:5432/ecommercedb
```

---

## Step 1 — Install PostgreSQL (if needed)

Download: https://www.postgresql.org/download/windows/

During install, remember the **postgres** superuser password (you need it for pgAdmin).

---

## Step 2 — Create the database (pgAdmin)

1. Open **pgAdmin**.
2. Connect to your server (usually **PostgreSQL 16** → enter your **postgres** password).
3. Click **Tools → Query Tool** (or right-click **postgres** database → **Query Tool**).
4. Open the file `backend/setup.sql` from this project, or paste:

```sql
CREATE USER ecommerce WITH PASSWORD '12345';
CREATE DATABASE ecommercedb OWNER ecommerce;
GRANT ALL PRIVILEGES ON DATABASE ecommercedb TO ecommerce;
```

5. Click **Execute** (▶).

**If you see “role already exists”**, run only:

```sql
ALTER USER ecommerce WITH PASSWORD '12345';
CREATE DATABASE ecommercedb OWNER ecommerce;
```

(Skip `CREATE DATABASE` if `ecommercedb` already exists.)

---

## Step 3 — Start the backend

```powershell
cd "c:\Users\USER\Desktop\Flutterecommercewebsite\E-Commerce-App\backend"
npm install
npm start
```

On first run, the server creates tables (`users`, `products`, `cart_items`) and loads 15 sample products.

---

## Step 4 — Verify

Open in browser: http://localhost:3000/health

Expected:

```json
{ "status": "ok", "database": "postgresql", "products": 15 }
```

---

## Step 5 — Run the Flutter app

```powershell
cd "c:\Users\USER\Desktop\Flutterecommercewebsite\E-Commerce-App\e_commerce_app_clean"
flutter run -d chrome
```

---

## Troubleshooting

| Error | Fix |
|--------|-----|
| `password authentication failed for user "ecommerce"` | Run `ALTER USER ecommerce WITH PASSWORD '12345';` in pgAdmin |
| `database "ecommercedb" does not exist` | Run `CREATE DATABASE ecommercedb OWNER ecommerce;` |
| `connection refused` | Start PostgreSQL: **Services** → **postgresql-x64-…** → **Start** |
| Wrong postgres port | Change `5432` in `backend/.env` if your install uses another port |

You do **not** need Docker for this project.
