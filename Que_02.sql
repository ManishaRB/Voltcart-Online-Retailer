/*2. Marketing wants to re-engage people who registered but never bought. 
List the customers who have never placed an order. 
Required output: customer_id, customer_name, signup_date.*/
SELECT
    c.customer_id,
    c.customer_name,
    c.signup_date
FROM dim_customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_orders AS o
    WHERE o.customer_id = c.customer_id
);
