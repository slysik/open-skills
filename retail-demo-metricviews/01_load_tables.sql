-- Loads the two sample CSVs from https://github.com/mwissad/databricks-genie-metricview
-- into retail_demo.retail as Delta tables, pure SQL (no notebook/Python).
-- CSVs must already be uploaded to the landing volume paths below first:
--   databricks fs cp retail_transactions.csv dbfs:/Volumes/retail_demo/retail/landing/retail_transactions/retail_transactions.csv
--   databricks fs cp store_performance.csv dbfs:/Volumes/retail_demo/retail/landing/store_performance/store_performance.csv

CREATE CATALOG IF NOT EXISTS retail_demo;
CREATE SCHEMA IF NOT EXISTS retail_demo.retail;
CREATE VOLUME IF NOT EXISTS retail_demo.retail.landing;

CREATE OR REPLACE TABLE retail_demo.retail.retail_transactions
COMMENT 'Transaction-level retail data including customer purchases, products, and payment methods'
AS SELECT * FROM read_files('/Volumes/retail_demo/retail/landing/retail_transactions/', format => 'csv', header => true, inferSchema => true);

CREATE OR REPLACE TABLE retail_demo.retail.store_performance
COMMENT 'Monthly aggregated store performance metrics including revenue, costs, and profitability'
AS SELECT * FROM read_files('/Volumes/retail_demo/retail/landing/store_performance/', format => 'csv', header => true, inferSchema => true);

-- NOTE: inferSchema => true parses retail_transactions.csv's TransactionDateTime as
-- TIMESTAMP and store_performance.csv's Month ("YYYY-MM") as DATE (first-of-month,
-- e.g. 2024-01 -> 2024-01-01), not STRING as the source repo's YAML assumed. The
-- metric view below uses YEAR()/MONTH()/QUARTER() on the real DATE type instead of
-- the original's SUBSTRING-on-string hack -- simpler and correct either way.
