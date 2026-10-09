-- ==========================================
-- 5 MySQL Subquery Mistakes Beginners Make
-- ==========================================

-- ------------------------------------------
-- 1. SETUP: Create Tables & Insert Data
-- ------------------------------------------
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    order_total DECIMAL(10, 2),
    order_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users (first_name, email) VALUES 
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');

INSERT INTO orders (user_id, order_total, order_date) VALUES 
(1, 50.00, CURDATE()),
(1, 120.00, CURDATE()),
(2, 75.00, CURDATE()),
(3, 200.00, '2023-01-01');

-- ------------------------------------------
-- MISTAKE 1: Returning multiple rows with '='
-- ------------------------------------------
-- ❌ BAD: Throws "Subquery returns more than 1 row"
SELECT first_name 
FROM users 
WHERE user_id = (SELECT user_id FROM orders WHERE order_date = CURDATE());

-- ✅ GOOD: Use IN to handle multiple returned values
SELECT first_name 
FROM users 
WHERE user_id IN (SELECT user_id FROM orders WHERE order_date = CURDATE());

-- ------------------------------------------
-- MISTAKE 2: Forgetting the Derived Table Alias
-- ------------------------------------------
-- ❌ BAD: Throws "Every derived table must have its own alias"
SELECT AVG(total_spent)
FROM (
    SELECT user_id, SUM(order_total) AS total_spent 
    FROM orders 
    GROUP BY user_id
);

-- ✅ GOOD: Added 'AS user_totals' at the end
SELECT AVG(total_spent)
FROM (
    SELECT user_id, SUM(order_total) AS total_spent 
    FROM orders 
    GROUP BY user_id
) AS user_totals;

-- ------------------------------------------
-- MISTAKE 3: Subqueries in the SELECT clause (N+1 Problem)
-- ------------------------------------------
-- ❌ BAD: Runs the subquery for every single user row
SELECT 
    first_name,
    (SELECT COUNT(*) FROM orders WHERE orders.user_id = users.user_id) AS order_count
FROM users;

-- ✅ GOOD: Use a LEFT JOIN and GROUP BY instead
SELECT 
    users.first_name,
    COUNT(orders.order_id) AS order_count
FROM users
LEFT JOIN orders ON users.user_id = orders.user_id
GROUP BY users.user_id;

-- ------------------------------------------
-- MISTAKE 4: Using IN instead of EXISTS for large datasets
-- ------------------------------------------
-- ❌ BAD: Can be slow on massive tables as it evaluates the whole list
SELECT first_name 
FROM users 
WHERE user_id IN (SELECT user_id FROM orders WHERE order_total > 100);

-- ✅ GOOD: EXISTS stops searching as soon as it finds a match
SELECT first_name 
FROM users u
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.user_id = u.user_id AND o.order_total > 100
);

-- ------------------------------------------
-- MISTAKE 5: Using a subquery when a JOIN is simpler
-- ------------------------------------------
-- ❌ BAD: Overcomplicating data retrieval
SELECT first_name, email 
FROM users 
WHERE user_id IN (SELECT user_id FROM orders);

-- ✅ GOOD: Cleaner and often optimized better by MySQL
SELECT DISTINCT u.first_name, u.email
FROM users u
JOIN orders o ON u.user_id = o.user_id;
