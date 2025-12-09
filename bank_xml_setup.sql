-- ============================================================================
-- BANK TRANSACTIONS XML EXPORT - SETUP SCRIPT
-- Creates database, tables, views, stages, UDFs and procedures
-- Run this script FIRST to set up all infrastructure
-- ============================================================================

-- ===========================================
-- STEP 1: CREATE DATABASE AND SCHEMA
-- ===========================================

CREATE OR REPLACE DATABASE BANK_XML_DEMO;

USE DATABASE BANK_XML_DEMO;

CREATE OR REPLACE SCHEMA TRANSACTIONS;

USE SCHEMA TRANSACTIONS;

-- ===========================================
-- STEP 2: CREATE REFERENCE TABLES
-- ===========================================

-- Account Types
CREATE OR REPLACE TABLE ACCOUNT_TYPES (
    account_type_id INT PRIMARY KEY,
    type_name VARCHAR(50),
    description VARCHAR(200)
);

INSERT INTO ACCOUNT_TYPES VALUES
    (1, 'CHECKING', 'Personal checking account'),
    (2, 'SAVINGS', 'Personal savings account'),
    (3, 'BUSINESS', 'Business checking account'),
    (4, 'CREDIT', 'Credit card account');

-- Transaction Categories
CREATE OR REPLACE TABLE TRANSACTION_CATEGORIES (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50),
    category_code VARCHAR(10)
);

INSERT INTO TRANSACTION_CATEGORIES VALUES
    (1, 'Transfer', 'TRF'),
    (2, 'Payment', 'PMT'),
    (3, 'Withdrawal', 'WTH'),
    (4, 'Deposit', 'DEP'),
    (5, 'Fee', 'FEE'),
    (6, 'Interest', 'INT'),
    (7, 'Purchase', 'PUR');

-- ===========================================
-- STEP 3: CREATE CUSTOMER TABLE
-- ===========================================

CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(20),
    address VARCHAR(300),
    city VARCHAR(100),
    country VARCHAR(100),
    created_date DATE
);

INSERT INTO CUSTOMERS VALUES
    (1001, 'Jan', 'Kowalski', 'jan.kowalski@email.pl', '+48 601 234 567', 'ul. Marszałkowska 10/5', 'Warszawa', 'Poland', '2020-03-15'),
    (1002, 'Anna', 'Nowak', 'anna.nowak@email.pl', '+48 602 345 678', 'ul. Długa 25', 'Kraków', 'Poland', '2019-07-22'),
    (1003, 'Piotr', 'Wiśniewski', 'piotr.w@email.pl', '+48 603 456 789', 'ul. Główna 100', 'Gdańsk', 'Poland', '2021-01-10'),
    (1004, 'Maria', 'Wójcik', 'maria.wojcik@email.pl', '+48 604 567 890', 'ul. Kwiatowa 8', 'Poznań', 'Poland', '2018-11-05'),
    (1005, 'Tomasz', 'Kamiński', 'tomasz.k@email.pl', '+48 605 678 901', 'ul. Lipowa 33', 'Wrocław', 'Poland', '2022-02-28');

-- ===========================================
-- STEP 4: CREATE ACCOUNTS TABLE
-- ===========================================

CREATE OR REPLACE TABLE ACCOUNTS (
    account_id INT PRIMARY KEY,
    customer_id INT REFERENCES CUSTOMERS(customer_id),
    account_type_id INT REFERENCES ACCOUNT_TYPES(account_type_id),
    account_number VARCHAR(34),
    iban VARCHAR(34),
    currency VARCHAR(3),
    balance DECIMAL(15,2),
    status VARCHAR(20),
    opened_date DATE
);

