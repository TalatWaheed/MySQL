-- ========================================================================
-- Project: MySQL Ranking Window Functions (ROW_NUMBER, RANK, DENSE_RANK)
-- Author: Talat Waheed
-- Description: Schema setup, sample data with deliberate ties, side-by-side
--              comparisons, and common interview solutions using CTEs.
-- Compatible with: MySQL 8.0+
-- ========================================================================

-- ------------------------------------------------------------------------
-- STEP 1: INITIALIZE DATABASE ENVIRONMENT
-- ------------------------------------------------------------------------
DROP DATABASE IF EXISTS window_functions_demo;
CREATE DATABASE window_functions_demo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE window_functions_demo;

-- ------------------------------------------------------------------------
-- STEP 2: TABLE DEFINITION (DDL)
-- ------------------------------------------------------------------------
CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------
-- STEP 3: SEED SAMPLE DATA (DML)
-- Note: Includes exact salary ties in IT and HR to demonstrate ranking differences.
-- ------------------------------------------------------------------------
INSERT INTO employees (name, department, salary) VALUES
('Aarav Sharma',    'IT', 85000.00), -- Tied top salary in IT
('Diya Patel',      'IT', 85000.00), -- Tied top salary in IT
('Rohan Gupta',     'IT', 70000.00),
('Pooja Verma',     'IT', 60000.00),
('Karan Singhania', 'HR', 65000.00),
('Neha Rao',        'HR', 50000.00),
('Vikram Mehta',    'HR', 50000.00), -- Tied second salary in HR
('Aditi Shah',      'HR', 42000.00);

-- Verify raw data
SELECT * FROM employees ORDER BY department, salary DESC;

-- ------------------------------------------------------------------------
-- STEP 4: QUERIES & EXPLANATIONS
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- 1. ROW_NUMBER() DEMO
-- Concept: Assigns a strict, continuous sequence (1, 2, 3...). Never ties.
-- ------------------------------------------------------------------------
SELECT 
    emp_id,
    name,
    department,
    salary,
    ROW_NUMBER() OVER (
        PARTITION BY department 
        ORDER BY salary DESC
    ) AS row_num
FROM employees;


-- ------------------------------------------------------------------------
-- 2. SIDE-BY-SIDE COMPARISON: ROW_NUMBER vs RANK vs DENSE_RANK
-- Concept:
-- - ROW_NUMBER: Ignores ties, always sequential (1, 2, 3, 4).
-- - RANK: Ties share rank, skips subsequent rank numbers (1, 1, 3, 4).
-- - DENSE_RANK: Ties share rank, leaves NO gaps (1, 1, 2, 3).
-- ------------------------------------------------------------------------
SELECT 
    name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS `row_number`,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS `rank`,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS `dense_rank`
FROM employees;


-- ------------------------------------------------------------------------
-- 3. GLOBAL RANKING (OVER WITHOUT PARTITION BY)
-- Concept: Evaluates rankings across the entire company instead of per department.
-- ------------------------------------------------------------------------
SELECT 
    name,
    department,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS company_wide_rank
FROM employees;


-- ------------------------------------------------------------------------
-- 4. PRACTICAL INTERVIEW QUERY: 2nd Highest Salary Per Department
-- Concept: Window functions cannot be directly filtered in WHERE;
--          wrap inside a CTE first.
-- ------------------------------------------------------------------------
WITH RankedDeptSalaries AS (
    SELECT 
        name,
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department 
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employees
)
SELECT 
    department,
    name,
    salary,
    salary_rank
FROM RankedDeptSalaries
WHERE salary_rank = 2;


-- ------------------------------------------------------------------------
-- 5. PRACTICAL QUERY: Top 2 Earners per Department (Handling Ties Fairly)
-- Concept: Using DENSE_RANK() <= 2 ensures all tied top performers are included.
-- ------------------------------------------------------------------------
WITH TopEarners AS (
    SELECT 
        name,
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department 
            ORDER BY salary DESC
        ) AS rnk
    FROM employees
)
SELECT 
    department,
    name,
    salary,
    rnk
FROM TopEarners
WHERE rnk <= 2
ORDER BY department, rnk, name;
