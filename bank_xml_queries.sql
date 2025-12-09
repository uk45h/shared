-- ============================================================================
-- BANK TRANSACTIONS XML EXPORT - QUERIES AND TESTS
-- Run this AFTER executing bank_xml_setup.sql
-- ============================================================================

USE DATABASE BANK_XML_DEMO;
USE SCHEMA TRANSACTIONS;

-- ===========================================
-- VERIFICATION: CHECK DATA WAS LOADED
-- ===========================================

-- Check all tables have data
SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL
SELECT 'ACCOUNTS', COUNT(*) FROM ACCOUNTS
UNION ALL
SELECT 'BANK_TRANSACTIONS', COUNT(*) FROM BANK_TRANSACTIONS
UNION ALL
SELECT 'ACCOUNT_TYPES', COUNT(*) FROM ACCOUNT_TYPES
UNION ALL
SELECT 'TRANSACTION_CATEGORIES', COUNT(*) FROM TRANSACTION_CATEGORIES;


-- ===========================================
-- TEST 1: SIMPLE XML GENERATION (String Concatenation)
-- ===========================================

-- Generate XML for single transactions
SELECT 
    '<Transaction>' ||
    '<TransactionId>' || transaction_id || '</TransactionId>' ||
    '<Date>' || TO_CHAR(transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS') || '</Date>' ||
    '<Amount>' || amount || '</Amount>' ||
    '<Currency>' || currency || '</Currency>' ||
    '<Category>' || transaction_category || '</Category>' ||
    '<Description>' || COALESCE(REPLACE(REPLACE(description, '&', '&amp;'), '<', '&lt;'), '') || '</Description>' ||
    '<Status>' || status || '</Status>' ||
    '<Account>' ||
        '<IBAN>' || account_iban || '</IBAN>' ||
        '<Type>' || account_type || '</Type>' ||
    '</Account>' ||
    '<Customer>' ||
        '<Name>' || first_name || ' ' || last_name || '</Name>' ||
        '<Email>' || email || '</Email>' ||
    '</Customer>' ||
    CASE WHEN counterparty_name IS NOT NULL THEN
        '<Counterparty>' ||
            '<Name>' || COALESCE(REPLACE(REPLACE(counterparty_name, '&', '&amp;'), '<', '&lt;'), '') || '</Name>' ||
            COALESCE('<Account>' || counterparty_account || '</Account>', '') ||
        '</Counterparty>'
    ELSE '' END ||
    '</Transaction>' AS xml_transaction
FROM V_TRANSACTION_DETAILS
WHERE customer_id = 1001
ORDER BY transaction_date;


-- ===========================================
-- TEST 2: FULL XML DOCUMENT WITH LISTAGG
-- ===========================================

-- Generate complete XML document with all transactions for a customer
WITH customer_transactions AS (
    SELECT * FROM V_TRANSACTION_DETAILS
    WHERE customer_id = 1001
    ORDER BY transaction_date
)
SELECT 
    '<?xml version="1.0" encoding="UTF-8"?>' || CHR(10) ||
    '<BankStatement>' || CHR(10) ||
    '  <GeneratedAt>' || CURRENT_TIMESTAMP() || '</GeneratedAt>' || CHR(10) ||
    '  <Customer>' || CHR(10) ||
    '    <CustomerId>' || MAX(customer_id) || '</CustomerId>' || CHR(10) ||
    '    <Name>' || MAX(first_name) || ' ' || MAX(last_name) || '</Name>' || CHR(10) ||
    '    <Email>' || MAX(email) || '</Email>' || CHR(10) ||
    '  </Customer>' || CHR(10) ||
    '  <Transactions>' || CHR(10) ||
    LISTAGG(
        '    <Transaction>' || CHR(10) ||
        '      <Id>' || transaction_id || '</Id>' || CHR(10) ||
        '      <Date>' || TO_CHAR(transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS') || '</Date>' || CHR(10) ||
        '      <Amount>' || amount || '</Amount>' || CHR(10) ||
        '      <Currency>' || currency || '</Currency>' || CHR(10) ||
        '      <Category code="' || category_code || '">' || transaction_category || '</Category>' || CHR(10) ||
        '      <Description>' || COALESCE(REPLACE(REPLACE(description, '&', '&amp;'), '<', '&lt;'), '') || '</Description>' || CHR(10) ||
        '      <Reference>' || COALESCE(reference_number, 'N/A') || '</Reference>' || CHR(10) ||
        '      <Status>' || status || '</Status>' || CHR(10) ||
        '      <AccountIBAN>' || account_iban || '</AccountIBAN>' || CHR(10) ||
        CASE WHEN counterparty_name IS NOT NULL THEN
        '      <Counterparty>' || CHR(10) ||
        '        <Name>' || COALESCE(REPLACE(REPLACE(counterparty_name, '&', '&amp;'), '<', '&lt;'), '') || '</Name>' || CHR(10) ||
        COALESCE('        <Account>' || counterparty_account || '</Account>' || CHR(10), '') ||
        '      </Counterparty>' || CHR(10)
        ELSE '' END ||
        '    </Transaction>', '
'
    ) || CHR(10) ||
    '  </Transactions>' || CHR(10) ||
    '</BankStatement>' AS xml_statement
FROM customer_transactions;


-- ===========================================
-- TEST 3: CALL STORED PROCEDURE
-- ===========================================

-- Generate XML for customer 1001
CALL EXPORT_CUSTOMER_TRANSACTIONS_XML(1001);

-- Generate XML for customer 1002
CALL EXPORT_CUSTOMER_TRANSACTIONS_XML(1002);

-- Generate XML for customer 1003 (business account)
CALL EXPORT_CUSTOMER_TRANSACTIONS_XML(1003);


-- ===========================================
-- TEST 4: JSON_TO_XML UDF - SINGLE TRANSACTION
-- ===========================================

-- Convert single transaction to XML using UDF
SELECT JSON_TO_XML(
    OBJECT_CONSTRUCT(
        'TransactionId', transaction_id,
        'Date', TO_CHAR(transaction_date, 'YYYY-MM-DD'),
        'Amount', amount,
        'Currency', currency,
        'Description', description,
        'Status', status
    ),
    'Transaction'
) AS xml_output
FROM BANK_TRANSACTIONS
LIMIT 1;


-- ===========================================
-- TEST 5: JSON_TO_XML UDF - MULTIPLE TRANSACTIONS
-- ===========================================

-- Generate XML for multiple transactions using the UDF
SELECT ROW_TO_XML(
    OBJECT_CONSTRUCT(
        'id', t.transaction_id,
        'date', TO_CHAR(t.transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS'),
        'amount', t.amount,
        'currency', t.currency,
        'category', tc.category_name,
        'description', t.description,
        'counterparty', t.counterparty_name
    ),
    'Transaction'
) AS transaction_xml
FROM BANK_TRANSACTIONS t
JOIN TRANSACTION_CATEGORIES tc ON t.category_id = tc.category_id
WHERE t.account_id = 10001;


-- ===========================================
-- TEST 6: JSON_TO_XML UDF - NESTED STRUCTURE
-- ===========================================

-- Full statement with nested structure (automatic XML generation!)
SELECT JSON_TO_XML(
    OBJECT_CONSTRUCT(
        'Header', OBJECT_CONSTRUCT(
            'GeneratedAt', CURRENT_TIMESTAMP()::VARCHAR,
            'Bank', 'Demo Bank S.A.'
        ),
        'Customer', OBJECT_CONSTRUCT(
            'Id', MAX(c.customer_id),
            'Name', MAX(c.first_name) || ' ' || MAX(c.last_name),
            'Email', MAX(c.email)
        ),
        'Summary', OBJECT_CONSTRUCT(
            'TotalTransactions', COUNT(*),
            'TotalCredits', SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END),
            'TotalDebits', SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END)
        ),
        'Transactions', ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'Id', t.transaction_id,
                'Date', TO_CHAR(t.transaction_date, 'YYYY-MM-DD'),
                'Amount', t.amount,
                'Category', tc.category_name,
                'Description', t.description
            )
        )
    ),
    'BankStatement'
) AS full_xml_statement
FROM BANK_TRANSACTIONS t
JOIN TRANSACTION_CATEGORIES tc ON t.category_id = tc.category_id
JOIN ACCOUNTS a ON t.account_id = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
WHERE c.customer_id = 1001
GROUP BY c.customer_id;


