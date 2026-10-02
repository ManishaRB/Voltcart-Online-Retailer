/*8. The platform team is moving off nightly full reloads. You've been handed today's
batch in stg_orders_incr. Write a single MERGE that performs an incremental load into
fact_orders: update orders that changed, insert ones that are new. Acceptance criteria: one
MERGE statement; matched orders are updated (status and total) and new orders inserted;
include a verification query showing the fact_orders row count before versus after and a
sample of updated rows.*/

-- ---------- STEP 0: BEFORE COUNT ----------
SELECT COUNT(*) AS fact_orders_count_before
FROM fact_orders;

-- =========================================================
-- THE MERGE — single statement, handles update + insert
-- =========================================================
MERGE fact_orders AS target
USING stg_orders_incr AS source
    ON target.order_id = source.order_id

WHEN MATCHED THEN
    UPDATE SET
        target.order_status = source.order_status,
        target.order_total  = source.order_total

WHEN NOT MATCHED BY TARGET THEN
    INSERT (order_id, order_date, customer_id, sales_rep_id, order_status, order_total)
    VALUES (source.order_id, source.order_date, source.customer_id,
            source.sales_rep_id, source.order_status, source.order_total);


-- ---------- STEP 1: AFTER COUNT ----------
SELECT COUNT(*) AS fact_orders_count_after
FROM fact_orders;


