-- Ported from https://github.com/mwissad/databricks-genie-metricview
-- src/metric_views/retail_store_performance_metric_view.yaml, adapted to
-- CREATE OR REPLACE VIEW ... WITH METRICS LANGUAGE YAML, source repointed to
-- retail_demo.retail.store_performance.
--
-- NOTE: the source repo's YAML treats Month as a "YYYY-MM" STRING and parses
-- year/month/quarter via SUBSTRING. Loading this CSV with inferSchema => true
-- (01_load_tables.sql) parses Month as a real DATE (first-of-month, e.g.
-- 2024-01 -> 2024-01-01) instead -- so year/month_number/quarter below use
-- YEAR()/MONTH()/QUARTER() directly rather than string-slicing a date.

CREATE OR REPLACE VIEW retail_demo.retail.mv_store_performance
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
source: retail_demo.retail.store_performance
comment: "Metric view for analyzing monthly store performance across retail locations. Includes revenue, transactions, profitability, and operational efficiency metrics."

dimensions:
  - name: store_id
    expr: StoreID
    comment: Store identifier code
  - name: city
    expr: City
    comment: City where the store is located
  - name: month
    expr: Month
    comment: First day of the reporting month
  - name: year
    expr: YEAR(Month)
    comment: Year extracted from month
  - name: month_number
    expr: MONTH(Month)
    comment: Month number (1-12)
  - name: quarter
    expr: CONCAT('Q', QUARTER(Month))
    comment: Quarter of the year
  - name: revenue_tier
    expr: >-
      CASE
        WHEN MonthlyRevenue < 1000000 THEN 'Low (<1M)'
        WHEN MonthlyRevenue < 1500000 THEN 'Medium (1M-1.5M)'
        WHEN MonthlyRevenue < 2000000 THEN 'High (1.5M-2M)'
        ELSE 'Very High (>2M)'
      END
    comment: Monthly revenue tier
  - name: profit_margin_tier
    expr: >-
      CASE
        WHEN ProfitMarginPercent < 30 THEN 'Low (<30%)'
        WHEN ProfitMarginPercent < 50 THEN 'Medium (30-50%)'
        WHEN ProfitMarginPercent < 70 THEN 'High (50-70%)'
        ELSE 'Very High (>70%)'
      END
    comment: Profit margin tier
  - name: store_size_tier
    expr: >-
      CASE
        WHEN EmployeeCount < 60 THEN 'Small (<60 employees)'
        WHEN EmployeeCount < 90 THEN 'Medium (60-90 employees)'
        ELSE 'Large (>90 employees)'
      END
    comment: Store size based on employee count
  - name: transaction_volume_tier
    expr: >-
      CASE
        WHEN MonthlyTransactions < 25000 THEN 'Low Volume'
        WHEN MonthlyTransactions < 35000 THEN 'Medium Volume'
        ELSE 'High Volume'
      END
    comment: Transaction volume tier

measures:
  - name: total_revenue
    expr: SUM(MonthlyRevenue)
    comment: Total revenue across all stores/months
  - name: average_monthly_revenue
    expr: AVG(MonthlyRevenue)
    comment: Average monthly revenue per store
  - name: max_monthly_revenue
    expr: MAX(MonthlyRevenue)
    comment: Maximum monthly revenue
  - name: min_monthly_revenue
    expr: MIN(MonthlyRevenue)
    comment: Minimum monthly revenue
  - name: total_transactions
    expr: SUM(MonthlyTransactions)
    comment: Total number of transactions
  - name: average_monthly_transactions
    expr: AVG(MonthlyTransactions)
    comment: Average monthly transactions per store
  - name: max_monthly_transactions
    expr: MAX(MonthlyTransactions)
    comment: Maximum monthly transactions
  - name: average_basket_size
    expr: AVG(AvgBasketSize)
    comment: Average basket size across stores
  - name: max_basket_size
    expr: MAX(AvgBasketSize)
    comment: Maximum average basket size
  - name: min_basket_size
    expr: MIN(AvgBasketSize)
    comment: Minimum average basket size
  - name: weighted_avg_basket_size
    expr: "SUM(AvgBasketSize * MonthlyTransactions) / NULLIF(SUM(MonthlyTransactions), 0)"
    comment: Weighted average basket size by transaction volume
  - name: total_unique_customers
    expr: SUM(UniqueCustomers)
    comment: Total unique customers (sum across store-months)
  - name: average_unique_customers
    expr: AVG(UniqueCustomers)
    comment: Average unique customers per store-month
  - name: max_unique_customers
    expr: MAX(UniqueCustomers)
    comment: Maximum unique customers in a store-month
  - name: total_employees
    expr: SUM(EmployeeCount)
    comment: Total employee count
  - name: average_employees_per_store
    expr: AVG(EmployeeCount)
    comment: Average employees per store
  - name: total_operating_costs
    expr: SUM(OperatingCosts)
    comment: Total operating costs
  - name: average_profit_margin
    expr: AVG(ProfitMarginPercent)
    comment: Average profit margin percentage
  - name: max_profit_margin
    expr: MAX(ProfitMarginPercent)
    comment: Maximum profit margin percentage
  - name: min_profit_margin
    expr: MIN(ProfitMarginPercent)
    comment: Minimum profit margin percentage
  - name: weighted_avg_profit_margin
    expr: "SUM(ProfitMarginPercent * MonthlyRevenue) / NULLIF(SUM(MonthlyRevenue), 0)"
    comment: Weighted average profit margin by revenue
  - name: store_month_count
    expr: COUNT(1)
    comment: Number of store-month records
  - name: unique_stores
    expr: COUNT(DISTINCT StoreID)
    comment: Number of unique stores
  - name: unique_cities
    expr: COUNT(DISTINCT City)
    comment: Number of unique cities
  - name: unique_months
    expr: COUNT(DISTINCT Month)
    comment: Number of unique months
  - name: total_profit
    expr: SUM(MonthlyRevenue * ProfitMarginPercent / 100)
    comment: Total estimated profit
  # Composed via MEASURE() -- divide last, re-aggregates safely at any grain.
  - name: cost_to_revenue_ratio
    expr: "MEASURE(`total_operating_costs`) / NULLIF(MEASURE(`total_revenue`), 0)"
    comment: Operating costs as percentage of revenue
  - name: revenue_per_employee
    expr: "MEASURE(`total_revenue`) / NULLIF(MEASURE(`total_employees`), 0)"
    comment: Revenue per employee
  - name: revenue_per_transaction
    expr: "MEASURE(`total_revenue`) / NULLIF(MEASURE(`total_transactions`), 0)"
    comment: Revenue per transaction
  - name: transactions_per_customer
    expr: "MEASURE(`total_transactions`) / NULLIF(MEASURE(`total_unique_customers`), 0)"
    comment: Transactions per unique customer
  - name: customers_per_employee
    expr: "MEASURE(`total_unique_customers`) / NULLIF(MEASURE(`total_employees`), 0)"
    comment: Customers served per employee
  - name: operating_cost_per_transaction
    expr: "MEASURE(`total_operating_costs`) / NULLIF(MEASURE(`total_transactions`), 0)"
    comment: Operating cost per transaction
  - name: profit_per_employee
    expr: "MEASURE(`total_profit`) / NULLIF(MEASURE(`total_employees`), 0)"
    comment: Profit per employee
$$
