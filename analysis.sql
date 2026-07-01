-- ============================================================
--  SALES & REVENUE ANALYSIS — MySQL Project
--  Dataset : 1000 orders | FY2022–FY2023 | Indian Retail Co.
-- ============================================================

-- ── STEP 1 : Create database & table ──────────────────────────
CREATE DATABASE IF NOT EXISTS sales_analysis;
USE sales_analysis;

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    order_id       VARCHAR(10)    PRIMARY KEY,
    order_date     DATE           NOT NULL,
    customer_id    VARCHAR(10),
    customer_name  VARCHAR(100),
    city           VARCHAR(50),
    segment        VARCHAR(20),   -- Retail / Corporate / SME
    region         VARCHAR(20),   -- North / South / East / West
    category       VARCHAR(50),
    product_name   VARCHAR(100),
    quantity       INT,
    unit_price     DECIMAL(10,2),
    unit_cost      DECIMAL(10,2),
    discount       DECIMAL(4,2),
    revenue        DECIMAL(12,2),
    profit         DECIMAL(12,2)
);

-- ── STEP 2 : Load CSV ─────────────────────────────────────────
-- Update the path below to match where you saved sales_data.csv
LOAD DATA LOCAL INFILE 'C:/Users/YourName/sales_project/sales_data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_date, customer_id, customer_name, city, segment,
 region, category, product_name, quantity, unit_price, unit_cost,
 discount, revenue, profit);

-- Verify load
SELECT COUNT(*) AS total_orders FROM sales;

-- ============================================================
--  ANALYSIS QUERIES
-- ============================================================


-- ── Q1 : Overall Business Summary ─────────────────────────────
-- Quick snapshot of the entire dataset
SELECT
    COUNT(*)                          AS total_orders,
    COUNT(DISTINCT customer_id)       AS unique_customers,
    ROUND(SUM(revenue),  2)           AS total_revenue,
    ROUND(SUM(profit),   2)           AS total_profit,
    ROUND(AVG(revenue),  2)           AS avg_order_value,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS overall_profit_margin_pct
FROM sales;


-- ── Q2 : Monthly Revenue & Profit Trend ───────────────────────
-- Shows how the business performed month by month
SELECT
    DATE_FORMAT(order_date, '%Y-%m')   AS month,
    COUNT(*)                           AS orders,
    ROUND(SUM(revenue), 2)             AS monthly_revenue,
    ROUND(SUM(profit),  2)             AS monthly_profit,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct
FROM sales
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


-- ── Q3 : Year-over-Year (YoY) Revenue Growth ──────────────────
-- Compares 2022 vs 2023 performance
SELECT
    YEAR(order_date)       AS year,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit),  2) AS total_profit,
    COUNT(*)               AS total_orders
FROM sales
GROUP BY YEAR(order_date)
ORDER BY year;


-- ── Q4 : Revenue & Profit by Region ───────────────────────────
-- Identifies which geography drives the most business
SELECT
    region,
    COUNT(*)                               AS orders,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(SUM(profit),  2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct,
    ROUND(SUM(revenue)*100.0/
          (SELECT SUM(revenue) FROM sales), 2) AS revenue_share_pct
FROM sales
GROUP BY region
ORDER BY total_revenue DESC;


-- ── Q5 : Category-wise Performance ────────────────────────────
-- Which product category is most profitable?
SELECT
    category,
    COUNT(*)                               AS orders,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(SUM(profit),  2)                 AS total_profit,
    ROUND(AVG(discount)*100, 2)            AS avg_discount_pct,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct
FROM sales
GROUP BY category
ORDER BY total_profit DESC;


-- ── Q6 : Top 10 Products by Revenue ───────────────────────────
SELECT
    product_name,
    category,
    SUM(quantity)                          AS units_sold,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(SUM(profit),  2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS margin_pct
FROM sales
GROUP BY product_name, category
ORDER BY total_revenue DESC
LIMIT 10;


-- ── Q7 : Customer Segment Analysis ────────────────────────────
-- Retail vs Corporate vs SME — which segment is most valuable?
SELECT
    segment,
    COUNT(DISTINCT customer_id)            AS unique_customers,
    COUNT(*)                               AS total_orders,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(AVG(revenue), 2)                 AS avg_order_value,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct
FROM sales
GROUP BY segment
ORDER BY total_revenue DESC;


-- ── Q8 : Top 10 Customers by Revenue ──────────────────────────
SELECT
    customer_id,
    customer_name,
    city,
    segment,
    COUNT(*)               AS total_orders,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit),  2) AS total_profit
FROM sales
GROUP BY customer_id, customer_name, city, segment
ORDER BY total_revenue DESC
LIMIT 10;


-- ── Q9 : Discount Impact Analysis ─────────────────────────────
-- Does giving discounts actually hurt or help profitability?
SELECT
    CASE
        WHEN discount = 0          THEN 'No Discount'
        WHEN discount <= 0.05      THEN '1–5%'
        WHEN discount <= 0.10      THEN '6–10%'
        ELSE 'Above 10%'
    END                                    AS discount_bucket,
    COUNT(*)                               AS orders,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(SUM(profit),  2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct
FROM sales
GROUP BY discount_bucket
ORDER BY FIELD(discount_bucket,'No Discount','1–5%','6–10%','Above 10%');


-- ── Q10 : Running Total Revenue (Window Function) ─────────────
-- Cumulative revenue month by month — shows growth trajectory
SELECT
    month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month), 2) AS cumulative_revenue
FROM (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        ROUND(SUM(revenue), 2)           AS monthly_revenue
    FROM sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) AS monthly
ORDER BY month;


-- ── Q11 : Quarter-wise Revenue Breakdown ──────────────────────
SELECT
    YEAR(order_date)                       AS year,
    QUARTER(order_date)                    AS quarter,
    ROUND(SUM(revenue), 2)                 AS quarterly_revenue,
    ROUND(SUM(profit),  2)                 AS quarterly_profit,
    COUNT(*)                               AS total_orders
FROM sales
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY year, quarter;


-- ── Q12 : Low Margin Products (Needs Attention) ───────────────
-- Products where margin is below 20% — flag for pricing review
SELECT
    product_name,
    category,
    ROUND(SUM(revenue), 2)                 AS total_revenue,
    ROUND(SUM(profit)/SUM(revenue)*100, 2) AS profit_margin_pct
FROM sales
GROUP BY product_name, category
HAVING profit_margin_pct < 20
ORDER BY profit_margin_pct ASC;
