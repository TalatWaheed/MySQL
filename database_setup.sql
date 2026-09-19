-- ========================================================================
-- Project: Connect MySQL to Python & Automate Data Workflows
-- Author: Talat Waheed
-- Description: Complete schema and seed data for automated Python workflows.
-- Compatible with: MySQL 8.0+
-- ========================================================================

-- ------------------------------------------------------------------------
-- STEP 1: INITIALIZE DATABASE
-- ------------------------------------------------------------------------
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ecommerce_db;

-- ------------------------------------------------------------------------
-- STEP 2: SCHEMA DEFINITIONS (DDL)
-- ------------------------------------------------------------------------

-- 1. Categories Table
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 2. Products Table (Includes stock monitor test items)
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. Orders Table
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'completed', 'cancelled') NOT NULL DEFAULT 'completed'
) ENGINE=InnoDB;

-- 4. Order Items Table
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------
-- STEP 3: SAMPLE DATA SEEDING (DML)
-- ------------------------------------------------------------------------

-- Categories
INSERT INTO categories (category_name) VALUES
('Hardware'),
('Peripherals'),
('Furniture');

-- Products (Includes high, low, and out-of-stock items for Python threshold testing)
INSERT INTO products (category_id, title, price, stock) VALUES
(2, 'Wireless Ergonomic Mouse',   1499.00,  45),
(2, 'RGB Mechanical Keyboard',    4499.00,  25),
(1, '27-inch 4K UHD Monitor',    18999.00,   8), -- Trigger alert (<= 15)
(2, 'USB-C Multi-Port Hub',       2199.00,  60),
(3, 'Adjustable Laptop Stand',    1850.00,  12), -- Trigger alert (<= 15)
(3, 'Memory Foam Desk Chair',    12499.00,   0); -- Out of stock (<= 15)

-- Orders
INSERT INTO orders (id, customer_name, order_date, status) VALUES
(101, 'Aarav Sharma',   '2026-09-15 10:00:00', 'completed'),
(102, 'Diya Patel',     '2026-09-16 11:30:00', 'completed'),
(103, 'Rohan Gupta',    '2026-09-18 14:20:00', 'completed'),
(104, 'Pooja Verma',    '2026-09-19 09:15:00', 'completed'),
(105, 'Karan Singhania','2026-09-19 11:00:00', 'processing');

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(101, 1, 2,  1499.00),
(101, 2, 1,  4499.00),
(102, 3, 1, 18999.00),
(102, 5, 2,  1850.00),
(103, 4, 3,  2199.00),
(104, 1, 1,  1499.00),
(104, 3, 1, 18999.00),
(105, 2, 1,  4499.00);

-- Quick verification query
SELECT 
    p.title,
    p.stock,
    COALESCE(SUM(oi.quantity), 0) AS total_sold
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.title, p.stock;