INSERT INTO ACCOUNTS VALUES
    (10001, 1001, 1, 'PL12345678901234567890123456', 'PL61109010140000071219812874', 'PLN', 15420.50, 'ACTIVE', '2020-03-15'),
    (10002, 1001, 2, 'PL23456789012345678901234567', 'PL61109010140000071219812875', 'PLN', 85000.00, 'ACTIVE', '2020-03-15'),
    (10003, 1002, 1, 'PL34567890123456789012345678', 'PL61109010140000071219812876', 'PLN', 3250.75, 'ACTIVE', '2019-07-22'),
    (10004, 1003, 3, 'PL45678901234567890123456789', 'PL61109010140000071219812877', 'PLN', 125000.00, 'ACTIVE', '2021-01-10'),
    (10005, 1004, 1, 'PL56789012345678901234567890', 'PL61109010140000071219812878', 'PLN', 8900.25, 'ACTIVE', '2018-11-05'),
    (10006, 1005, 4, 'PL67890123456789012345678901', 'PL61109010140000071219812879', 'PLN', -2500.00, 'ACTIVE', '2022-02-28');

-- ===========================================
-- STEP 5: CREATE TRANSACTIONS TABLE
-- ===========================================

CREATE OR REPLACE TABLE BANK_TRANSACTIONS (
    transaction_id INT PRIMARY KEY,
    account_id INT REFERENCES ACCOUNTS(account_id),
    category_id INT REFERENCES TRANSACTION_CATEGORIES(category_id),
    transaction_date TIMESTAMP,
    amount DECIMAL(15,2),
    currency VARCHAR(3),
    description VARCHAR(500),
    reference_number VARCHAR(50),
    counterparty_name VARCHAR(200),
    counterparty_account VARCHAR(34),
    status VARCHAR(20)
);

-- Insert sample transactions
INSERT INTO BANK_TRANSACTIONS VALUES
    (100001, 10001, 4, '2024-12-01 09:15:00', 5000.00, 'PLN', 'Salary payment December 2024', 'SAL-2024-12-001', 'ABC Corporation Sp. z o.o.', 'PL98765432109876543210987654', 'COMPLETED'),
    (100002, 10001, 7, '2024-12-02 14:30:00', -156.50, 'PLN', 'Grocery shopping - Biedronka', 'POS-2024-12-001', 'Biedronka S.A.', NULL, 'COMPLETED'),
    (100003, 10001, 2, '2024-12-03 10:00:00', -850.00, 'PLN', 'Electricity bill payment', 'BILL-2024-12-001', 'PGE Obrót S.A.', 'PL11223344556677889900112233', 'COMPLETED'),
    (100004, 10001, 1, '2024-12-04 16:45:00', -2000.00, 'PLN', 'Transfer to savings account', 'TRF-2024-12-001', 'Jan Kowalski', 'PL23456789012345678901234567', 'COMPLETED'),
    (100005, 10002, 4, '2024-12-04 16:45:00', 2000.00, 'PLN', 'Transfer from checking account', 'TRF-2024-12-001', 'Jan Kowalski', 'PL12345678901234567890123456', 'COMPLETED'),
    (100006, 10001, 7, '2024-12-05 12:20:00', -89.99, 'PLN', 'Netflix subscription', 'SUB-2024-12-001', 'Netflix International B.V.', NULL, 'COMPLETED'),
    (100007, 10001, 3, '2024-12-06 18:00:00', -500.00, 'PLN', 'ATM withdrawal - Euronet', 'ATM-2024-12-001', 'ATM Euronet', NULL, 'COMPLETED'),
    (100008, 10003, 4, '2024-12-01 08:30:00', 4200.00, 'PLN', 'Salary payment December 2024', 'SAL-2024-12-002', 'XYZ Technologies S.A.', 'PL87654321098765432109876543', 'COMPLETED'),
    (100009, 10003, 7, '2024-12-03 15:45:00', -1299.00, 'PLN', 'Online purchase - Allegro', 'ECOM-2024-12-001', 'Allegro.pl Sp. z o.o.', NULL, 'COMPLETED'),
    (100010, 10003, 2, '2024-12-05 09:00:00', -450.00, 'PLN', 'Internet and TV bill', 'BILL-2024-12-002', 'Orange Polska S.A.', 'PL55667788990011223344556677', 'COMPLETED'),
    (100011, 10004, 4, '2024-12-02 11:00:00', 25000.00, 'PLN', 'Client payment - Invoice 2024/11/045', 'INV-2024-11-045', 'Global Trade Sp. z o.o.', 'PL99887766554433221100998877', 'COMPLETED'),
    (100012, 10004, 2, '2024-12-04 14:00:00', -8500.00, 'PLN', 'Supplier payment - Materials', 'SUP-2024-12-001', 'Steel Works S.A.', 'PL44332211009988776655443322', 'COMPLETED'),
    (100013, 10004, 5, '2024-12-05 00:00:00', -50.00, 'PLN', 'Monthly account maintenance fee', 'FEE-2024-12-001', 'Bank', NULL, 'COMPLETED'),
    (100014, 10005, 4, '2024-12-01 09:00:00', 3800.00, 'PLN', 'Pension payment December 2024', 'PEN-2024-12-001', 'ZUS', 'PL00112233445566778899001122', 'COMPLETED'),
    (100015, 10005, 7, '2024-12-02 11:30:00', -245.00, 'PLN', 'Pharmacy - medications', 'POS-2024-12-002', 'Apteka Gemini', NULL, 'COMPLETED'),
    (100016, 10006, 7, '2024-12-01 20:15:00', -350.00, 'PLN', 'Restaurant - dinner', 'POS-2024-12-003', 'Restauracja Polska', NULL, 'COMPLETED'),
    (100017, 10006, 7, '2024-12-03 16:00:00', -1200.00, 'PLN', 'Furniture store purchase', 'POS-2024-12-004', 'IKEA Retail Sp. z o.o.', NULL, 'COMPLETED'),
    (100018, 10006, 6, '2024-12-05 00:00:00', -45.50, 'PLN', 'Credit card interest charge', 'INT-2024-12-001', 'Bank', NULL, 'COMPLETED'),
    (100019, 10001, 7, '2024-12-07 10:30:00', -65.00, 'PLN', 'Uber ride', 'UBER-2024-12-001', 'Uber B.V.', NULL, 'COMPLETED'),
    (100020, 10001, 1, '2024-12-08 09:00:00', -1500.00, 'PLN', 'Transfer to Anna Nowak', 'TRF-2024-12-002', 'Anna Nowak', 'PL34567890123456789012345678', 'PENDING');


