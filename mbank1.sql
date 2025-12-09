-- =============================================
-- SNOWFLAKE BANKING PROJECT
-- Syntetyczne dane transakcji bankowych
-- =============================================

-- =============================================
-- KROK 1: TWORZENIE BAZY DANYCH I STRUKTURY TABEL
-- =============================================

-- Utwórz bazę danych
CREATE DATABASE IF NOT EXISTS BANKING_PROJECT;
USE DATABASE BANKING_PROJECT;

-- Utwórz schemat
CREATE SCHEMA IF NOT EXISTS BANKING_DEMO;
USE SCHEMA BANKING_DEMO;

-- Tabela CUSTOMERS (Klienci)
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    address VARCHAR(255),
    join_date DATE,
    segment VARCHAR(20)
);

-- Tabela TRANSACTIONS (Transakcje)
CREATE OR REPLACE TABLE TRANSACTIONS (
    transaction_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    transaction_date DATE,
    amount DECIMAL(15,2),
    category VARCHAR(50),
    location_city VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
);

-- Sprawdź czy tabele zostały utworzone
SHOW TABLES;

-- 2A: Generowanie 5000 klientów
INSERT INTO CUSTOMERS (customer_id, name, address, join_date, segment)
SELECT 
    SEQ4() + 1 AS customer_id,
    -- Generowanie imion i nazwisk
    CONCAT(
        CASE MOD(SEQ4(), 20)
            WHEN 0 THEN 'Jan'
            WHEN 1 THEN 'Anna'
            WHEN 2 THEN 'Piotr'
            WHEN 3 THEN 'Maria'
            WHEN 4 THEN 'Krzysztof'
            WHEN 5 THEN 'Agnieszka'
            WHEN 6 THEN 'Andrzej'
            WHEN 7 THEN 'Barbara'
            WHEN 8 THEN 'Tomasz'
            WHEN 9 THEN 'Ewa'
            WHEN 10 THEN 'Marcin'
            WHEN 11 THEN 'Katarzyna'
            WHEN 12 THEN 'Paweł'
            WHEN 13 THEN 'Małgorzata'
            WHEN 14 THEN 'Michał'
            WHEN 15 THEN 'Joanna'
            WHEN 16 THEN 'Jakub'
            WHEN 17 THEN 'Monika'
            WHEN 18 THEN 'Łukasz'
            ELSE 'Aleksandra'
        END,
        ' ',
        CASE MOD(FLOOR(SEQ4() / 20), 25)
            WHEN 0 THEN 'Nowak'
            WHEN 1 THEN 'Kowalski'
            WHEN 2 THEN 'Wiśniewski'
            WHEN 3 THEN 'Wójcik'
            WHEN 4 THEN 'Kowalczyk'
            WHEN 5 THEN 'Kamiński'
            WHEN 6 THEN 'Lewandowski'
            WHEN 7 THEN 'Zieliński'
            WHEN 8 THEN 'Szymański'
            WHEN 9 THEN 'Woźniak'
            WHEN 10 THEN 'Dąbrowski'
            WHEN 11 THEN 'Kozłowski'
            WHEN 12 THEN 'Jankowski'
            WHEN 13 THEN 'Mazur'
            WHEN 14 THEN 'Kwiatkowski'
            WHEN 15 THEN 'Krawczyk'
            WHEN 16 THEN 'Piotrowski'
            WHEN 17 THEN 'Grabowski'
            WHEN 18 THEN 'Nowakowski'
            WHEN 19 THEN 'Pawłowski'
            WHEN 20 THEN 'Michalski'
            WHEN 21 THEN 'Adamczyk'
            WHEN 22 THEN 'Dudek'
            WHEN 23 THEN 'Zając'
            ELSE 'Król'
        END
    ) AS name,
    -- Generowanie adresów
    CONCAT(
        'ul. ',
        CASE MOD(SEQ4(), 15)
            WHEN 0 THEN 'Główna'
            WHEN 1 THEN 'Polna'
            WHEN 2 THEN 'Leśna'
            WHEN 3 THEN 'Słoneczna'
            WHEN 4 THEN 'Krótka'
            WHEN 5 THEN 'Szkolna'
            WHEN 6 THEN 'Ogrodowa'
            WHEN 7 THEN 'Lipowa'
            WHEN 8 THEN 'Brzozowa'
            WHEN 9 THEN 'Łąkowa'
            WHEN 10 THEN 'Kwiatowa'
            WHEN 11 THEN 'Zielona'
            WHEN 12 THEN 'Nowa'
            WHEN 13 THEN 'Sportowa'
            ELSE 'Parkowa'
        END,
        ' ',
        TO_VARCHAR(MOD(SEQ4(), 150) + 1),
        ', ',
        CASE MOD(FLOOR(SEQ4() / 15), 10)
            WHEN 0 THEN 'Warszawa'
            WHEN 1 THEN 'Kraków'
            WHEN 2 THEN 'Wrocław'
            WHEN 3 THEN 'Poznań'
            WHEN 4 THEN 'Gdańsk'
            WHEN 5 THEN 'Łódź'
            WHEN 6 THEN 'Szczecin'
            WHEN 7 THEN 'Katowice'
            WHEN 8 THEN 'Lublin'
            ELSE 'Białystok'
        END
    ) AS address,
    -- Data dołączenia: losowa z ostatnich 5 lat
    DATEADD(
        day, 
        -FLOOR(UNIFORM(0::FLOAT, 1825::FLOAT, RANDOM())), 
        CURRENT_DATE()
    ) AS join_date,
    -- Segment klienta
    CASE MOD(SEQ4(), 10)
        WHEN 0 THEN 'Premium'
        WHEN 1 THEN 'Premium'
        WHEN 2 THEN 'Corporate'
        WHEN 3 THEN 'Corporate'
        WHEN 4 THEN 'Corporate'
        ELSE 'Private'
    END AS segment
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Sprawdź liczbę klientów
SELECT COUNT(*) AS customer_count FROM CUSTOMERS;
SELECT * FROM CUSTOMERS LIMIT 10;


