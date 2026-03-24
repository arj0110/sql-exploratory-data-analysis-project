-- Advanced Data analysis
use DataWarehouseAnalytics;


-- Verify Gold Layer Tables Exist
IF NOT EXISTS (SELECT 1 
               FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'gold' 
               AND TABLE_NAME = 'fact_sales')
BEGIN
    PRINT 'ERROR: Table gold.fact_sales does not exist.';
    RETURN;
END;

IF NOT EXISTS (SELECT 1 
               FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'gold' 
               AND TABLE_NAME = 'dim_customers')
BEGIN
    PRINT 'ERROR: Table gold.dim_customers does not exist.';
    RETURN;
END;

IF NOT EXISTS (SELECT 1 
               FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'gold' 
               AND TABLE_NAME = 'dim_products')
BEGIN
    PRINT 'ERROR: Table gold.dim_products does not exist.';
    RETURN;
END;

PRINT 'All required GOLD layer tables are available. Advanced analysis can proceed.';
GO;


/* ==========================================================
   ADVANCED DATA ANALYSIS
   ==========================================================

   Purpose:
   This script performs advanced analytical queries on the
   Gold Layer of the Data Warehouse. The analysis focuses on
   uncovering business insights from sales, customers, and
   product data using SQL analytical techniques.

   The analysis includes the following sections:

   1. Trend Analysis (Change Over Time)
      - Evaluates sales performance across different time
        periods (yearly and monthly).
      - Measures key metrics such as total sales, number of
        customers, and quantity sold.

   2. Cumulative Analysis
      - Calculates running totals and moving averages to
        understand sales momentum and pricing trends over time.

   3. Performance Analysis
      - Compares yearly product performance.
      - Identifies whether product sales are above or below
        average and performs Year-over-Year (YoY) comparisons.

   4. Part-to-Whole Analysis
      - Determines how much each product category contributes
        to the overall sales.

   5. Data Segmentation
      - Groups products into cost ranges.
      - Segments customers based on spending behavior and
        purchase history (VIP, Regular, New).

   6. Analytical Reporting
      - Creates reusable views that generate consolidated
        customer and product reports.
      - Computes business KPIs such as:
            • Total orders
            • Total sales
            • Customer/product lifespan
            • Recency
            • Average order value (AOV)
            • Average monthly revenue/spend

   These analyses help stakeholders understand sales trends,
   customer behavior, product performance, and overall
   business contribution metrics.

   Database Used: DataWarehouseAnalytics
   Schema: Gold Layer
========================================================== */


--1. Change Over Time(Trend analysis)

Select Year(order_date)as Yearly,sum(sales_amount) as total_sales,
count(distinct customer_key)customers,sum(quantity)total_quantity
from gold.fact_sales
where order_date is not null
group by Year(order_date)
order by Year(order_date);

Select Year(order_date)as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key)customers,
sum(quantity)total_quantity
from gold.fact_sales
where order_date is not null
group by Year(order_date),month(order_date)
order by Year(order_date),month(order_date);

--2. Cumulative Analysis(Moving avg,rolling avg,rolling total sales etc)

-- Total Sales per month and running total

Select *,
	sum(total_sales) over(partition by year(order_date) order by order_date)Rolling_Sales
from(
Select
	DateTRUNC(month,order_date)order_date,sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by 	DateTRUNC(month,order_date)
)t ;

Select *,
	avg(avg_price) over (partition by year(order_date) order by order_date)Moving_average
from(
Select
	DATETRUNC(month,order_date)order_date,
	AVG(price) as avg_price
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
)t ;

--3. Performance Analysis

-- Analyse yearly performance of product by comparing their sales
-- to the avg sales performance of product and the prev year sale 

