
/*3. Merchandising wants the stars of each category. For every category, return the
top 3 products by completed revenue. Required output: category_name, product_name,
total_revenue, revenue_rank.*/

WITH product_revenue AS (
    -- Step 1: Collapse many order-line rows into ONE row
    SELECT
        c.category_name,
        p.product_name,

        -- SUM() adds up every line_amount for this product across ALL completed orders
        ROUND(SUM(fo.line_amount), 0) AS total_revenue

    FROM fact_order_items AS fo

    -- Bring in order-level info (needed to check order_status)
    JOIN fact_orders AS o
        ON o.order_id = fo.order_id

    -- Bring in product info (needed for product_name, category_id)
    JOIN dim_product AS p
        ON fo.product_id = p.product_id

    -- Bring in category info (needed for the readable category_name)
    JOIN dim_category AS c
        ON p.category_id = c.category_id

    -- Only count revenue from orders that actually completed —
    -- this filter runs BEFORE the SUM/GROUP BY, so cancelled/
    -- returned/pending orders never enter the total.
    WHERE o.order_status = 'Completed'

    -- Group by both category and product so SUM() calculates
    -- one total_revenue per distinct product within its category.
    GROUP BY c.category_name, p.product_name
),
-- Step 2: Rank each product's total_revenue against
revenue_rank AS (
    SELECT
        category_name,
        product_name,
        total_revenue,

        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM product_revenue  
)

-- Step 3: Keep only the top 3 ranked products per category,
SELECT *
FROM revenue_rank
WHERE revenue_rank <= 3
ORDER BY category_name, revenue_rank;