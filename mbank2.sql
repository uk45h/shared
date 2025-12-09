-- Włącz cache
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- ZAPYTANIE B - ZOPTYMALIZOWANE
WITH 
-- Wstępna filtracja danych (ograniczamy dane na starcie)
filtered_transactions AS (
    SELECT 
        t.transaction_id,
        t.customer_id,
        t.transaction_date,
        t.amount,
        t.category,
        t.location_city,
        DATE_TRUNC('month', t.transaction_date) AS month_year
    FROM TRANSACTIONS t
    WHERE t.transaction_date >= DATEADD(month, -6, CURRENT_DATE())
),

-- Pre-agregacja: średnia dla każdego klienta (zamiast skorelowanego podzapytania 1)
customer_stats AS (
    SELECT 
        customer_id,
        ROUND(AVG(amount), 2) AS customer_avg,
        SUM(amount) AS customer_total
    FROM TRANSACTIONS
    GROUP BY customer_id
),

-- Pre-agregacja: liczba transakcji w mieście/miesiącu (zamiast skorelowanego podzapytania 2)
city_monthly_stats AS (
    SELECT 
        location_city,
        month_year,
        COUNT(*) AS city_monthly_count
    FROM filtered_transactions
    GROUP BY location_city, month_year
),

-- Pre-agregacja: ranking kwot w segmencie (zamiast skorelowanego podzapytania 3)
segment_amount_ranks AS (
    SELECT 
        c.segment,
        t.amount,
        COUNT(*) OVER (PARTITION BY c.segment ORDER BY t.amount DESC) AS segment_rank_by_amount
    FROM TRANSACTIONS t
    JOIN CUSTOMERS c ON t.customer_id = c.customer_id
    QUALIFY ROW_NUMBER() OVER (PARTITION BY c.segment, t.amount ORDER BY t.transaction_id) = 1
),

-- Główne zapytanie z joinami zamiast podzapytań
main_query AS (
    SELECT 
        c.segment,
        c.customer_id,
        c.name,
        ft.transaction_id,
        ft.transaction_date,
        ft.amount,
        ft.category,
        ft.location_city,
        
        -- Z pre-agregacji (zamiast skorelowanych podzapytań)
        cs.customer_avg AS customer_running_avg,
        cms.city_monthly_count,
        COALESCE(sar.segment_rank_by_amount, 0) AS segment_rank_by_amount,
        
        -- Funkcje okna (zoptymalizowane partycje)
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY ft.transaction_date DESC, ft.amount DESC) AS customer_row_num
        
    FROM filtered_transactions ft
    JOIN CUSTOMERS c ON ft.customer_id = c.customer_id
    JOIN customer_stats cs ON ft.customer_id = cs.customer_id
    JOIN city_monthly_stats cms ON ft.location_city = cms.location_city AND ft.month_year = cms.month_year
    LEFT JOIN segment_amount_ranks sar ON c.segment = sar.segment AND ft.amount = sar.amount
)

SELECT 
    segment,
    customer_id,
    name,
    transaction_id,
    transaction_date,
    amount,
    category,
    location_city,
    customer_running_avg,
    city_monthly_count,
    segment_rank_by_amount,
    customer_row_num
FROM main_query
WHERE customer_row_num <= 5
ORDER BY segment, customer_running_avg DESC, city_monthly_count DESC, segment_rank_by_amount
LIMIT 10000;