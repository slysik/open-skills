DROP VIEW IF EXISTS dbo.customer_360;
DROP VIEW IF EXISTS dbo.ticket_operations;
DROP TABLE IF EXISTS dbo.ticket_ai_enrichment;
DROP TABLE IF EXISTS dbo.ticket_messages;
DROP TABLE IF EXISTS dbo.support_tickets;
DROP TABLE IF EXISTS dbo.order_items;
DROP TABLE IF EXISTS dbo.orders;
DROP TABLE IF EXISTS dbo.knowledge_articles;
DROP TABLE IF EXISTS dbo.products;
DROP TABLE IF EXISTS dbo.customers;
GO

CREATE TABLE dbo.customers (
  customer_id VARCHAR(20) NOT NULL,
  customer_name VARCHAR(200) NOT NULL,
  segment VARCHAR(50) NOT NULL,
  region VARCHAR(50) NOT NULL,
  lifecycle_status VARCHAR(50) NOT NULL,
  signup_date DATE NOT NULL
);
GO

CREATE TABLE dbo.products (
  product_id VARCHAR(20) NOT NULL,
  product_name VARCHAR(200) NOT NULL,
  category VARCHAR(100) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  launch_date DATE NOT NULL
);
GO

CREATE TABLE dbo.orders (
  order_id VARCHAR(20) NOT NULL,
  customer_id VARCHAR(20) NOT NULL,
  order_ts DATETIME2(6) NOT NULL,
  channel VARCHAR(50) NOT NULL,
  order_status VARCHAR(50) NOT NULL,
  order_total DECIMAL(12,2) NOT NULL
);
GO

CREATE TABLE dbo.order_items (
  order_id VARCHAR(20) NOT NULL,
  line_id INT NOT NULL,
  product_id VARCHAR(20) NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  returned_flag BIT NOT NULL
);
GO

CREATE TABLE dbo.support_tickets (
  ticket_id VARCHAR(20) NOT NULL,
  customer_id VARCHAR(20) NOT NULL,
  order_id VARCHAR(20) NULL,
  product_id VARCHAR(20) NULL,
  created_ts DATETIME2(6) NOT NULL,
  channel VARCHAR(50) NOT NULL,
  priority VARCHAR(50) NOT NULL,
  ticket_status VARCHAR(50) NOT NULL,
  subject VARCHAR(500) NOT NULL,
  description VARCHAR(8000) NOT NULL,
  expected_category VARCHAR(50) NOT NULL,
  expected_sentiment VARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.ticket_messages (
  message_id VARCHAR(20) NOT NULL,
  ticket_id VARCHAR(20) NOT NULL,
  author_type VARCHAR(50) NOT NULL,
  message_ts DATETIME2(6) NOT NULL,
  message_body VARCHAR(8000) NOT NULL
);
GO

CREATE TABLE dbo.knowledge_articles (
  article_id VARCHAR(20) NOT NULL,
  product_id VARCHAR(20) NULL,
  title VARCHAR(500) NOT NULL,
  article_body VARCHAR(8000) NOT NULL,
  policy_tags VARCHAR(500) NOT NULL
);
GO
