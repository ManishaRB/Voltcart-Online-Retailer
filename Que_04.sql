/*4. Finance wants the revenue trend with momentum. Produce
monthly completed revenue with a cumulative running total and the month-over-month %
change. Required output: order_month (YYYY-MM), monthly_revenue, running_total,
mom_pct_change.*/
WITH monthly_revenue AS (
    -- Step 1: Collapse all completed orders into one row per month,
    SELECT
        FORMAT(order_date, 'yyyy-MM') AS order_month,
        SUM(order_total) AS monthly_revenue
    FROM fact_orders
    -- Only completed orders count as revenue — same rule as Q3.
    WHERE order_status = 'Completed'
    GROUP BY FORMAT(order_date, 'yyyy-MM')
),

with_trend AS (
    -- Step 2: Add the running total and month-over-month % change,
    SELECT
        order_month,
        monthly_revenue,
        SUM(monthly_revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,
        LAG(monthly_revenue) OVER (
            ORDER BY order_month
        ) AS prev_month_revenue
    FROM monthly_revenue
)

-- Step 3: Turn prev_month_revenue into a % change and present
SELECT
    order_month,
    monthly_revenue,
    running_total,
    CASE
        WHEN prev_month_revenue IS NULL OR prev_month_revenue = 0 THEN NULL
        ELSE ROUND(
            (monthly_revenue - prev_month_revenue) / prev_month_revenue * 100,
            2
        )
    END AS mom_pct_change
FROM with_trend
ORDER BY order_month;