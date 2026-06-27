CREATE OR REPLACE VIEW __TARGET__.customer_360 AS
SELECT
  c.customer_id,
  c.customer_name,
  c.segment,
  c.region,
  COUNT(DISTINCT o.order_id) AS order_count,
  COALESCE(SUM(o.order_total), 0) AS lifetime_order_value,
  COUNT(DISTINCT t.ticket_id) AS ticket_count,
  SUM(IFF(t.ticket_status IN ('open', 'pending'), 1, 0)) AS active_ticket_count
FROM __TARGET__.customers c
LEFT JOIN __TARGET__.orders o ON o.customer_id = c.customer_id
LEFT JOIN __TARGET__.support_tickets t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment, c.region;

CREATE OR REPLACE VIEW __TARGET__.ticket_operations AS
SELECT
  t.ticket_id,
  t.created_ts,
  t.priority,
  t.ticket_status,
  c.customer_name,
  c.segment,
  p.product_name,
  p.category AS product_category,
  o.order_status,
  t.subject,
  t.description
FROM __TARGET__.support_tickets t
JOIN __TARGET__.customers c ON c.customer_id = t.customer_id
LEFT JOIN __TARGET__.products p ON p.product_id = t.product_id
LEFT JOIN __TARGET__.orders o ON o.order_id = t.order_id;

CREATE OR REPLACE TABLE __TARGET__.ticket_ai_enrichment AS
SELECT
  ticket_id,
  SNOWFLAKE.CORTEX.SUMMARIZE(subject || '. ' || description) AS ai_summary,
  SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
    description,
    ['billing', 'technical', 'shipping', 'returns', 'account', 'product']
  ) AS ai_category,
  SNOWFLAKE.CORTEX.SENTIMENT(description) AS ai_sentiment,
  expected_category,
  expected_sentiment
FROM __TARGET__.support_tickets;

CREATE OR REPLACE CORTEX SEARCH SERVICE __TARGET__.knowledge_search
  ON article_body
  ATTRIBUTES title, product_id, policy_tags
  WAREHOUSE = __WAREHOUSE__
  TARGET_LAG = '1 hour'
  AS
  SELECT article_id, title, product_id, article_body, policy_tags
  FROM __TARGET__.knowledge_articles;
