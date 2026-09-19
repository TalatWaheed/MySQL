-- ========================================================================
-- Project: Top 10 MySQL Interview Questions Solved Step-by-Step
-- Author: Talat Waheed
-- Description: Complete schema definitions, realistic test edge-case data,
--              and production-ready solutions for top 10 SQL interview problems.
-- Compatible with: MySQL 8.0+
-- ========================================================================

-- ------------------------------------------------------------------------
-- STEP 1: INITIALIZE DATABASE ENVIRONMENT
-- ------------------------------------------------------------------------
DROP DATABASE IF EXISTS interview_prep_db;
CREATE DATABASE interview_prep_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE interview_prep_db;

-- ------------------------------------------------------------------------
-- STEP 2: TABLE DEFINITIONS (DDL)
-- ------------------------------------------------------------------------

-- 1. Employees Table (Self-referencing hierarchy, duplicates, salary test cases)
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    manager_id INT DEFAULT NULL,
    email VARCHAR(120) NOT NULL,
    CONSTRAINT fk_employee_manager 
        FOREIGN KEY (manager_id) REFERENCES employees(id) 
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- 2. Customers Table
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 3. Orders Table (Associated with customers)
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id) 
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Sales Table (Time-series data for running totals & trends)
CREATE TABLE sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL
) ENGINE=InnoDB;

-- 5. User Logins Table (Activity logs for consecutive days problem)
CREATE TABLE user_logins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    login_date DATE NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------
-- STEP 3: SEED TEST DATA (DML)
-- ------------------------------------------------------------------------

-- Insert Employees (Includes ties for highest salary, duplicate emails, and manager links)
INSERT INTO employees (id, name, department, salary, manager_id, email) VALUES
(1, 'Aarav Sharma',    'Executive',   120000.00, NULL, 'aarav@company.com'),
(2, 'Diya Patel',      'Engineering',  95000.00, 1,    'diya@company.com'),
(3, 'Rohan Gupta',     'Engineering',  95000.00, 2,    'rohan@company.com'), -- Tied second-highest salary
(4, 'Pooja Verma',     'Engineering',  70000.00, 2,    'pooja@company.com'),
(5, 'Karan Singhania', 'HR',           65000.00, 1,    'karan@company.com'),
(6, 'Neha Rao',        'HR',           50000.00, 5,    'neha@company.com'),
(7, 'Vikram Mehta',    'Marketing',    80000.00, 1,    'vikram@company.com'),
(8, 'Aditi Shah',      'Marketing',    85000.00, 7,    'aditi@company.com'),  -- Earns more than manager (Vikram: 80k)
(9, 'Diya Patel Copy', 'Engineering',  40000.00, 2,    'diya@company.com');  -- Duplicate email test row

-- Insert Customers
INSERT INTO customers (id, name, email) VALUES
(1, 'Amit Kumar',   'amit@gmail.com'),
(2, 'Sneha Reddy',  'sneha@gmail.com'),
(3, 'Rajesh Iyer',  'rajesh@gmail.com'),
(4, 'Priya Nair',   'priya@gmail.com'); -- Placed no orders

-- Insert Orders
INSERT INTO orders (order_id, customer_id, order_date, amount) VALUES
(101, 1, '2026-08-01', 2500.00),
(102, 1, '2026-08-10', 1400.00),
(103, 2, '2026-08-12', 5600.00),
(104, 3, '2026-08-15', 3100.00);

-- Insert Daily Sales Records
INSERT INTO sales (sale_date, amount) VALUES
('2026-08-01', 1200.00),
('2026-08-02', 1800.00),
('2026-08-03', 1500.00),
('2026-08-04', 2200.00),
('2026-08-05', 3000.00);

-- Insert User Logins (Consecutive date checks)
INSERT INTO user_logins (user_id, login_date) VALUES
(101, '2026-08-01'),
(101, '2026-08-02'), -- Consecutive day for 101
(101, '2026-08-04'),
(102, '2026-08-01'),
(102, '2026-08-05'); -- Not consecutive for 102

-- ------------------------------------------------------------------------
-- STEP 4: TOP 10 INTERVIEW QUESTIONS & QUERIES
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- QUESTION 1: Find the 2nd Highest Salary (Handling Ties Properly)
-- Preferred Approach: Window function DENSE_RANK() avoids duplicate rank skips.
-- ------------------------------------------------------------------------
WITH RankedSalaries AS (
    SELECT 
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS rank_num
    FROM employees
)
SELECT DISTINCT salary AS second_highest_salary
FROM RankedSalaries
WHERE rank_num = 2;


