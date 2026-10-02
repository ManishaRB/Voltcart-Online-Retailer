/*1. Voltkart's commercial team wants a quick look at the biggest sales. 
Return the top 20 completed orders by value, with the customer and the sales rep behind each one.
Required output: order_id, order_date, customer_name, sales_rep_name, order_total.*/
SELECT TOP (20)
    o.order_id,
    o.order_date,
    c.customer_name,
    e.employee_name AS sales_rep_name,
    o.order_total
FROM fact_orders AS o
JOIN dim_customer AS c ON c.customer_id = o.customer_id
JOIN dim_employee AS e ON e.employee_id = o.sales_rep_id
WHERE o.order_status = 'Completed'
ORDER BY o.order_total DESC;