-- ===========================================
-- STEP 6: CREATE VIEWS
-- ===========================================

-- View that combines transaction data for XML export
CREATE OR REPLACE VIEW V_TRANSACTION_DETAILS AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.currency,
    t.description,
    t.reference_number,
    t.status,
    t.counterparty_name,
    t.counterparty_account,
    a.account_number,
    a.iban AS account_iban,
    at.type_name AS account_type,
    tc.category_name AS transaction_category,
    tc.category_code,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email
FROM BANK_TRANSACTIONS t
JOIN ACCOUNTS a ON t.account_id = a.account_id
JOIN ACCOUNT_TYPES at ON a.account_type_id = at.account_type_id
JOIN TRANSACTION_CATEGORIES tc ON t.category_id = tc.category_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id;

-- View for JSON/XML-ready structured data
CREATE OR REPLACE VIEW V_TRANSACTIONS_AS_OBJECTS AS
SELECT
    OBJECT_CONSTRUCT(
        'transactionId', transaction_id,
        'dateTime', TO_CHAR(transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS'),
        'amount', amount,
        'currency', currency,
        'category', OBJECT_CONSTRUCT(
            'code', category_code,
            'name', transaction_category
        ),
        'description', description,
        'reference', reference_number,
        'status', status,
        'account', OBJECT_CONSTRUCT(
            'iban', account_iban,
            'type', account_type
        ),
        'customer', OBJECT_CONSTRUCT(
            'id', customer_id,
            'name', first_name || ' ' || last_name,
            'email', email
        ),
        'counterparty', CASE WHEN counterparty_name IS NOT NULL THEN
            OBJECT_CONSTRUCT(
                'name', counterparty_name,
                'account', counterparty_account
            )
        ELSE NULL END
    ) AS transaction_object,
    customer_id
FROM V_TRANSACTION_DETAILS;


-- ===========================================
-- STEP 7: CREATE STAGE AND FILE FORMAT
-- ===========================================

-- Create internal stage for XML files
CREATE OR REPLACE STAGE XML_EXPORT_STAGE
    FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = NONE RECORD_DELIMITER = NONE);

