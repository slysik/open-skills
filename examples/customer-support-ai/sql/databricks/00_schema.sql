-- open-skills-statement
CREATE SCHEMA IF NOT EXISTS __TARGET__;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.customers (
  customer_id STRING,
  customer_name STRING,
  segment STRING,
  region STRING,
  lifecycle_status STRING,
  signup_date DATE
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.products (
  product_id STRING,
  product_name STRING,
  category STRING,
  unit_price DECIMAL(12,2),
  launch_date DATE
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.orders (
  order_id STRING,
  customer_id STRING,
  order_ts TIMESTAMP,
  channel STRING,
  order_status STRING,
  order_total DECIMAL(12,2)
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.order_items (
  order_id STRING,
  line_id INT,
  product_id STRING,
  quantity INT,
  unit_price DECIMAL(12,2),
  returned_flag BOOLEAN
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.support_tickets (
  ticket_id STRING,
  customer_id STRING,
  order_id STRING,
  product_id STRING,
  created_ts TIMESTAMP,
  channel STRING,
  priority STRING,
  ticket_status STRING,
  subject STRING,
  description STRING,
  expected_category STRING,
  expected_sentiment STRING
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.ticket_messages (
  message_id STRING,
  ticket_id STRING,
  author_type STRING,
  message_ts TIMESTAMP,
  message_body STRING
) USING DELTA;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.knowledge_articles (
  article_id STRING,
  product_id STRING,
  title STRING,
  article_body STRING,
  policy_tags STRING
) USING DELTA;
