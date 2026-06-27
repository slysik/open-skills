CREATE DATABASE IF NOT EXISTS __DATABASE__;
CREATE SCHEMA IF NOT EXISTS __TARGET__;
CREATE WAREHOUSE IF NOT EXISTS __WAREHOUSE__
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE OR REPLACE TABLE __TARGET__.customers (
  customer_id VARCHAR,
  customer_name VARCHAR,
  segment VARCHAR,
  region VARCHAR,
  lifecycle_status VARCHAR,
  signup_date DATE
);

CREATE OR REPLACE TABLE __TARGET__.products (
  product_id VARCHAR,
  product_name VARCHAR,
  category VARCHAR,
  unit_price NUMBER(12,2),
  launch_date DATE
);

CREATE OR REPLACE TABLE __TARGET__.orders (
  order_id VARCHAR,
  customer_id VARCHAR,
  order_ts TIMESTAMP_NTZ,
  channel VARCHAR,
  order_status VARCHAR,
  order_total NUMBER(12,2)
);

CREATE OR REPLACE TABLE __TARGET__.order_items (
  order_id VARCHAR,
  line_id INTEGER,
  product_id VARCHAR,
  quantity INTEGER,
  unit_price NUMBER(12,2),
  returned_flag BOOLEAN
);

CREATE OR REPLACE TABLE __TARGET__.support_tickets (
  ticket_id VARCHAR,
  customer_id VARCHAR,
  order_id VARCHAR,
  product_id VARCHAR,
  created_ts TIMESTAMP_NTZ,
  channel VARCHAR,
  priority VARCHAR,
  ticket_status VARCHAR,
  subject VARCHAR,
  description VARCHAR,
  expected_category VARCHAR,
  expected_sentiment VARCHAR
);

CREATE OR REPLACE TABLE __TARGET__.ticket_messages (
  message_id VARCHAR,
  ticket_id VARCHAR,
  author_type VARCHAR,
  message_ts TIMESTAMP_NTZ,
  message_body VARCHAR
);

CREATE OR REPLACE TABLE __TARGET__.knowledge_articles (
  article_id VARCHAR,
  product_id VARCHAR,
  title VARCHAR,
  article_body VARCHAR,
  policy_tags VARCHAR
);
