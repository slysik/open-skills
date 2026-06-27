-- open-skills-statement
CREATE OR REPLACE VIEW __TARGET__.customer_360 AS
SELECT
  c.customer_id,
  c.customer_name,
  c.segment,
  c.region,
  COUNT(DISTINCT o.order_id) AS order_count,
  COALESCE(SUM(o.order_total), 0) AS lifetime_order_value,
  COUNT(DISTINCT t.ticket_id) AS ticket_count,
  SUM(CASE WHEN t.ticket_status IN ('open', 'pending') THEN 1 ELSE 0 END) AS active_ticket_count
FROM __TARGET__.customers c
LEFT JOIN __TARGET__.orders o ON o.customer_id = c.customer_id
LEFT JOIN __TARGET__.support_tickets t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment, c.region;

-- open-skills-statement
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

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.ticket_ai_enrichment AS
SELECT
  ticket_id,
  ai_summarize(CONCAT(subject, '. ', description)) AS ai_summary,
  ai_classify(
    description,
    ARRAY('billing', 'technical', 'shipping', 'returns', 'account', 'product')
  ) AS ai_category,
  ai_analyze_sentiment(description) AS ai_sentiment,
  expected_category,
  expected_sentiment
FROM __TARGET__.support_tickets;

-- open-skills-statement
CREATE OR REPLACE TABLE __TARGET__.rag_smoke_result AS
SELECT
  article_id,
  title,
  ai_similarity(
    article_body,
    'How do I recover a gateway that went offline after a firmware update?'
  ) AS similarity
FROM __TARGET__.knowledge_articles
ORDER BY similarity DESC
LIMIT 3;
