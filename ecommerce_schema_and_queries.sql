-- ========================================================================
-- Project: Complete E-Commerce Database from Scratch
-- Author: Talat Waheed
-- Description: Full normalized schema, referential integrity constraints,
--              realistic sample seed data, and real-time business reports.
-- Compatible with: MySQL 8.0+
-- ========================================================================

-- ------------------------------------------------------------------------
-- STEP 1: DATABASE INITIALIZATION
-- ------------------------------------------------------------------------
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ecommerce_db;

-- ------------------------------------------------------------------------
-- STEP 2: TABLE CREATION (NORMALIZED DDL WITH CONSTRAINTS)
-- ------------------------------------------------------------------------

-- 1. Users Table (Stores registered customer accounts)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Categories Table (Product catalog classifications)
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 3. Products Table (Stores merchandise, inventory stock, and base pricing)
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

-- 4. Orders Table (Header table tracking customer purchases and status)
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Order Items Table (Junction/Bridge table handling Many-to-Many products & orders)
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

-- Create performance indexes on frequently joined foreign keys
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- ------------------------------------------------------------------------
-- STEP 3: SAMPLE DATA POPULATION (DML SEEDING)
-- ------------------------------------------------------------------------

-- 1. Insert Categories
INSERT INTO categories (category_name) VALUES
('Electronics'),
('Accessories'),
('Home Office');

-- 2. Insert Users
INSERT INTO users (name, email, phone) VALUES
('Aarav Sharma',   'aarav.sharma@example.com',   '+91-9876543210'),
('Diya Patel',     'diya.patel@example.com',     '+91-9876543211'),
('Rohan Gupta',    'rohan.gupta@example.com',    '+91-9876543212'),
('Pooja Verma',    'pooja.verma@example.com',    '+91-9876543213'),
('Karan Singhania','karan.singh@example.com',    '+91-9876543214');

-- 3. Insert Products
INSERT INTO products (category_id, title, price, stock) VALUES
(2, 'Wireless Ergonomic Mouse',  1499.00, 45),
(2, 'RGB Mechanical Keyboard',   4499.00, 25),
(1, '27-inch 4K UHD Monitor',   18999.00,  8),
(2, 'USB-C Multi-Port Hub',      2199.00, 60),
(3, 'Adjustable Laptop Stand',   1850.00, 15),
(3, 'Memory Foam Desk Chair',   12499.00,  0); -- Out of stock intentional test case

-- 4. Insert Orders
INSERT INTO orders (id, user_id, order_date, status) VALUES
(1001, 1, '2026-08-01 10:30:00', 'completed'),
(1002, 2, '2026-08-03 14:15:00', 'completed'),
(1003, 1, '2026-08-10 18:45:00', 'completed'),
(1004, 3, '2026-08-15 09:20:00', 'completed'),
(1005, 4, '2026-08-20 16:00:00', 'processing');
-- Note: User ID 5 (Karan) has no orders to test LEFT JOIN behavior.

-- 5. Insert Order Items (Captures historical unit_price at time of order)
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1001 (Aarav: 2 mice, 1 keyboard)
(1001, 1, 2, 1499.00),
(1001, 2, 1, 4499.00),

-- Order 1002 (Diya: 1 monitor, 1 stand)
(1002, 3, 1, 18999.00),
(1002, 5, 1, 1850.00),

-- Order 1003 (Aarav: 3 USB-C hubs)
(1003, 4, 3, 2199.00),

-- Order 1004 (Rohan: 1 mechanical keyboard)
(1004, 2, 1, 4499.00),

-- Order 1005 (Pooja: 1 wireless mouse, 1 USB-C hub)
(1005, 1, 1, 1499.00),
(1005, 4, 1, 2199.00);

-- ------------------------------------------------------------------------
-- STEP 4: REAL-TIME BUSINESS REPORTING QUERIES
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- QUERY 1: Top-Selling Products by Revenue
-- Business Value: Identifies the merchandise driving majority store income.
-- ------------------------------------------------------------------------
SELECT 
    p.id AS product_id,
    p.title AS product_name,
    c.category_name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE o.status IN ('completed', 'processing')
GROUP BY p.id, p.title, c.category_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------
-- QUERY 2: Customer Lifetime Value (CLV) Report
-- Business Value: Ranks highest spending customers while preserving users
--                 with zero orders using LEFT JOIN & COALESCE.
-- ------------------------------------------------------------------------
SELECT 
    u.id AS user_id,
    u.name AS customer_name,
    u.email,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0.00) AS total_lifetime_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.status = 'completed'
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY u.id, u.name, u.email
ORDER BY total_lifetime_spent DESC;

-- ------------------------------------------------------------------------
-- QUERY 3: Low Inventory Stock Reorder Alerts
-- Business Value: Warehouse automation report flagging restock priorities.
-- ------------------------------------------------------------------------
SELECT 
    p.id AS product_id,
    p.title AS product_name,
    c.category_name,
    p.stock AS current_stock,
    CASE 
        WHEN p.stock = 0 THEN 'CRITICAL: OUT OF STOCK'
        WHEN p.stock <= 10 THEN 'WARNING: LOW STOCK'
        WHEN p.stock <= 25 THEN 'NOTICE: MODERATE STOCK'
        ELSE 'SUFFICIENT'
    END AS stock_status
FROM products p
JOIN categories c ON p.category_id = c.id
ORDER BY p.stock ASC;

-- ------------------------------------------------------------------------
-- QUERY 4: Monthly Sales & Order Trend
-- Business Value: High-level financial reporting by calendar month.
-- ------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT o.id) AS completed_orders,
    SUM(oi.quantity) AS total_items_sold,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY sales_month DESC;
