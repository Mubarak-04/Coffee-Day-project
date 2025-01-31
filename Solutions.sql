-- Coffee Day -- Data Analysis & Reports
USE coffee_day;

-- Preview tables
SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;


-- Q1: Coffee Consumers Count
# How many people in each city are estimated to consume coffee, assuming 
# that 25% of the population drinks coffee?
SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY 2 DESC;

-- Q2: Total Revenue from Coffee Sales
# How does the revenue vary by city?

SELECT 
    SUM(total) AS total_revenue
FROM sales
WHERE 
    YEAR(sale_date) = 2023 AND QUARTER(sale_date) = 4;

-- Revenue by city
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
WHERE 
    YEAR(s.sale_date) = 2023 AND QUARTER(s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q3: Sales Count for Each Product
#  How many units of each coffee product have been sold?

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products AS p
LEFT JOIN sales AS s ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q4: Average Sales Amount per City
# What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q5: City Population and Coffee Consumers (25%)

# Provide a list of cities along with their populations and estimated 
# coffee consumers. Also, include the total number of unique customers 
# per city.

WITH city_data AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
    FROM city
),
customer_data AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY 1
)
SELECT 
    customer_data.city_name,
    city_data.coffee_consumers AS coffee_consumers_in_millions,
    customer_data.unique_customers
FROM city_data
JOIN customer_data ON city_data.city_name = customer_data.city_name;


-- Q6: Customer Segmentation by City
# How many unique customers are there in each city who have 
# purchased coffee products?

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city AS ci
LEFT JOIN customers AS c ON c.city_id = ci.city_id
JOIN sales AS s ON s.customer_id = c.customer_id
WHERE s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- Q7: Monthly Sales Growth
# Calculate the percentage growth (or decline) in sales across different 
# cities on a monthly basis.

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(sale_date) AS month,
        YEAR(sale_date) AS year,
        SUM(s.total) AS total_sales
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY 1, 2, 3
),
growth_data AS (
    SELECT
        city_name,
        month,
        year,
        total_sales AS current_month_sales,
        LAG(total_sales) OVER (PARTITION BY city_name ORDER BY year, month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    current_month_sales,
    previous_month_sales,
    ROUND((current_month_sales - previous_month_sales) / previous_month_sales * 100, 2) AS growth_rate
FROM growth_data
WHERE previous_month_sales IS NOT NULL;

-- Q8: Market Potential Analysis0
# Identify the top 3 cities based on the highest total sales. 
# Provide insights into total revenue, total rent, number of customers, 
# and estimated coffee consumers for each city.

WITH city_sales AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY 1
),
city_data AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumers
    FROM city
)
SELECT 
    cd.city_name,
    cs.total_revenue,
    cd.estimated_rent AS total_rent,
    cs.total_customers,
    cd.estimated_coffee_consumers,
    cs.avg_sale_per_customer,
    ROUND(cd.estimated_rent / cs.total_customers, 2) AS avg_rent_per_customer
FROM city_data AS cd
JOIN city_sales AS cs ON cd.city_name = cs.city_name
ORDER BY 2 DESC;

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.