-- Generowanie 20 000 000 transakcji
INSERT INTO TRANSACTIONS (transaction_id, customer_id, transaction_date, amount, category, location_city)
SELECT 
    ROW_NUMBER() OVER (ORDER BY RANDOM()) AS transaction_id,
    FLOOR(UNIFORM(1::FLOAT, 5001::FLOAT, RANDOM()))::INTEGER AS customer_id,
    DATEADD(
        day, 
        -FLOOR(UNIFORM(0::FLOAT, 1095::FLOAT, RANDOM())), 
        CURRENT_DATE()
    ) AS transaction_date,
    ROUND(
        CASE 
            WHEN MOD(SEQ4(), 20) = 0 THEN UNIFORM(3000::FLOAT, 15000::FLOAT, RANDOM())
            WHEN MOD(SEQ4(), 20) BETWEEN 1 AND 3 THEN 
                CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.5 
                     THEN UNIFORM(100::FLOAT, 5000::FLOAT, RANDOM())
                     ELSE -UNIFORM(100::FLOAT, 5000::FLOAT, RANDOM())
                END
            WHEN MOD(SEQ4(), 20) BETWEEN 4 AND 8 THEN -UNIFORM(20::FLOAT, 500::FLOAT, RANDOM())
            WHEN MOD(SEQ4(), 20) BETWEEN 9 AND 13 THEN -UNIFORM(50::FLOAT, 2000::FLOAT, RANDOM())
            WHEN MOD(SEQ4(), 20) BETWEEN 14 AND 16 THEN -UNIFORM(100::FLOAT, 800::FLOAT, RANDOM())
            WHEN MOD(SEQ4(), 20) BETWEEN 17 AND 18 THEN -UNIFORM(30::FLOAT, 300::FLOAT, RANDOM())
            ELSE CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.4 
                      THEN UNIFORM(500::FLOAT, 10000::FLOAT, RANDOM())
                      ELSE -UNIFORM(500::FLOAT, 10000::FLOAT, RANDOM())
                 END
        END
    , 2) AS amount,
    CASE MOD(SEQ4(), 20)
        WHEN 0 THEN 'Salary'
        WHEN 1 THEN 'Transfer'
        WHEN 2 THEN 'Transfer'
        WHEN 3 THEN 'Transfer'
        WHEN 4 THEN 'Grocery'
        WHEN 5 THEN 'Grocery'
        WHEN 6 THEN 'Grocery'
        WHEN 7 THEN 'Grocery'
        WHEN 8 THEN 'Grocery'
        WHEN 9 THEN 'Online Shopping'
        WHEN 10 THEN 'Online Shopping'
        WHEN 11 THEN 'Online Shopping'
        WHEN 12 THEN 'Online Shopping'
        WHEN 13 THEN 'Online Shopping'
        WHEN 14 THEN 'Bills'
        WHEN 15 THEN 'Bills'
        WHEN 16 THEN 'Bills'
        WHEN 17 THEN 'Entertainment'
        WHEN 18 THEN 'Entertainment'
        ELSE 'Investment'
    END AS category,
    CASE MOD(FLOOR(SEQ4() / 7), 10)
        WHEN 0 THEN 'Warszawa'
        WHEN 1 THEN 'Kraków'
        WHEN 2 THEN 'Wrocław'
        WHEN 3 THEN 'Poznań'
        WHEN 4 THEN 'Gdańsk'
        WHEN 5 THEN 'Łódź'
        WHEN 6 THEN 'Szczecin'
        WHEN 7 THEN 'Katowice'
        WHEN 8 THEN 'Lublin'
        ELSE 'Białystok'
    END AS location_city