-- File format for XML export (alternative)
CREATE OR REPLACE FILE FORMAT XML_FILE_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = NONE
    SKIP_HEADER = 0;


-- ===========================================
-- STEP 8: CREATE JAVASCRIPT UDFs
-- ===========================================

-- Note: Snowflake does NOT have built-in XML generation functions like:
--   - Oracle: XMLELEMENT, XMLAGG, XMLFOREST, XMLROOT
--   - SQL Server: FOR XML PATH, FOR XML AUTO
--   - PostgreSQL: xmlelement, xmlagg
-- SOLUTION: Create JavaScript UDFs to convert JSON to XML automatically!

-- UDF: Convert any JSON object to XML with full document declaration
CREATE OR REPLACE FUNCTION JSON_TO_XML(json_data VARIANT, root_element VARCHAR)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
function jsonToXml(obj, rootName) {
    function escapeXml(str) {
        if (str === null || str === undefined) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }
    
    function convert(obj, tagName) {
        let xml = '';
        
        if (obj === null || obj === undefined) {
            return '<' + tagName + '/>';
        }
        
        if (Array.isArray(obj)) {
            for (let i = 0; i < obj.length; i++) {
                xml += convert(obj[i], tagName);
            }
            return xml;
        }
        
        if (typeof obj === 'object') {
            xml = '<' + tagName + '>';
            for (let key in obj) {
                if (obj.hasOwnProperty(key)) {
                    xml += convert(obj[key], key);
                }
            }
            xml += '</' + tagName + '>';
            return xml;
        }
        
        return '<' + tagName + '>' + escapeXml(obj) + '</' + tagName + '>';
    }
    
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + convert(obj, rootName);
}

return jsonToXml(JSON_DATA, ROOT_ELEMENT);
$$;

-- UDF: Convert single row to XML element (without document declaration)
CREATE OR REPLACE FUNCTION ROW_TO_XML(json_data VARIANT, element_name VARCHAR)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
function escapeXml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

function convert(obj, tagName) {
    let xml = '';
    
    if (obj === null || obj === undefined) {
        return '<' + tagName + '/>';
    }
    
    if (Array.isArray(obj)) {
        for (let i = 0; i < obj.length; i++) {
            xml += convert(obj[i], 'item');
        }
        return '<' + tagName + '>' + xml + '</' + tagName + '>';
    }
    
    if (typeof obj === 'object') {
        xml = '<' + tagName + '>';
        for (let key in obj) {
            if (obj.hasOwnProperty(key)) {
                xml += convert(obj[key], key);
            }
        }
        xml += '</' + tagName + '>';
        return xml;
    }
    
    return '<' + tagName + '>' + escapeXml(obj) + '</' + tagName + '>';
}

return convert(JSON_DATA, ELEMENT_NAME);
$$;


-- ===========================================
-- STEP 9: CREATE STORED PROCEDURES
-- ===========================================

-- Stored procedure for XML export by customer
CREATE OR REPLACE PROCEDURE EXPORT_CUSTOMER_TRANSACTIONS_XML(CUSTOMER_ID_PARAM INT)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    xml_content VARCHAR;
    file_name VARCHAR;
