/*10. A report is slow. Here is the query analysts are running:
 SELECT o.customer_id, COUNT(*) AS orders_2024,
 (SELECT SUM(oi.line_amount)
 FROM fact_order_items oi
 JOIN fact_orders o2 ON o2.order_id = oi.order_id
 WHERE o2.customer_id = o.customer_id) AS lifetime_value
 FROM fact_orders o
 WHERE YEAR(o.order_date) = 2024
 GROUP BY o.customer_id;
Turn on SET STATISTICS IO, TIME ON and "Include Actual Execution Plan", run it, then make
it fast: explain what the plan is doing, rewrite the query, and add an index that helps. Required
output: the rewritten query, the CREATE INDEX statement(s), and a short note giving the
logical reads before versus after and why the plan changed.*/



SET STATISTICS IO ON;
SET STATISTICS TIME ON;

WITH order_item_totals AS (
    SELECT
        order_id,
        SUM(line_amount) AS order_amount
    FROM fact_order_items
    GROUP BY order_id
),
customer_lifetime AS (
    SELECT
        o.customer_id,
        SUM(oit.order_amount) AS lifetime_value
    FROM fact_orders AS o
    JOIN order_item_totals AS oit ON oit.order_id = o.order_id
    GROUP BY o.customer_id
),
orders_2024 AS (
    SELECT
        customer_id,
        COUNT(*) AS orders_2024
    FROM fact_orders
    WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'   -- SARGable range
    GROUP BY customer_id
)
SELECT
    o.customer_id,
    o.orders_2024,
    cl.lifetime_value
FROM orders_2024 AS o
JOIN customer_lifetime AS cl ON cl.customer_id = o.customer_id;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- SUPPORTING INDEXES
-- Speeds the SARGable date-range scan/seek and covers customer_id + order_id
-- so the orders_2024 / customer_lifetime CTEs can be satisfied from the index
-- without a key lookup.
CREATE INDEX IX_fact_orders_date_customer
    ON fact_orders (order_date)
    INCLUDE (customer_id, order_id, order_total);

-- Speeds the per-order aggregation in order_item_totals — an index on
-- order_id (with line_amount included) lets SQL Server aggregate via an
-- ordered index scan/seek instead of scanning the whole heap/clustered index
-- and lets the join to fact_orders use a merge or nested-loop-with-seek
-- instead of a hash/scan.
CREATE INDEX IX_fact_order_items_order_id
    ON fact_order_items (order_id)
    INCLUDE (line_amount);


-- EXPECTED IMPACT / NOTE FOR THE WRITE-UP:
-- Before: logical reads on fact_orders and fact_order_items scale with
-- (distinct customers) x (table size) because of the correlated subquery
-- re-scanning both tables per customer, plus a full scan for the
-- non-SARGable YEAR() predicate.
-- After: fact_order_items is aggregated exactly once (one ordered
-- scan/seek using IX_fact_order_items_order_id), fact_orders is read once
-- for the date range (index seek/range scan using IX_fact_orders_date_customer)
-- and once for the full lifetime join, and the two aggregates are combined
-- with a single hash/merge join. The plan shape changes from
-- "nested loops re-executing a subquery per group" to
-- "two independent aggregations joined once," which is why logical reads
-- and elapsed time drop sharply — report the actual before/after numbers
-- from your STATISTICS IO output in the write-up, since they depend on your
-- data volume.