FROM TABLE(GENERATOR(ROWCOUNT => 20000000));

-- Sprawdź liczbę transakcji
SELECT COUNT(*) AS transaction_count FROM TRANSACTIONS;

-- Aktualizacja kwot z sezonowością (grudzień +30%, styczeń -20%, wakacje +15%)
UPDATE TRANSACTIONS
SET amount = ROUND(
    amount * CASE 
        WHEN MONTH(transaction_date) = 12 THEN 1.30  -- Grudzień: +30% (święta)
        WHEN MONTH(transaction_date) = 1 THEN 0.80   -- Styczeń: -20% (po świętach)
        WHEN MONTH(transaction_date) IN (7, 8) THEN 1.15  -- Wakacje: +15%
        WHEN MONTH(transaction_date) IN (11) THEN 1.20    -- Listopad: +20% (Black Friday)
        ELSE 1.0
    END
, 2);

-- Dodanie trendu wzrostowego (nowsze transakcje są średnio większe)
UPDATE TRANSACTIONS
SET amount = ROUND(
    amount * (1 + (DATEDIFF(day, DATEADD(year, -3, CURRENT_DATE()), transaction_date) / 1095.0) * 0.15)
, 2);

-- Widok agregujący dane miesięczne dla każdego segmentu
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

-- Widok w formacie dla Snowflake AutoML
CREATE OR REPLACE VIEW V_FORECASTING_DATA AS
SELECT 
    month_year AS ds,           -- Data (wymagane przez AutoML)
    segment,                     -- Parametr grupujący
    total_amount AS y           -- Wartość do prognozowania
FROM V_MONTHLY_SEGMENT_TOTALS
WHERE month_year < DATE_TRUNC('month', CURRENT_DATE())
ORDER BY segment, ds;

-- Sprawdź dane do prognozowania
SELECT * FROM V_FORECASTING_DATA ORDER BY segment, ds;


-- Wyłącz cache
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

-- ZAPYTANIE A - EKSTREMALNE OBCIĄŻENIE
-- Wielokrotne skorelowane podzapytania + funkcje okna + sortowania
SELECT * FROM (
    SELECT 
        c.segment,
        c.customer_id,
        c.name,
        t.transaction_id,
        t.transaction_date,
        t.amount,
        t.category,
        t.location_city,
        
        -- Skorelowane podzapytanie 1: średnia dla tego klienta
        (
            SELECT ROUND(AVG(t2.amount), 2)
            FROM TRANSACTIONS t2
            WHERE t2.customer_id = t.customer_id
            AND t2.transaction_date <= t.transaction_date
        ) AS customer_running_avg,
        
        -- Skorelowane podzapytanie 2: liczba transakcji w tym mieście w tym miesiącu
        (
            SELECT COUNT(*)
            FROM TRANSACTIONS t3
            WHERE t3.location_city = t.location_city
            AND DATE_TRUNC('month', t3.transaction_date) = DATE_TRUNC('month', t.transaction_date)
        ) AS city_monthly_count,
        
        -- Skorelowane podzapytanie 3: ranking klienta w segmencie
        (
            SELECT COUNT(DISTINCT t4.customer_id)
            FROM TRANSACTIONS t4
            JOIN CUSTOMERS c4 ON t4.customer_id = c4.customer_id
            WHERE c4.segment = c.segment
            AND t4.amount > t.amount
        ) AS segment_rank_by_amount,
        
        -- Funkcje okna
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY t.transaction_date DESC, t.amount DESC) AS customer_row_num,
        SUM(t.amount) OVER (PARTITION BY c.segment, t.location_city ORDER BY t.transaction_date ROWS UNBOUNDED PRECEDING) AS segment_city_cumsum,
        AVG(t.amount) OVER (PARTITION BY t.category ORDER BY t.transaction_date ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS category_moving_avg,
        
        CURRENT_TIMESTAMP() AS query_ts
        
    FROM TRANSACTIONS t
    JOIN CUSTOMERS c ON t.customer_id = c.customer_id
    WHERE t.transaction_date >= DATEADD(month, -6, CURRENT_DATE())
) sub
WHERE customer_row_num <= 5
ORDER BY segment, customer_running_avg DESC, city_monthly_count DESC, segment_rank_by_amount
LIMIT 10000;