BEGIN
    -- Generate XML content
    SELECT 
        '<?xml version="1.0" encoding="UTF-8"?>' || CHR(10) ||
        '<BankStatement xmlns="http://bank.example.com/statement">' || CHR(10) ||
        '  <Header>' || CHR(10) ||
        '    <GeneratedAt>' || CURRENT_TIMESTAMP() || '</GeneratedAt>' || CHR(10) ||
        '    <Bank>Demo Bank S.A.</Bank>' || CHR(10) ||
        '    <StatementPeriod>' || CHR(10) ||
        '      <From>' || MIN(TO_CHAR(transaction_date, 'YYYY-MM-DD')) || '</From>' || CHR(10) ||
        '      <To>' || MAX(TO_CHAR(transaction_date, 'YYYY-MM-DD')) || '</To>' || CHR(10) ||
        '    </StatementPeriod>' || CHR(10) ||
        '  </Header>' || CHR(10) ||
        '  <Customer>' || CHR(10) ||
        '    <CustomerId>' || MAX(customer_id) || '</CustomerId>' || CHR(10) ||
        '    <FullName>' || MAX(first_name) || ' ' || MAX(last_name) || '</FullName>' || CHR(10) ||
        '    <Email>' || MAX(email) || '</Email>' || CHR(10) ||
        '  </Customer>' || CHR(10) ||
        '  <Summary>' || CHR(10) ||
        '    <TotalTransactions>' || COUNT(*) || '</TotalTransactions>' || CHR(10) ||
        '    <TotalCredits>' || SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) || '</TotalCredits>' || CHR(10) ||
        '    <TotalDebits>' || SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) || '</TotalDebits>' || CHR(10) ||
        '    <NetChange>' || SUM(amount) || '</NetChange>' || CHR(10) ||
        '  </Summary>' || CHR(10) ||
        '  <Transactions>' || CHR(10) ||
        LISTAGG(
            '    <Transaction id="' || transaction_id || '">' || CHR(10) ||
            '      <DateTime>' || TO_CHAR(transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS') || '</DateTime>' || CHR(10) ||
            '      <Amount currency="' || currency || '">' || amount || '</Amount>' || CHR(10) ||
            '      <Type>' || CASE WHEN amount > 0 THEN 'CREDIT' ELSE 'DEBIT' END || '</Type>' || CHR(10) ||
            '      <Category code="' || category_code || '">' || transaction_category || '</Category>' || CHR(10) ||
            '      <Description><![CDATA[' || COALESCE(description, '') || ']]></Description>' || CHR(10) ||
            '      <Reference>' || COALESCE(reference_number, '') || '</Reference>' || CHR(10) ||
            '      <Status>' || status || '</Status>' || CHR(10) ||
            '      <Account>' || CHR(10) ||
            '        <IBAN>' || account_iban || '</IBAN>' || CHR(10) ||
            '        <Type>' || account_type || '</Type>' || CHR(10) ||
            '      </Account>' || CHR(10) ||
            CASE WHEN counterparty_name IS NOT NULL THEN
            '      <Counterparty>' || CHR(10) ||
            '        <Name><![CDATA[' || COALESCE(counterparty_name, '') || ']]></Name>' || CHR(10) ||
            COALESCE('        <IBAN>' || counterparty_account || '</IBAN>' || CHR(10), '') ||
            '      </Counterparty>' || CHR(10)
            ELSE '' END ||
            '    </Transaction>', '
'
        ) || CHR(10) ||
        '  </Transactions>' || CHR(10) ||
        '</BankStatement>'
    INTO xml_content
    FROM V_TRANSACTION_DETAILS
    WHERE customer_id = :CUSTOMER_ID_PARAM;
    
    -- Create filename
    file_name := 'statement_customer_' || :CUSTOMER_ID_PARAM || '_' || 
                 TO_CHAR(CURRENT_DATE(), 'YYYYMMDD') || '.xml';
    
    RETURN xml_content;
END;
$$;


-- ===========================================
-- STEP 10: PYTHON UDF (OPTIONAL - if Python enabled)
-- ===========================================

-- Uncomment if your Snowflake account has Anaconda packages enabled
/*
CREATE OR REPLACE FUNCTION JSON_TO_XML_PY(json_data VARIANT, root_element VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
HANDLER = 'convert_to_xml'
AS
$$
import json
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def dict_to_xml(data, parent):
    if isinstance(data, dict):
        for key, value in data.items():
            child = SubElement(parent, str(key))
            dict_to_xml(value, child)
    elif isinstance(data, list):
        for item in data:
            child = SubElement(parent, 'item')
            dict_to_xml(item, child)
    else:
        parent.text = str(data) if data is not None else ''

def convert_to_xml(json_data, root_element):
    root = Element(root_element)
    dict_to_xml(json_data, root)
    xml_str = tostring(root, encoding='unicode')
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_str
$$;
*/


-- ===========================================
-- SETUP COMPLETE!
-- ===========================================
-- Now run bank_xml_queries.sql to test the XML export functionality