-- ===========================================
-- TEST 7: QUERY THE OBJECT VIEW
-- ===========================================

-- Get structured objects for each transaction
SELECT transaction_object
FROM V_TRANSACTIONS_AS_OBJECTS
WHERE customer_id = 1001;

-- Convert object view to XML
SELECT ROW_TO_XML(transaction_object, 'Transaction') AS xml_transaction
FROM V_TRANSACTIONS_AS_OBJECTS
WHERE customer_id = 1001;


-- ===========================================
-- ANALYTICS QUERIES
-- ===========================================

-- Summary by customer
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) AS total_credits,
    SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) AS total_debits,
    SUM(t.amount) AS net_change
FROM CUSTOMERS c
JOIN ACCOUNTS a ON c.customer_id = a.customer_id
JOIN BANK_TRANSACTIONS t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_transactions DESC;

-- Transaction summary by category
SELECT 
    tc.category_name,
    tc.category_code,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS avg_amount
FROM BANK_TRANSACTIONS t
JOIN TRANSACTION_CATEGORIES tc ON t.category_id = tc.category_id
GROUP BY tc.category_name, tc.category_code
ORDER BY transaction_count DESC;

-- Daily transaction volume
SELECT 
    DATE(transaction_date) AS transaction_day,
    COUNT(*) AS num_transactions,
    SUM(amount) AS daily_total,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS credits,
    SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS debits
FROM BANK_TRANSACTIONS
GROUP BY DATE(transaction_date)
ORDER BY transaction_day;

-- Recent transactions (all customers)
SELECT * FROM V_TRANSACTION_DETAILS
ORDER BY transaction_date DESC
LIMIT 10;

-- Pending transactions
SELECT * FROM V_TRANSACTION_DETAILS
WHERE status = 'PENDING';


-- ===========================================
-- XML FOR ALL CUSTOMERS (BATCH)
-- ===========================================

-- Generate XML statement for each customer
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    JSON_TO_XML(
        OBJECT_CONSTRUCT(
            'CustomerId', customer_id,
            'Name', first_name || ' ' || last_name,
            'Email', email,
            'TotalTransactions', (
                SELECT COUNT(*) 
                FROM BANK_TRANSACTIONS t 
                JOIN ACCOUNTS a ON t.account_id = a.account_id 
                WHERE a.customer_id = c.customer_id
            )
        ),
        'CustomerSummary'
    ) AS customer_xml
FROM CUSTOMERS c;


-- ===========================================
-- CLEANUP (uncomment to drop everything)
-- ===========================================
-- DROP DATABASE BANK_XML_DEMO;

