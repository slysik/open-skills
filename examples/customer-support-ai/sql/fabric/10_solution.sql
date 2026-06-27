CREATE VIEW dbo.customer_360 AS
SELECT
  c.customer_id,
  c.customer_name,
  c.segment,
  c.region,
  COUNT(DISTINCT o.order_id) AS order_count,
  COALESCE(SUM(o.order_total), 0) AS lifetime_order_value,
  COUNT(DISTINCT t.ticket_id) AS ticket_count,
  SUM(CASE WHEN t.ticket_status IN ('open', 'pending') THEN 1 ELSE 0 END) AS active_ticket_count
FROM dbo.customers c
LEFT JOIN dbo.orders o ON o.customer_id = c.customer_id
LEFT JOIN dbo.support_tickets t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment, c.region;
GO

CREATE VIEW dbo.ticket_operations AS
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
FROM dbo.support_tickets t
JOIN dbo.customers c ON c.customer_id = t.customer_id
LEFT JOIN dbo.products p ON p.product_id = t.product_id
LEFT JOIN dbo.orders o ON o.order_id = t.order_id;
GO

SELECT
  ticket_id,
  AI_SUMMARIZE(CONCAT(subject, '. ', description)) AS ai_summary,
  AI_CLASSIFY(
    description,
    'billing, technical, shipping, returns, account, product'
  ) AS ai_category,
  AI_ANALYZE_SENTIMENT(description) AS ai_sentiment,
  expected_category,
  expected_sentiment
INTO dbo.ticket_ai_enrichment
FROM dbo.support_tickets;
GO
