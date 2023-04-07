/* REQUEST 1
Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. */

SELECT 
    distinct market
FROM
    gdb023.dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

/* REQUEST 2 
What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

WITH 
  year2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2020 
    FROM gdb023.fact_sales_monthly 
    WHERE fiscal_year = 2020
  ),
  year2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2021 
    FROM gdb023.fact_sales_monthly 
    WHERE fiscal_year = 2021
  )
SELECT 
  year2020.unique_product_2020 AS unique_product_2020,
  year2021.unique_product_2021 AS unique_product_2021,
  ROUND(((year2021.unique_product_2021 - year2020.unique_product_2020) / year2020.unique_product_2020) * 100, 2) AS percentage_difference
FROM year2020, year2021;



/* REQUEST 3
Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains 2 fields,
segment
product_count */

SELECT 
    segment, COUNT(product_code) AS product_count
FROM
    gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* REQUEST 4
Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH
  year2020 AS (
	SELECT p.segment,count(DISTINCT p.product_code) AS unique_product_2020
	FROM gdb023.dim_product p JOIN gdb023.fact_sales_monthly f 
	ON p.product_code = f.product_code 
	WHERE f.fiscal_year = 2020 
	GROUP BY segment
  ),
  year2021 AS (
	SELECT p.segment,count(DISTINCT p.product_code) AS unique_product_2021
	FROM gdb023.dim_product p JOIN gdb023.fact_sales_monthly f 
	ON p.product_code = f.product_code 
	WHERE f.fiscal_year = 2021
	GROUP BY segment
  )
SELECT 
  year2020.SEGMENT,
  year2020.unique_product_2020 AS unique_product_2020,
  year2021.unique_product_2021 AS unique_product_2021,
  (year2021.unique_product_2021 - year2020.unique_product_2020) AS difference
FROM year2020 JOIN year2021 ON year2020.SEGMENT = year2021.SEGMENT
ORDER BY difference DESC;


/* REQUEST 5
get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

SELECT p.product_code,p.product, m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
ON m.product_code = p.product_code
WHERE manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost) 
OR manufacturing_cost = (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost);

/* REQUEST 6
Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

WITH discounts AS (
  SELECT 
    c.customer_code, 
    c.customer, 
    AVG(p.pre_invoice_discount_pct) AS average_discount_percentage,
    RANK() OVER (ORDER BY AVG(p.pre_invoice_discount_pct) DESC) AS discount_rank
  FROM 
    dim_customer c 
    JOIN fact_pre_invoice_deductions p ON c.customer_code = p.customer_code 
  WHERE 
    p.fiscal_year = 2021 AND c.market = 'India'
  GROUP BY 
    c.customer,c.customer_code 
)
SELECT 
  customer, 
  ROUND(average_discount_percentage*100, 2) AS average_discount_percentage
FROM 
  discounts
WHERE 
  discount_rank <= 5
ORDER BY average_discount_percentage DESC;

/* REQUEST 7 
Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

SELECT 
    MONTHNAME(s.date) AS `month`,
    YEAR(s.date) AS `year`,
    round((SUM((p.gross_price) * (s.sold_quantity)))/1000000,2) AS Gross_Sales
FROM
    gdb023.fact_sales_monthly s
        JOIN
    gdb023.fact_gross_price p ON p.product_code = s.product_code
        JOIN
    gdb023.dim_customer c ON c.customer_code = s.customer_code
WHERE
    customer = 'Atliq Exclusive'
GROUP BY `year`,`month` ;


/* REQUEST 8
In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */


SELECT 
    CASE
        WHEN MONTH(date) IN (9 , 10, 11) THEN 'Q1'
        WHEN MONTH(date) IN (12 , 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3 , 4, 5) THEN 'Q3'
        WHEN MONTH(date) IN (6 , 7, 8) THEN 'Q4'
    END AS Quater2020,
    ROUND(SUM(sold_quantity) / 1000000, 2) AS Qua_in_millions
FROM
    gdb023.fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY Quater2020
ORDER BY Qua_in_millions DESC;

/* REQUEST 9
Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

WITH cte as (
SELECT 
    channel,
    round((SUM((p.gross_price) * (s.sold_quantity)))/1000000,2) AS gross_sales_mn
FROM
    gdb023.fact_sales_monthly s
        JOIN
    gdb023.fact_gross_price p ON p.product_code = s.product_code
        JOIN
    gdb023.dim_customer c ON c.customer_code = s.customer_code
WHERE
     s.fiscal_year = 2021
GROUP BY channel)
select *, round((gross_sales_mn*100)/sum(gross_sales_mn) over(),2) as Percentage from cte
ORder by gross_sales_mn DESC;

/* REQUEST 10
Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order */

WITH cte1 as (
SELECT p.division,p.product_code,p.product, round((sum(s.sold_quantity)/1000),2) as sold_quantity FROM gdb023.dim_product p
JOIN gdb023.fact_sales_monthly s 
ON s.product_code = p.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.division,p.product, p.product_code),
cte2 as
(SELECT *, rank() over(PARTITION BY division ORDER BY sold_quantity DESC) as rank_order FROM cte1)
SELECT * FROM cte2 WHERE rank_order < 4; 

/* THANK YOU */