with yearly_sales as (
Select
	dp.product_name,
	year(fs.order_date)order_year,
	sum(sales_amount)current_sales
from gold.fact_sales fs
left join gold.dim_products dp
on dp.product_key = fs.product_key
where order_date is not NULL
group by product_name,year(order_date)
)
select *,
	avg(current_sales) over(partition by product_name order by order_year)avg_sales,
	(current_sales - avg(current_sales) over(partition by product_name))diff_avg,
	CASE 
		when (current_sales - avg(current_sales) over(partition by product_name))>0 
		then 'Above Avg'
		when (current_sales - avg(current_sales) over(partition by product_name))<0
		then 'Below Avg'
		else 'Same as Avg'
		end as Avg_change_diff,
	-- Year Over Year Analysis 
	LAG(current_sales) over(partition by product_name order by order_year)Prev_year_sale,
		(current_sales - LAG(current_sales) over(partition by product_name order by order_year))Year_sale_Diff,
	CASE 
		WHEN (current_sales - LAG(current_sales) over(partition by product_name order by order_year))>0
		Then 'Increase'
		WHEN (current_sales - LAG(current_sales) over(partition by product_name order by order_year))<0
		then 'Decrease'
		else 'No Change'
		end as YOY_Sale_diff
from yearly_sales;

--4. Part-To-Whole Analysis

--Category contribution to whole sales

with cat_sales as (
select category,
COALESCE(sum(sales_amount),0)total_Sales
from gold.fact_sales fs
right join gold.dim_products dp
on dp.product_key = fs.product_key
where category is not null
group by category
)
select 
category,
total_Sales,
SUM(total_Sales) over() as overall_sales,
	concat(round((cast(total_Sales as float) / SUM(total_Sales)over()) *100,2),'%') AS percentage_total
from cat_sales;


-- 5. Data Segmentation(Grouping)

-- Segment products into cost ranges and count how many products fall into each segment(group)

with cost_cat as (
Select 
	 product_key,
	product_name,
	cost,
	case 
		when cost>=1 and cost<=500 then 'low_cost'
		when cost>=501 and cost<=1000 then 'Budget-friendly'
		when cost>=1001 and cost<1500 then 'Little-expensive'
		when cost>1500 then 'Expensive'
		else 'No value' end as Cost_category
from gold.dim_products
)
select 
	Cost_category,
	count(Cost_category) as total_quantity
from cost_cat
group by Cost_category
order by total_quantity desc;


/*Group customers into three segments based on their spending behavior:
- VIP: at least 12 months of history and spending more than €5,000.
- Regular: at least 12 months of history but spending €5,000 or less.
- New: lifespan less than 12 months.
And find the total number of customers by each group.*/

with cust_cte as (
Select 
	dc.customer_key,
	sum(sales_amount)total_spend,
	min(order_Date) as first_order,
	max(order_date) as last_order,
	DATEDIFF(month,min(order_Date),max(order_Date)) as lifespan
from gold.fact_sales fs
left join gold.dim_customers dc 
ON dc.customer_key = fs.customer_key
group by dc.customer_key
)
select 
	CASE
		WHEN lifespan>=12 and total_spend>5000 then 'VIP'
		WHEN lifespan>=12 and total_spend<5000 then 'Regular'
		else 'New'
		end as Customer_segments,
	SUM(total_spend) as total_sales,
	COUNT(customer_key) as total_customers
from cust_cte
group by (CASE
		WHEN lifespan>=12 and total_spend>5000 then 'VIP'
		WHEN lifespan>=12 and total_spend<5000 then 'Regular'
		else 'New'
		end)
order by total_sales desc;

--6. Reporting 


/*
Customer Report
==========================================================
Purpose :
Highlights:
- This report consolidates key customer metrics and behaviors

1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
	- total orders
	- total sales
	- total quantity purchased
	- total products
	- lifespan (in months)
4. Calculates valuable KPIs:
	- recency (months since last order)
	- average order value
	- average monthly spend
==============================================
*/

