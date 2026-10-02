/*9. The catalogue source now emits a change feed (cdc_product_changes) with
operation codes. Apply it to dim_product in a single MERGE that honours the codes: I inserts
a new product, U updates an existing one, D deletes it. Acceptance criteria: one MERGE
handling all three operations; include a verification query showing inserted, updated, and
deleted products.*/

-- ---------- STEP 0: BEFORE COUNT ----------
SELECT COUNT(*) AS dim_product_count_before
FROM dim_product;

WITH latest_change AS (
    SELECT
        change_id,
        product_id,
        operation,
        change_ts,
        product_name,
        category_id,
        unit_price,
        unit_cost,
        launch_date,
        -- Rank each product_id's changes newest-first; keep only rank 1.
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY change_ts DESC
        ) AS rn
    FROM cdc_product_changes
),

source_changes AS (
    SELECT *
    FROM latest_change
    WHERE rn = 1   -- one row per product_id: its most recent change
)

-- =========================================================
-- THE MERGE — single statement, handles I / U / D
-- =========================================================
MERGE dim_product AS target
USING source_changes AS source
    ON target.product_id = source.product_id

-- Product exists in dim_product AND the CDC feed says 'D' -> delete it.
WHEN MATCHED AND source.operation = 'D' THEN
    DELETE

-- Product exists in dim_product AND the CDC feed says 'U' -> refresh
-- its attributes with the latest values from the feed.
WHEN MATCHED AND source.operation = 'U' THEN
    UPDATE SET
        target.product_name = source.product_name,
        target.category_id  = source.category_id,
        target.unit_price   = source.unit_price,
        target.unit_cost    = source.unit_cost,
        target.launch_date  = source.launch_date

-- Product does NOT exist in dim_product yet AND the CDC feed says
-- 'I' -> insert it as a brand-new product.
WHEN NOT MATCHED BY TARGET AND source.operation = 'I' THEN
    INSERT (product_id, product_name, category_id, unit_price, unit_cost, launch_date)
    VALUES (source.product_id, source.product_name, source.category_id,
            source.unit_price, source.unit_cost, source.launch_date);

-- ---------- STEP 1: AFTER COUNT ----------
SELECT COUNT(*) AS dim_product_count_after
FROM dim_product;
