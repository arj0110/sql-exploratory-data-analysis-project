# SQL Exploratory Data Analysis Project

# 📊 Sales Analytics SQL Project

## Overview

This project performs **Exploratory Data Analysis (EDA)** and **Advanced Data Analysis** using SQL on a **Data Warehouse Gold Layer**.
The goal is to analyze **sales trends, customer behavior, and product performance** to generate meaningful business insights.

The dataset comes from a structured warehouse architecture (**Bronze → Silver → Gold**), where the Gold layer contains cleaned and analytics-ready data.

---

# 🔎 Exploratory Data Analysis (EDA)

EDA was performed to understand the structure and quality of the dataset.

Key tasks:

* Exploring database tables and columns
* Analyzing customer locations
* Understanding product categories and hierarchy
* Identifying unique values and data distribution

This step ensures the data is **clean and ready for deeper analysis**.

---

# 📈 Advanced Data Analysis

Several analytical techniques were applied using SQL.

### Trend Analysis

Analyzed **yearly and monthly sales trends** including:

* Total sales
* Number of customers
* Quantity sold

### Cumulative Analysis

Used **window functions** to calculate:

* Running sales totals
* Moving average pricing trends

### Performance Analysis

Evaluated **product performance over time**, including:

* Average product sales
* Year-over-Year (YoY) sales comparison

### Part-to-Whole Analysis

Measured **category contribution to total revenue**.

### Customer & Product Segmentation

Customers and products were grouped based on behavior:

Customer Segments:

* **VIP** – ≥12 months history & spending > €5000
* **Regular** – ≥12 months history & spending ≤ €5000
* **New** – <12 months history

Products were categorized based on **cost ranges and revenue performance**.

---

# 📊 Analytical Reports

Two reporting views were created:

**Customer Report**

* Total orders
* Total sales
* Customer lifespan
* Recency
* Average Order Value (AOV)
* Average monthly spend

**Product Report**

* Total orders
* Revenue and quantity sold
* Unique customers
* Product lifespan
* Average selling price
* Monthly revenue performance

---

# 🛠 Tools Used

* SQL Server
* T-SQL
* Data Warehousing (Bronze → Silver → Gold)
* Window Functions
* CTEs and Aggregations

---

# 🚀 Key Outcome

This project demonstrates how SQL can be used to perform **EDA, advanced analytics, and KPI reporting** on warehouse data to support **business decision-making**.

---

👨‍💻 **Author:** Ankit Jain

Data Analyst | SQL | Data Warehousing | Analytics
