WITH customer_spend AS (
    -- Step 1: One row per customer, with their total COMPLETED spend.
    -- LEFT JOIN (not INNER) so customers with zero completed orders still appear
    SELECT
        c.customer_id,
        COALESCE(SUM(o.order_total), 0) AS lifetime_spend
    FROM dim_customer AS c
    LEFT JOIN fact_orders AS o
        ON o.customer_id = c.customer_id
        AND o.order_status = 'Completed'
    GROUP BY c.customer_id
),

quartiled_customers AS (
    -- Step 2: Split customers into 4 equal-sized buckets by spend.
    SELECT
        customer_id,
        lifetime_spend,
        NTILE(4) OVER (ORDER BY lifetime_spend DESC) AS spend_quartile
    FROM customer_spend
)

-- Step 3: Summarize each quartile — how many customers, and
-- their average lifetime spend.
SELECT
    spend_quartile,
    COUNT(*) AS customer_count,
    ROUND(AVG(lifetime_spend), 2) AS avg_lifetime_spend
FROM quartiled_customers
GROUP BY spend_quartile
ORDER BY spend_quartile;


