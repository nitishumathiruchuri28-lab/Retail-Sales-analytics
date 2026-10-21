-- 1. Overall KPIs
SELECT COUNT(DISTINCT OrderID) AS orders, COUNT(DISTINCT CustomerID) AS customers,
       SUM(Sales) AS total_sales, SUM(Profit) AS total_profit,
       ROUND(100.0*SUM(Profit)/NULLIF(SUM(Sales),0),2) AS profit_margin_pct,
       SUM(Quantity) AS units_sold
FROM retail_sales;

-- 2. Monthly trend (SQLite)
SELECT strftime('%Y-%m', OrderDate) AS month, ROUND(SUM(Sales),2) AS sales,
       ROUND(SUM(Profit),2) AS profit
FROM retail_sales GROUP BY strftime('%Y-%m', OrderDate) ORDER BY month;

-- 3. Category performance
SELECT Category, ROUND(SUM(Sales),2) AS sales, ROUND(SUM(Profit),2) AS profit,
       ROUND(100.0*SUM(Profit)/NULLIF(SUM(Sales),0),2) AS margin_pct
FROM retail_sales GROUP BY Category ORDER BY sales DESC;

-- 4. Region performance
SELECT Region, ROUND(SUM(Sales),2) AS sales, ROUND(SUM(Profit),2) AS profit
FROM retail_sales GROUP BY Region ORDER BY sales DESC;

-- 5. Top 10 subcategories
SELECT SubCategory, ROUND(SUM(Sales),2) AS sales, ROUND(SUM(Profit),2) AS profit
FROM retail_sales GROUP BY SubCategory ORDER BY sales DESC LIMIT 10;

-- 6. Discount bands and margin
SELECT CASE WHEN Discount=0 THEN 'No discount' WHEN Discount<=0.10 THEN '1-10%'
            WHEN Discount<=0.20 THEN '11-20%' ELSE 'Above 20%' END AS discount_band,
       COUNT(*) AS order_lines, SUM(Sales) AS sales, SUM(Profit) AS profit,
       ROUND(100.0*SUM(Profit)/NULLIF(SUM(Sales),0),2) AS margin_pct
FROM retail_sales GROUP BY discount_band;

-- 7. Top 20 customers with ranking
SELECT CustomerID, COUNT(DISTINCT OrderID) AS orders, ROUND(SUM(Sales),2) AS sales,
       ROUND(SUM(Profit),2) AS profit,
       DENSE_RANK() OVER (ORDER BY SUM(Sales) DESC) AS customer_rank
FROM retail_sales GROUP BY CustomerID ORDER BY sales DESC LIMIT 20;

-- 8. Running monthly sales total
WITH monthly AS (SELECT strftime('%Y-%m', OrderDate) AS month, SUM(Sales) AS sales
                 FROM retail_sales GROUP BY strftime('%Y-%m', OrderDate))
SELECT month, ROUND(sales,2) AS monthly_sales,
       ROUND(SUM(sales) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS running_sales
FROM monthly ORDER BY month;

-- 9. Data quality checks
SELECT 'blank_order_id' AS check_name, COUNT(*) AS issue_count
FROM retail_sales WHERE OrderID IS NULL OR TRIM(OrderID)=''
UNION ALL SELECT 'negative_sales', COUNT(*) FROM retail_sales WHERE Sales<0
UNION ALL SELECT 'negative_quantity', COUNT(*) FROM retail_sales WHERE Quantity<0
UNION ALL SELECT 'invalid_discount', COUNT(*) FROM retail_sales WHERE Discount<0 OR Discount>1;

-- 10. Shipping mode performance
SELECT ShipMode, COUNT(*) AS order_lines, SUM(Sales) AS sales, SUM(Profit) AS profit
FROM retail_sales GROUP BY ShipMode ORDER BY sales DESC;
