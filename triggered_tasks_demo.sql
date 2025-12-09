-- ============================================================================
-- SNOWFLAKE TRIGGERED TASKS DEMO
-- ============================================================================
-- Triggered tasks execute automatically when a stream detects new data
-- instead of running on a fixed schedule. This enables event-driven processing.
-- ============================================================================

-- Setup: Create a demo database and schema (optional - adjust to your environment)
CREATE DATABASE IF NOT EXISTS triggered_tasks_demo;
USE DATABASE triggered_tasks_demo;
CREATE SCHEMA IF NOT EXISTS demo;
USE SCHEMA demo;

-- ============================================================================
-- STEP 1: Create source table for incoming data
-- ============================================================================
CREATE OR REPLACE TABLE orders_raw (
    order_id        INT AUTOINCREMENT,
    customer_id     INT,
    product_name    VARCHAR(100),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    order_date      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    status          VARCHAR(20) DEFAULT 'NEW'
);

-- ============================================================================
-- STEP 2: Create target table for processed data
-- ============================================================================
CREATE OR REPLACE TABLE orders_processed (
    order_id        INT,
    customer_id     INT,
    product_name    VARCHAR(100),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    total_amount    DECIMAL(12,2),
    order_date      TIMESTAMP_NTZ,
    processed_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    status          VARCHAR(20)
);

-- ============================================================================
-- STEP 3: Create a stream on the source table
-- ============================================================================
-- The stream captures changes (inserts, updates, deletes) to the source table
CREATE OR REPLACE STREAM orders_stream ON TABLE orders_raw
    APPEND_ONLY = FALSE;  -- Set TRUE if you only care about inserts

-- ============================================================================
-- STEP 4: Create the triggered task
-- ============================================================================
-- Key difference from scheduled tasks:
-- - Uses WHEN clause with SYSTEM$STREAM_HAS_DATA() function
-- - Still needs a SCHEDULE but it only checks stream status at those intervals
-- - Task runs only when stream has data AND schedule interval is reached

CREATE OR REPLACE TASK process_orders_task
    WAREHOUSE = COMPUTE_WH              -- Adjust to your warehouse name
    -- SCHEDULE = '1 MINUTE'               -- Check every minute if stream has data
    WHEN SYSTEM$STREAM_HAS_DATA('orders_stream')  -- Only run if stream has data
AS
    INSERT INTO orders_processed (
        order_id,
        customer_id,
        product_name,
        quantity,
        unit_price,
        total_amount,
        order_date,
        status
    )
    SELECT 
        order_id,
        customer_id,
        product_name,
        quantity,
        unit_price,
        quantity * unit_price AS total_amount,
        order_date,
        'PROCESSED'
    FROM orders_stream
    WHERE METADATA$ACTION = 'INSERT';  -- Only process inserts

-- ============================================================================
-- STEP 5: Resume the task (tasks are created in suspended state)
-- ============================================================================
ALTER TASK process_orders_task RESUME;

-- ============================================================================
-- STEP 6: Test the triggered task by inserting data
-- ============================================================================
-- Insert some test orders
INSERT INTO orders_raw (customer_id, product_name, quantity, unit_price)
VALUES 
    (101, 'Laptop', 2, 999.99),
    (102, 'Mouse', 5, 29.99),
    (103, 'Keyboard', 3, 79.99),
    (101, 'Monitor', 1, 349.99);

-- ============================================================================
-- MONITORING AND VERIFICATION QUERIES
-- ============================================================================

-- Check if stream has data
SELECT SYSTEM$STREAM_HAS_DATA('orders_stream') AS has_data;

-- View stream contents (before task consumes it)
SELECT * FROM orders_stream;
select * from orders_processed;

-- View task status
SHOW TASKS LIKE 'process_orders_task';

-- Check task execution history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'PROCESS_ORDERS_TASK',
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC;

-- View processed orders (after task runs)
SELECT * FROM orders_processed;

-- View raw orders
SELECT * FROM orders_raw;