-- ------------------------------------------------------------------------
-- QUESTION 2: Find Duplicate Records (e.g., Duplicate Emails)
-- Explanation: GROUP BY aggregates records; HAVING filters aggregate counts.
-- ------------------------------------------------------------------------
SELECT 
    email,
    COUNT(*) AS occurrence_count
FROM employees
GROUP BY email
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------------------
-- QUESTION 3: Delete Duplicate Rows Keeping Only the Lowest Primary Key
-- Explanation: Self-join matches identical emails and drops records with higher IDs.
-- ------------------------------------------------------------------------
-- (Wrapped in a transaction demo so test data can be preserved if needed)
DELETE e1
FROM employees e1
JOIN employees e2 
  ON e1.email = e2.email 
 AND e1.id > e2.id;

-- Verify deletion
SELECT id, name, email FROM employees WHERE email = 'diya@company.com';


-- ------------------------------------------------------------------------
-- QUESTION 4: Find Employees Who Earn More Than Their Direct Managers
-- Explanation: Self-Join comparing employee row against corresponding manager row.
-- ------------------------------------------------------------------------
SELECT 
    emp.name AS employee_name,
    emp.salary AS employee_salary,
    mgr.name AS manager_name,
    mgr.salary AS manager_salary
FROM employees emp
JOIN employees mgr 
  ON emp.manager_id = mgr.id
WHERE emp.salary > mgr.salary;


-- ------------------------------------------------------------------------
-- QUESTION 5: Find Customers Who Have Never Placed an Order
-- Explanation: LEFT JOIN keeps all customers; filters where right-table PK is NULL.
-- ------------------------------------------------------------------------
SELECT 
    c.id AS customer_id,
    c.name AS customer_name,
    c.email
FROM customers c
LEFT JOIN orders o 
  ON c.id = o.customer_id
WHERE o.order_id IS NULL;


-- ------------------------------------------------------------------------
-- QUESTION 6: Find the Department with the Highest Total Payroll Spend
-- Explanation: Aggregates total salary per department and grabs top 1 via LIMIT.
-- ------------------------------------------------------------------------
SELECT 
    department,
    SUM(salary) AS total_payroll
FROM employees
GROUP BY department
ORDER BY total_payroll DESC
LIMIT 1;


-- ------------------------------------------------------------------------
-- QUESTION 7: Find the Top 3 Highest Earners in Each Department
-- Explanation: Uses DENSE_RANK() partitioned by department wrapped in a CTE.
-- ------------------------------------------------------------------------
WITH DeptRankings AS (
    SELECT 
        department,
        name,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department 
            ORDER BY salary DESC
        ) AS dept_rank
    FROM employees
)
SELECT 
    department,
    name,
    salary,
    dept_rank
FROM DeptRankings
WHERE dept_rank <= 3
ORDER BY department, dept_rank;


-- ------------------------------------------------------------------------
-- QUESTION 8: Calculate Cumulative Running Total of Sales Over Time
-- Explanation: Window function SUM(...) OVER (ORDER BY ...) maintains running balance.
-- ------------------------------------------------------------------------
SELECT 
    sale_date,
    amount,
    SUM(amount) OVER (ORDER BY sale_date) AS running_total
FROM sales;


-- ------------------------------------------------------------------------
-- QUESTION 9: Detect Users Who Logged In on Consecutive Days
-- Explanation: Uses LEAD() to inspect the next login date row and DATEDIFF = 1.
-- ------------------------------------------------------------------------
WITH LoginIntervals AS (
    SELECT 
        user_id,
        login_date,
        LEAD(login_date, 1) OVER (
            PARTITION BY user_id 
            ORDER BY login_date
        ) AS next_login_date
    FROM user_logins
)
SELECT DISTINCT 
    user_id
FROM LoginIntervals
WHERE DATEDIFF(next_login_date, login_date) = 1;


-- ------------------------------------------------------------------------
-- QUESTION 10: Pivot Rows into Columns Without Dynamic SQL
-- Explanation: Uses conditional aggregation (SUM + CASE WHEN) to pivot department spend.
-- ------------------------------------------------------------------------
SELECT 
    SUM(CASE WHEN department = 'Engineering' THEN salary ELSE 0 END) AS engineering_spend,
    SUM(CASE WHEN department = 'HR'          THEN salary ELSE 0 END) AS hr_spend,
    SUM(CASE WHEN department = 'Marketing'   THEN salary ELSE 0 END) AS marketing_spend,
    SUM(CASE WHEN department = 'Executive'   THEN salary ELSE 0 END) AS executive_spend
FROM employees;
