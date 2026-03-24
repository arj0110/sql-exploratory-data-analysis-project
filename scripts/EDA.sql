/*===============================================================
  Project: Data Warehouse & Analytics Project
  Script : Exploratory Data Analysis (EDA) on Gold Layer
  Author : Ankit Jain
  Description:
      This script performs exploratory data analysis on the
      analytical (Gold) layer of the data warehouse.

      The goal is to:
      - Understand the structure of the database
      - Explore dimension attributes
      - Analyze date coverage
      - Evaluate key business metrics
      - Perform magnitude analysis
      - Identify top/bottom performers using ranking analysis

      The Gold layer follows a Star Schema consisting of:
      - Dimension Tables (Customers, Products)
      - Fact Table (Sales)
================================================================*/

USE DataWarehouseAnalytics;

---------------------------------------------------------------
-- 1. DATABASE EXPLORATION
---------------------------------------------------------------

-- Explore all tables available in the database
-- Helps understand schema structure and available objects
SELECT *
FROM INFORMATION_SCHEMA.TABLES;


-- Explore all columns across tables
-- Useful for understanding attributes and data types
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS;



---------------------------------------------------------------
-- 2. DIMENSION EXPLORATION
---------------------------------------------------------------

-- Explore all distinct countries from the customer dimension
-- Helps understand geographic distribution of customers
SELECT DISTINCT country
FROM gold.dim_customers;


-- Explore product hierarchy
-- Identifies categories, subcategories, and product names
SELECT DISTINCT 
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;



---------------------------------------------------------------
-- 3. DATE EXPLORATION
---------------------------------------------------------------

-- Identify age distribution of customers
-- Finds oldest and youngest customers based on birthdate
SELECT 
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_customer_age,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_customer_age
FROM gold.dim_customers;


-- Determine sales data coverage
-- Finds earliest and latest order date and total duration
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS order_date_range_days
FROM gold.fact_sales;



---------------------------------------------------------------
-- 4. MEASURE EXPLORATION
---------------------------------------------------------------

-- Analyze core sales metrics
-- Provides total revenue, total quantity sold, and average price
SELECT 
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    AVG(price) AS average_price
FROM gold.fact_sales;


-- Count total number of orders
SELECT COUNT(order_number) AS total_orders
FROM gold.fact_sales;


-- Count unique orders
-- Helps detect duplicate orders
SELECT COUNT(DISTINCT order_number) AS unique_orders
FROM gold.fact_sales;


-- Compare distinct products vs total records
SELECT 
    COUNT(DISTINCT product_key) AS unique_products,
    COUNT(product_key) AS total_product_records
FROM gold.dim_products;


-- Total number of customers in the system
SELECT COUNT(customer_id) AS total_customers
FROM gold.dim_customers;


-- Customers who have placed at least one order
SELECT COUNT(DISTINCT customer_key) AS customers_with_orders
FROM gold.fact_sales;



---------------------------------------------------------------
-- BUSINESS KPI SUMMARY REPORT
---------------------------------------------------------------

-- Generates a consolidated KPI table for quick business overview
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT 'Total Quantity', SUM(quantity)
FROM gold.fact_sales

UNION ALL

SELECT 'Average Price', AVG(price)
FROM gold.fact_sales

UNION ALL

SELECT 'Total Orders', COUNT(DISTINCT order_number)
FROM gold.fact_sales

UNION ALL

SELECT 'Total Products', COUNT(product_key)
FROM gold.dim_products

UNION ALL

SELECT 'Total Customers', COUNT(customer_id)
FROM gold.dim_customers

UNION ALL

SELECT 'Customers with Orders', COUNT(DISTINCT customer_key)
FROM gold.fact_sales;



---------------------------------------------------------------
-- 5. MAGNITUDE ANALYSIS
---------------------------------------------------------------

-- Total number of customers by country
-- Helps identify key geographic markets
SELECT 
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;


-- Total number of customers by gender
SELECT 
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;


-- Total products available in each category
SELECT 
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;


-- Average product cost per category
SELECT 
    category,
    AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;


-- Total revenue generated by each product category
SELECT 
    category,
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales fs
RIGHT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
GROUP BY category
ORDER BY total_revenue DESC;


-- Revenue generated by each customer
SELECT 
    dc.customer_key,
    first_name,
    last_name,
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key, first_name, last_name
ORDER BY total_revenue DESC, first_name ASC;


-- Distribution of sold items across countries
SELECT 
    country,
    SUM(quantity) AS total_sold_items
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
GROUP BY country
ORDER BY total_sold_items DESC;



---------------------------------------------------------------
-- 6. RANKING ANALYSIS
---------------------------------------------------------------

-- Top 5 products generating the highest revenue
SELECT TOP (5)
    dp.product_key,
    dp.product_name,
    SUM(sales_amount) AS revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name
ORDER BY revenue DESC;


-- Bottom 5 products with the lowest revenue
SELECT TOP (5)
    dp.product_key,
    dp.product_name,
    SUM(sales_amount) AS revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name
ORDER BY revenue ASC;


-- Top 10 customers generating the highest revenue
SELECT TOP (10)
    dc.customer_key,
    first_name,
    last_name,
    SUM(sales_amount) AS revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key, first_name, last_name
ORDER BY revenue DESC, first_name ASC;


-- 3 customers with the fewest orders
SELECT TOP (3)
    dc.customer_key,
    first_name,
    last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key, first_name, last_name
ORDER BY total_orders ASC, first_name ASC;

