# Building Snowflake Objects — Reference Templates

Copy/paste-ready SQL. Replace `<env>` with `dev|stg|prod`. All examples assume
ACCOUNTADMIN bootstrap, then daily work as `SYSADMIN` / functional roles.

## 1. Account bootstrap (one-time)

```sql
USE ROLE ACCOUNTADMIN;

-- Functional roles
CREATE ROLE IF NOT EXISTS DATA_ENGINEER;
CREATE ROLE IF NOT EXISTS ANALYTICS_ENGINEER;
CREATE ROLE IF NOT EXISTS AI_PLATFORM;       -- owns Cortex artifacts
CREATE ROLE IF NOT EXISTS APP_SERVICE;       -- FastAPI/agents auth as this

GRANT ROLE DATA_ENGINEER       TO ROLE SYSADMIN;
GRANT ROLE ANALYTICS_ENGINEER  TO ROLE SYSADMIN;
GRANT ROLE AI_PLATFORM         TO ROLE SYSADMIN;
GRANT ROLE APP_SERVICE         TO ROLE SYSADMIN;

-- Cortex access (database role granted to functional roles)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AI_PLATFORM;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE APP_SERVICE;
```

## 2. Warehouses (isolate AI cost)

```sql
CREATE WAREHOUSE IF NOT EXISTS WH_TRANSFORM
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS WH_AI
  WAREHOUSE_SIZE = SMALL AUTO_SUSPEND = 30 AUTO_RESUME = TRUE
  SCALING_POLICY = 'STANDARD' MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 4;

CREATE WAREHOUSE IF NOT EXISTS WH_BI
  WAREHOUSE_SIZE = SMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
```

## 3. Databases & schemas (medallion + AI plane)

```sql
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS RAW_PROD;
CREATE DATABASE IF NOT EXISTS STG_PROD;
CREATE DATABASE IF NOT EXISTS MART_PROD;
CREATE DATABASE IF NOT EXISTS AI_PROD;

CREATE SCHEMA IF NOT EXISTS AI_PROD.SEARCH;     -- Cortex Search services
CREATE SCHEMA IF NOT EXISTS AI_PROD.SEMANTIC;   -- Semantic views for Cortex Analyst
CREATE SCHEMA IF NOT EXISTS AI_PROD.VECTORS;    -- embedding tables
CREATE SCHEMA IF NOT EXISTS AI_PROD.PROMPTS;    -- prompt UDFs / templates
```

## 4. Tables, stages, streams, dynamic tables

```sql
-- External stage on S3 (or internal)
CREATE STAGE IF NOT EXISTS RAW_PROD.PUBLIC.LANDING
  URL='s3://zebra-raw-prod/landing/'
  STORAGE_INTEGRATION = S3_INT
  FILE_FORMAT = (TYPE = JSON);

-- Raw landing table
CREATE TABLE IF NOT EXISTS RAW_PROD.PUBLIC.QUOTES_RAW (
  payload   VARIANT,
  ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
  src_file  STRING
);

-- Stream for CDC
CREATE STREAM IF NOT EXISTS RAW_PROD.PUBLIC.QUOTES_RAW_S
  ON TABLE RAW_PROD.PUBLIC.QUOTES_RAW APPEND_ONLY = TRUE;

-- Dynamic table = preferred incremental transform
CREATE OR REPLACE DYNAMIC TABLE STG_PROD.PUBLIC.QUOTES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = WH_TRANSFORM
AS
SELECT
  payload:quote_id::STRING        AS quote_id,
  payload:driver_id::STRING       AS driver_id,
  payload:state::STRING           AS state,
  payload:premium_cents::NUMBER   AS premium_cents,
  payload:created_at::TIMESTAMP   AS created_at
FROM RAW_PROD.PUBLIC.QUOTES_RAW;
```

## 5. RBAC pattern (least privilege)

```sql
USE ROLE SECURITYADMIN;
-- per-DB read/write/owner roles
CREATE ROLE IF NOT EXISTS MART_PROD_RO;
GRANT USAGE  ON DATABASE MART_PROD TO ROLE MART_PROD_RO;
GRANT USAGE  ON ALL SCHEMAS IN DATABASE MART_PROD TO ROLE MART_PROD_RO;
GRANT SELECT ON ALL TABLES  IN DATABASE MART_PROD TO ROLE MART_PROD_RO;
GRANT SELECT ON FUTURE TABLES IN DATABASE MART_PROD TO ROLE MART_PROD_RO;
GRANT ROLE MART_PROD_RO TO ROLE APP_SERVICE;
```

## 6. Masking policy (PII for an insurtech)

```sql
CREATE OR REPLACE MASKING POLICY MART_PROD.PUBLIC.MASK_EMAIL AS
  (val STRING) RETURNS STRING ->
    CASE WHEN CURRENT_ROLE() IN ('AI_PLATFORM','APP_SERVICE')
         THEN REGEXP_REPLACE(val,'(^.).*(@.*$)','\\1***\\2')
         ELSE val END;

ALTER TABLE MART_PROD.PUBLIC.CUSTOMERS
  MODIFY COLUMN email SET MASKING POLICY MART_PROD.PUBLIC.MASK_EMAIL;
```

## 7. Prompt-as-UDF (source-controlled prompts)

```sql
CREATE OR REPLACE FUNCTION AI_PROD.PROMPTS.SUMMARIZE_POLICY(doc STRING)
RETURNS STRING
LANGUAGE SQL
AS $$
  SNOWFLAKE.CORTEX.COMPLETE(
    'claude-3-5-sonnet',
    [
      {'role':'system','content':'You summarize insurance policy docs in <=120 words. Output bullets.'},
      {'role':'user','content': doc}
    ],
    {'temperature':0.1,'max_tokens':400}
  )
$$;
```

This is the seed of the "prompt framework / guardrails" deliverable in the JD:
prompts live in DDL, get versioned in dbt, and are auditable.
