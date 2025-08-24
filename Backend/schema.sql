-- schema.sql

DROP TABLE IF EXISTS products;

CREATE TABLE products (
    barcode_number TEXT PRIMARY KEY,
    item_name TEXT,
    brand TEXT,
    weight TEXT,
    ingredients TEXT,
    nutritional_info TEXT,
    product_description TEXT
);

 