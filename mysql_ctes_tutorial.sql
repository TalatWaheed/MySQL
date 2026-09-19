-- ========================================================================
-- Project: Write Cleaner SQL with MySQL CTEs (Say Goodbye to Ugly Subqueries)
-- Author: Talat Waheed
-- Description: Demonstration of Common Table Expressions (CTEs) vs nested subqueries,
--              chaining multiple CTEs, and practical business reporting queries.
-- Compatible with: MySQL 8.0+
-- ========================================================================

-- ------------------------------------------------------------------------
-- STEP 1: INITIALIZE DATABASE ENVIRONMENT
-- ------------------------------------------------------------------------
DROP DATABASE IF EXISTS cte_tutorial_db;
CREATE DATABASE cte_tutorial_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cte_tutorial_db;

-- ------------------------------------------------------------------------
-- STEP 2: TABLE DEFINITION (DDL)
-- ------------------------------------------------------------------------
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    hire_date DATE NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------
-- STEP 3: SAMPLE DATA SEEDING (DML)
-- ------------------------------------------------------------------------
INSERT INTO employees (name, department, salary, hire_date) VALUES
('Aarav Sharma',    'IT',        60000.00, '2023-03-15'),
('Diya Patel',      'IT',        85000.00, '2022-06-01'),
('Rohan Gupta',     'HR',        45000.00, '2024-01-10'),
('Pooja Verma',     'IT',        90000.00, '2021-11-20'),
('Karan Singhania', 'HR',        55000.00, '2023-08-05'),
('Neha Rao',        'Finance',   72000.00, '2022-09-18'),
('Vikram Mehta',    'Finance',   48000.00, '2024-04-12');

-- ------------------------------------------------------------------------
-- STEP 4: QUERIES & COMPARISONS
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- 1. THE OLD WAY: DERIVED TABLE SUBQUERY
-- Goal: Find total staff and average salary for high earners (salary > 50,000)
-- Problem: Filtering is buried inside FROM clause; requires alias at the end.
-- ------------------------------------------------------------------------
SELECT 
    department, 
    COUNT(*) AS total_staff, 
    AVG(salary) AS avg_sal
FROM (
    SELECT * 
    FROM employees 
    WHERE salary > 50000.00
) AS high_earners
GROUP BY department;


-- ------------------------------------------------------------------------
-- 2. THE MODERN WAY: SINGLE BASIC CTE (WITH Clause)
-- Goal: Same report as above, written with top-to-bottom clean logic.
-- ------------------------------------------------------------------------
WITH HighEarners AS (
    SELECT * 
    FROM employees 
    WHERE salary > 50000.00
)
SELECT 
    department, 
    COUNT(*) AS total_staff, 
    AVG(salary) AS avg_sal
FROM HighEarners
GROUP BY department;


-- ------------------------------------------------------------------------
-- 3. CHAINING MULTIPLE CTES TOGETHER
-- Rule: Use WITH only once! Separate subsequent CTEs with commas.
-- Pipeline: Filter IT department -> Find top earners (>= 80k) -> Select results.
-- ------------------------------------------------------------------------
WITH ITStaff AS (
    SELECT * 
    FROM employees 
    WHERE department = 'IT'
),
TopPerformers AS (
    SELECT * 
    FROM ITStaff 
    WHERE salary >= 80000.00
)
SELECT 
    id,
    name, 
    department,
    salary,
    hire_date
FROM TopPerformers;


-- ------------------------------------------------------------------------
-- 4. PRACTICAL CTE: COMPARING INDIVIDUAL SALARY TO DEPARTMENT AVERAGE
-- Goal: Find employees earning more than their own department's average salary.
-- ------------------------------------------------------------------------
WITH DeptAverages AS (
    SELECT 
        department,
        AVG(salary) AS avg_dept_salary
    FROM employees
    GROUP BY department
)
SELECT 
    e.name,
    e.department,
    e.salary,
    ROUND(d.avg_dept_salary, 2) AS dept_average,
    ROUND(e.salary - d.avg_dept_salary, 2) AS salary_difference
FROM employees e
JOIN DeptAverages d 
  ON e.department = d.department
WHERE e.salary > d.avg_dept_salary
ORDER BY salary_difference DESC;
