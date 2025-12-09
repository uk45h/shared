USE DATABASE banking_project;
use schema banking_demo;
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE VIEW V_MONTHLY_SEGMENT_TOTALS AS
SELECT 
    DATE_TRUNC('month', t.transaction_date) AS month_year,
    c.segment,
    ROUND(SUM(t.amount), 2) AS total_amount,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT t.customer_id) AS unique_customers,
    ROUND(AVG(t.amount), 2) AS avg_transaction_amount,
    ROUND(SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END), 2) AS total_income,
    ROUND(SUM(CASE WHEN t.amount < 0 THEN t.amount ELSE 0 END), 2) AS total_expenses
FROM TRANSACTIONS t
JOIN CUSTOMERS c ON t.customer_id = c.customer_id
GROUP BY DATE_TRUNC('month', t.transaction_date), c.segment
ORDER BY month_year, segment;

-- Sprawdź widok
SELECT * FROM V_MONTHLY_SEGMENT_TOTALS ORDER BY month_year DESC LIMIT 20;

-- Widok w formacie odpowiednim dla Snowflake AutoML (Time Series Forecasting)
CREATE OR REPLACE VIEW V_FORECASTING_DATA AS
SELECT 
    month_year AS ds,           -- Data (wymagane przez AutoML)
    segment,                     -- Parametr grupujący
    total_amount AS y           -- Wartość do prognozowania
FROM V_MONTHLY_SEGMENT_TOTALS
WHERE month_year < DATE_TRUNC('month', CURRENT_DATE()) and SEGMENT='Private' -- Tylko pełne miesiące and 
ORDER BY segment, ds;

-- Sprawdź dane do prognozowania
SELECT * FROM V_FORECASTING_DATA ORDER BY segment, ds;

-- Statystyki dla każdego segmentu
SELECT 
    segment,
    COUNT(*) AS months_count,
    MIN(ds) AS first_month,
    MAX(ds) AS last_month,
    ROUND(AVG(y), 2) AS avg_monthly_amount,
    ROUND(STDDEV(y), 2) AS stddev_amount
FROM V_FORECASTING_DATA
GROUP BY segment;

-- =============================================
-- KROK 5: SNOWFLAKE AutoML - PROGNOZOWANIE
-- (do uruchomienia w Snowflake z odpowiednimi uprawnieniami)
-- =============================================

/*
CEL PROGNOZOWANIA:
- Parametr 1 (y): Łączna kwota transakcji miesięcznych (total_amount)
- Parametr 2: Segment klienta (Private, Corporate, Premium)

KROKI DO WYKONANIA W SNOWFLAKE:

1. Utworzenie modelu prognozowania dla każdego segmentu:
*/
CREATE WAREHOUSE automl WITH WAREHOUSE_SIZE = 'SMALL' AUTO_SUSPEND = 300 AUTO_RESUME = TRUE;
USE warehouse automl;
-- Utwórz model prognozowania (wymaga Snowflake ML Functions)
-- Dla segmentu Private
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST model_forecast_private(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'V_FORECASTING_DATA'),
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y'
);


-- Generowanie prognozy na 6 miesięcy do przodu
CALL model_forecast_private!FORECAST(
    FORECASTING_PERIODS => 6,
    CONFIG_OBJECT => {'prediction_interval': 0.95}
);