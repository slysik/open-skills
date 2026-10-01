-- Ported from https://github.com/mwissad/databricks-genie-metricview
-- src/metric_views/retail_transactions_metric_view.yaml, adapted to
-- CREATE OR REPLACE VIEW ... WITH METRICS LANGUAGE YAML (current UC metric
-- view syntax) with source repointed to retail_demo.retail.retail_transactions.

CREATE OR REPLACE VIEW retail_demo.retail.mv_retail_transactions
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
source: retail_demo.retail.retail_transactions
comment: "Metric view for analyzing retail transactions across store locations. Includes sales performance, customer segmentation, product analytics, and payment insights."

dimensions:
  - name: transaction_id
    expr: TransactionID
    comment: Unique transaction identifier
  - name: store_id
    expr: StoreID
    comment: Store identifier code
  - name: store_city
    expr: StoreCity
    comment: City where the store is located
  - name: customer_id
    expr: CustomerID
    comment: Customer identifier
  - name: customer_segment
    expr: CustomerSegment
    comment: "Customer loyalty segment (VIP, Premium, Regular, New)"
  - name: transaction_date_time
    expr: TransactionDateTime
    comment: Transaction date and time
  - name: transaction_date
    expr: DATE(TransactionDateTime)
    comment: Transaction date only
  - name: transaction_year
    expr: YEAR(TransactionDateTime)
    comment: Transaction year
  - name: transaction_month
    expr: MONTH(TransactionDateTime)
    comment: Transaction month
  - name: transaction_day
    expr: DAY(TransactionDateTime)
    comment: Transaction day of month
  - name: transaction_hour
    expr: HOUR(TransactionDateTime)
    comment: Hour of the transaction (0-23)
  - name: day_of_week
    expr: DAYOFWEEK(TransactionDateTime)
    comment: "Day of the week (1=Sunday, 7=Saturday)"
  - name: is_weekend
    expr: CASE WHEN DAYOFWEEK(TransactionDateTime) IN (1, 7) THEN 'Yes' ELSE 'No' END
    comment: Whether the transaction occurred on a weekend
  - name: product_id
    expr: ProductID
    comment: Product identifier
  - name: product_name
    expr: ProductName
    comment: Name of the product
  - name: category
    expr: Category
    comment: Product category
  - name: payment_method
    expr: PaymentMethod
    comment: Payment method used for the transaction
  - name: has_discount
    expr: CASE WHEN DiscountPercent > 0 THEN 'Yes' ELSE 'No' END
    comment: Whether a discount was applied to the transaction
  - name: discount_tier
    expr: >-
      CASE
        WHEN DiscountPercent = 0 THEN 'No Discount'
        WHEN DiscountPercent <= 5 THEN 'Low (1-5%)'
        WHEN DiscountPercent <= 10 THEN 'Medium (6-10%)'
        WHEN DiscountPercent <= 15 THEN 'High (11-15%)'
        ELSE 'Very High (>15%)'
      END
    comment: Discount percentage tier

measures:
  - name: total_revenue
    expr: SUM(TotalAmount)
    comment: Total revenue from all transactions
  - name: average_transaction_value
    expr: AVG(TotalAmount)
    comment: Average transaction value
  - name: max_transaction_value
    expr: MAX(TotalAmount)
    comment: Maximum transaction value
  - name: min_transaction_value
    expr: MIN(TotalAmount)
    comment: Minimum transaction value
  - name: total_quantity_sold
    expr: SUM(Quantity)
    comment: Total quantity of items sold
  - name: average_quantity_per_transaction
    expr: AVG(Quantity)
    comment: Average quantity of items per transaction
  - name: transaction_count
    expr: COUNT(1)
    comment: Total number of transactions
  - name: unique_customers
    expr: COUNT(DISTINCT CustomerID)
    comment: Number of unique customers
  - name: unique_products_sold
    expr: COUNT(DISTINCT ProductID)
    comment: Number of unique products sold
  - name: unique_stores
    expr: COUNT(DISTINCT StoreID)
    comment: Number of unique stores
  - name: average_discount_percent
    expr: AVG(DiscountPercent)
    comment: Average discount percentage applied
  - name: discounted_transaction_count
    expr: SUM(CASE WHEN DiscountPercent > 0 THEN 1 ELSE 0 END)
    comment: Number of transactions with discounts
  - name: total_discount_amount
    expr: SUM((Quantity * UnitPrice) - TotalAmount)
    comment: Total discount amount given
  - name: average_unit_price
    expr: AVG(UnitPrice)
    comment: Average unit price
  - name: total_gross_revenue
    expr: SUM(Quantity * UnitPrice)
    comment: Total revenue before discounts
  # Composed via MEASURE() -- divide last, re-aggregates safely at any grain.
  - name: discount_rate
    expr: "(MEASURE(`total_gross_revenue`) - MEASURE(`total_revenue`)) / NULLIF(MEASURE(`total_gross_revenue`), 0)"
    comment: Percentage of revenue lost to discounts
  - name: revenue_per_customer
    expr: "MEASURE(`total_revenue`) / NULLIF(MEASURE(`unique_customers`), 0)"
    comment: Average revenue per unique customer
  - name: revenue_per_store
    expr: "MEASURE(`total_revenue`) / NULLIF(MEASURE(`unique_stores`), 0)"
    comment: Average revenue per store
  - name: transactions_per_customer
    expr: "MEASURE(`transaction_count`) / NULLIF(MEASURE(`unique_customers`), 0)"
    comment: Average transactions per customer
  - name: items_per_transaction
    expr: "MEASURE(`total_quantity_sold`) / NULLIF(MEASURE(`transaction_count`), 0)"
    comment: Average items per transaction
  - name: discount_penetration
    expr: "MEASURE(`discounted_transaction_count`) / NULLIF(MEASURE(`transaction_count`), 0)"
    comment: Percentage of transactions with discounts
$$
