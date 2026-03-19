use bhadb;
select * from city;
select * from customers;
select * from products;
select * from sales;

-- Report & Data analysis
-- Q1 : Coffee Consumers Count
-- how many people in each city are estimeted to consume coffee, given that 25% of the population does?

select city_name, ROUND((population * 0.25)/1000000,2) as coffee_conusmer_in_millions, city_rank from city order by 2 desc;

-- Q2 Total Revenue from Coffee sales
-- What is the total revenue generated from coffee sales across all cities in the last quater at 2023?
select 
	ci.city_name, 
sum(TOTAL) as revenue from  sales as s
join customers as c
	on s.customer_id = c. customer_id
join city as ci
on ci.city_id =  c.city_id
    where EXTRACT(YEAR FROM s.sale_date) = 2023 AND
    extract(quarter from s.sale_date) = 4
group by  ci.city_name  
order by 2 desc; 

-- Q3. Sales count for each product
-- How many Units of each coffee product have been sold?
select p.product_name,
count(s.sale_id) as total_orders from products as p
LEFT JOIN
sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc;

-- Q4.  Average sales amount per city
-- what is the average sales amount per customer in each day?

select 
	ci.city_name, 
sum(TOTAL) as total_revenue,
count(distinct s.customer_id) as total_cx,
round(sum(TOTAL)/count(distinct s.customer_id),2) as avg_sale_per_cx
from  sales as s
join customers as c
	on s.customer_id = c. customer_id
join city as ci
on ci.city_id =  c.city_id
group by  ci.city_name  
order by 2 desc; 

-- Q5. City population and coffeee consumers
-- provide a list of cities along with their populations and estimedted coffee consumers. Return city_name, total current cx, estimated coffee consumers(25%)

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions
    FROM city
),
customers_table AS (
    SELECT
        ci.city_name, 
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id 
    GROUP BY ci.city_name
)
SELECT 
    ct.city_name,
    ct.coffee_consumers_in_millions,
    cit.unique_cx
FROM city_table AS ct
JOIN customers_table AS cit
    ON cit.city_name = ct.city_name;

-- q6 top selling products by city
-- What are the top 3 selling products in each city based on sales volume?

WITH base AS (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
)
SELECT 
    city_name,
    product_name,
    total_orders,
    DENSE_RANK() OVER (
        PARTITION BY city_name 
        ORDER BY total_orders DESC
    ) AS rnk
FROM base;

-- Q7. Customer segmentation by city
-- How many unique customers are there in each city who have purchased coffee products?
select * from products;
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1 ;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions
WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY avg_sale_pr_cx DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, YEAR(s.sale_date), MONTH(s.sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale) OVER (
            PARTITION BY city_name 
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / NULLIF(last_month_sale, 0) * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / NULLIF(COUNT(DISTINCT s.customer_id), 0),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name
),
city_rent AS (
    SELECT 
        city_id,
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / NULLIF(ct.total_cx, 0),
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_id = ct.city_id
ORDER BY ct.total_revenue DESC;


