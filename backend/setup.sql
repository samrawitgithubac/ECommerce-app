-- Run once in pgAdmin (Query Tool) while logged in as the "postgres" superuser.
-- Database name: ecommercedb
-- App user: ecommerce / password: 12345

CREATE USER ecommerce WITH PASSWORD '12345';

CREATE DATABASE ecommercedb OWNER ecommerce;

GRANT ALL PRIVILEGES ON DATABASE ecommercedb TO ecommerce;