CREATE OR ALTER VIEW gold.customer_report   -- View for checking Report for customer
AS
	-- Base query to get the core columns
	WITH base_Cte as (
		Select  
			fs.order_number,
			fs.product_key,
			order_date,
			sales_amount,
			quantity,
			dc.customer_key,
			dc.customer_number,
			concat(dc.first_name,' ',dc.last_name)customer_name,
			DATEDIFF(YEAR,dc.birthdate,GETDATE())Age
		from gold.fact_sales fs
		left join gold.dim_customers dc
		ON dc.customer_key = fs.customer_key
		where order_date is not null
	),
	-- Aggregated results to get aggregated columns with customer details
	aggregated_cte as (
	select 
		customer_key,
		customer_number,
		customer_name,
		age,
		count(distinct order_number) as total_orders,
		sum(sales_amount)total_Sales,
		sum(quantity) as total_quantity,
		count(distinct product_key) as total_products,
		DATEDIFF(month,min(order_date),max(order_Date))lifespan,
		max(order_date)recent_order
	from base_Cte
	group by customer_key,
		customer_number,
		customer_name,
		age
	)
	-- Final Query with important KPI's
	Select 
		customer_key,
		customer_name,
		customer_number,
		CASE
			WHEN age<20 then 'Under 20'
			WHEN age between 20 and 39 then '20-39'
			WHEN age between 40 and 59 then '40-59'
			ELSE '60+'
		END AS age_segment,
		CASE 
			WHEN lifespan>=12 and total_Sales>5000 then 'VIP'
			WHEN lifespan>=12 and total_Sales<5000 then 'Regular'
			else 'New'
			end as Customer_segments,
		total_orders,
		total_Sales,
		total_quantity,
		total_products,
		lifespan,
		recent_order,
		DATEDIFF(month,recent_order,GETDATE()) as recency,
		CASE WHEN total_orders = 0 then 0
			else	total_Sales/total_orders 
			end as AOV, -- Average Order Value
		CASE
			WHEN lifespan = 0 then total_Sales	-- to avoid divide by zero error
			else total_Sales/lifespan 
			end as Avg_Monthly_spend -- Average_Monthly_Spend
	from aggregated_cte;

-- Execute view to see the report 
Select
top(100)* 
from
gold.customer_report; 


/*
Product Report
========
Purpose:
Highlights:
===
- This report consolidates key product metrics and behaviors.

1. Gathers essential fields such as product name, category, subcategory, and cost.
2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
3. Aggregates product-level metrics:
	- total orders
	- total sales
	- total quantity sold
	- total customers (unique)
	- lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last sale)
- average order revenue (AOR)
- average monthly revenue
*/

CREATE OR ALTER VIEW gold.product_report
AS
	--Base query with core columns
	With base_cte as (
	Select 
		s.product_key,
		product_name,
		category,
		subcategory,
		cost,
		s.order_date,
		s.order_number,
		s.customer_key,
		s.sales_amount,
		s.quantity,
		s.price
	from gold.dim_products p
	RIGHT JOIN gold.fact_sales s
	on s.product_key = p.product_key
	where order_date is not null
	), 
	-- Product aggregation for summarising important KPIs
	product_agg as (
	Select 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		max(order_date)recent_order,
		DATEDIFF(month,min(order_date),max(order_Date))lifespan,
		count(distinct order_number)total_orders,
		count(distinct customer_key)total_customers,
		sum(sales_amount)total_sales,
		SUM(quantity)total_quantity,
		AVG(sales_amount/quantity)avg_sell_price
	from base_cte
	group by product_key,
		product_name,
		category,
		subcategory,cost
	)
	-- Final output with KPIs
	Select 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		CASE 
			WHEN total_sales<100000 then 'Low-performer'
			WHEN total_sales between 100000 and 1000000 then 'Mid-performer'
			ELSE 'High Performer'
			end as Product_segment,
		total_orders,
		total_sales,
		total_quantity,
		total_customers,
		lifespan,
		avg_sell_price,
		DATEDIFF(month,recent_order,getdate())recency,
		CASE 
			WHEN total_orders = 0 then 0
			else	total_Sales/total_orders 
			end as AOV, -- Average Order Value,
		CASE 
			WHEN lifespan = 0 then total_sales   -- Average monthly order
			else total_sales/lifespan end 
			as Avg_monthly_sale
	from product_agg


-- Execute the product view
Select
TOP(100)* from gold.product_report