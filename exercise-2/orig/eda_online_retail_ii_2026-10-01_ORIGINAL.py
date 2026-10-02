# Databricks notebook source
# MAGIC %md
# MAGIC # Online Retail II — Exploratory Data Analysis
# MAGIC **Data:** UCI Online Retail II, a UK online gift retailer's invoice lines, Dec 2009 – Dec 2011 (the same 1,067,371 rows as the Kaggle copy) · **Platform:** Databricks serverless, Unity Catalog `synaptiq.online_retail` · **Approach:** SQL for the analysis; Python only to read the Excel file and draw two charts. Every number in the text comes from a query cell in this notebook.
# MAGIC
# MAGIC ## 1. Executive summary
# MAGIC
# MAGIC * **Total sales were flat (+1.2% year on year), and the total hides two opposite trends:**
# MAGIC   * **Wholesale customers we can identify: down 2.8%.** They bought **11% fewer units**, partly offset by **9% more value per unit**. On the same products, the price change is somewhere between about **−2% and +5%** depending on the index method. Most of the per-unit rise is mix, not proven price increases.
# MAGIC   * **The unidentified "dotcom" channel: up 32%.** This is the 13% of sales with no customer ID, and all of the net growth sits here.
# MAGIC * **Sales are seasonal and concentrated.** **Sep–Nov is 36–38% of the year**, in both years. The **top 10% of customers bring 63% of sales**. The Netherlands is effectively one account; EIRE is two.
# MAGIC * **Existing customers carry the business.** 64% of year-1 customers bought again, and they produced **83% of year-2 sales** from identified customers. Whether *new*-customer acquisition is slowing **cannot be measured** from two years of data. I tested this and explain why in §4d.
# MAGIC * **Three data issues would have changed the conclusions if missed:**
# MAGIC   1. The two Excel sheets **overlap (1–9 Dec 2010)**: 22,523 rows are an exact copy. That explains two-thirds of the "34,335 duplicates" commonly reported for this data.
# MAGIC   2. **Mis-keyed orders reversed within minutes** (one of 80,995 units) inflate sales and product rankings.
# MAGIC   3. **Missing customer IDs aren't random.** They mark the dotcom channel.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Data overview
# MAGIC
# MAGIC **Source.** One Excel workbook with **two sheets**, `Year 2009-2010` and `Year 2010-2011`: 1,067,371 rows, 8 columns. The popular Kaggle CSV is these two sheets stacked: same rows, with `Customer ID` stored as a float (`13085.0`).
# MAGIC
# MAGIC **Grain.** One row = **one line on an invoice** (a product, a quantity and a unit price), *not* one order.
# MAGIC
# MAGIC | Column | Meaning / what to watch |
# MAGIC |---|---|
# MAGIC | `Invoice` | Prefix **`C` = cancellation** (negative quantity), **`A` = bad-debt adjustment**. An identifier, not a number. |
# MAGIC | `StockCode` | 5 digits plus an optional letter for variants (`85123A`). Case and spacing vary (`85123a`), so I normalise it. **Non-product codes** exist: `POST`/`DOT` (postage), `M` (manual), `D` (discount), `AMAZONFEE`, `BANK CHARGES`, `B` (bad debt), `TEST001`… |
# MAGIC | `Description` | Product name. On stock-adjustment lines it sometimes holds a note instead (`damaged`, `check`, `?`). |
# MAGIC | `Quantity`, `Price` | Units and unit price in GBP. Line value = Quantity × Price. |
# MAGIC | `InvoiceDate` | Timestamp to the minute. |
# MAGIC | `Customer ID` | 5-digit id; **22.8% missing** (§4e). |
# MAGIC | `Country` | Customer's country (43 values). |
# MAGIC
# MAGIC ### Ingest
# MAGIC SQL can't read `.xlsx`, so this one cell uses Python. It reads **both** sheets, tags each row with its sheet (needed for the overlap check) and keeps every value as text, exactly as received. All typing happens afterwards, in SQL.

# COMMAND ----------

# MAGIC %pip install -q openpyxl

# COMMAND ----------

import pandas as pd

SRC = "/Volumes/synaptiq/online_retail/raw/online_retail_II.xlsx"
COLS = ["invoice", "stock_code", "description", "quantity", "invoice_date", "price", "customer_id", "country"]

# Every value as text, so nothing is coerced on the way in (e.g. Customer ID -> float).
sheets = pd.read_excel(SRC, sheet_name=None, engine="openpyxl", dtype=str)
raw = pd.concat(
    [df.set_axis(COLS, axis=1).assign(source_sheet=name) for name, df in sheets.items()],
    ignore_index=True,
)
print({name: len(df) for name, df in sheets.items()}, "total:", len(raw))

(spark.createDataFrame(raw.astype(object).where(raw.notna(), None))
      .write.mode("overwrite").option("overwriteSchema", "true")
      .saveAsTable("synaptiq.online_retail.transactions_raw"))

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Typed copy. No rows removed: every cleaning decision below is a FLAG, so it can be revisited.
# MAGIC CREATE OR REPLACE TABLE synaptiq.online_retail.transactions
# MAGIC COMMENT 'Online Retail II invoice lines, typed. Grain: one invoice line. Nothing removed.'
# MAGIC AS SELECT
# MAGIC     monotonically_increasing_id()             AS line_id,       -- stable id, used to pair reversals 1:1
# MAGIC     invoice,
# MAGIC     upper(trim(stock_code))                   AS stock_code,    -- '85123a ' and '85123A' are one product
# MAGIC     description,
# MAGIC     try_cast(quantity AS INT)                 AS quantity,
# MAGIC     try_cast(invoice_date AS TIMESTAMP)       AS invoice_ts,
# MAGIC     try_cast(price AS DECIMAL(12,3))          AS price,
# MAGIC     customer_id, country, source_sheet,
# MAGIC     invoice LIKE 'C%'                         AS is_cancellation,
# MAGIC     CAST(try_cast(quantity AS INT) * try_cast(price AS DECIMAL(12,3)) AS DECIMAL(14,2)) AS line_amount
# MAGIC FROM synaptiq.online_retail.transactions_raw;
# MAGIC
# MAGIC -- Parse check: 0 failed casts, and the date range.
# MAGIC SELECT count(*) AS rows, count_if(quantity IS NULL) AS bad_qty, count_if(price IS NULL) AS bad_price,
# MAGIC        count_if(invoice_ts IS NULL) AS bad_ts, min(invoice_ts) AS first_ts, max(invoice_ts) AS last_ts,
# MAGIC        count(DISTINCT invoice) AS invoices, count(DISTINCT customer_id) AS customers, count(DISTINCT country) AS countries
# MAGIC FROM synaptiq.online_retail.transactions;

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Data quality checks
# MAGIC
# MAGIC **What I checked first, and why: the two-sheet structure.** Data split by year often overlaps at the boundary. If it does, every later number is wrong, and nothing else would reveal it.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3a. The sheets' date ranges overlap (sheet 1 ends 9 Dec 2010, sheet 2 starts 1 Dec 2010).
# MAGIC --     Is the overlap a row-for-row copy? EXCEPT ALL compares every column, duplicates included.
# MAGIC WITH s1 AS (SELECT invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
# MAGIC             FROM synaptiq.online_retail.transactions_raw
# MAGIC             WHERE source_sheet = 'Year 2009-2010' AND invoice_date >= '2010-12-01'),
# MAGIC      s2 AS (SELECT invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
# MAGIC             FROM synaptiq.online_retail.transactions_raw
# MAGIC             WHERE source_sheet = 'Year 2010-2011' AND invoice_date < '2010-12-10')
# MAGIC SELECT (SELECT count(*) FROM s1)                         AS sheet1_rows_from_1_dec,
# MAGIC        (SELECT count(*) FROM s2)                         AS sheet2_rows_to_9_dec,
# MAGIC        (SELECT count(*) FROM (SELECT * FROM s1 EXCEPT ALL SELECT * FROM s2)) AS only_in_sheet1,
# MAGIC        (SELECT count(*) FROM (SELECT * FROM s2 EXCEPT ALL SELECT * FROM s1)) AS only_in_sheet2,
# MAGIC        (SELECT count(DISTINCT invoice) FROM s1)          AS invoices,
# MAGIC        (SELECT sum(try_cast(quantity AS INT) * try_cast(price AS DECIMAL(12,3))) FROM s1) AS value_gbp;

# COMMAND ----------

# MAGIC %md
# MAGIC **Result: an exact copy.** All 22,523 rows (1,088 invoices, £377k) match row for row, with nothing in either sheet that isn't in the other. Stacking the sheets naively, as the Kaggle CSV does, counts 1–9 Dec 2010 twice. **Fix:** drop sheet 2's rows before 10 Dec 2010.
# MAGIC
# MAGIC Next, each issue raised in the Kaggle discussion of this dataset, plus the ones I found myself, **re-measured rather than taken on trust**:

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3b. Issue scorecard, measured on all 1,067,371 raw rows.
# MAGIC WITH t AS (SELECT * FROM synaptiq.online_retail.transactions),
# MAGIC dup AS (SELECT sum(c - 1) AS extra_rows FROM (
# MAGIC         SELECT count(*) AS c FROM synaptiq.online_retail.transactions_raw
# MAGIC         GROUP BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
# MAGIC         HAVING count(*) > 1))
# MAGIC SELECT 'Missing customer_id' AS issue,          count_if(customer_id IS NULL) AS rows, round(100 * count_if(customer_id IS NULL) / count(*), 1) AS pct FROM t
# MAGIC UNION ALL SELECT 'Missing description',                count_if(description IS NULL), round(100 * count_if(description IS NULL) / count(*), 2) FROM t
# MAGIC UNION ALL SELECT 'Cancellation lines (C invoices)',    count_if(is_cancellation), round(100 * count_if(is_cancellation) / count(*), 2) FROM t
# MAGIC UNION ALL SELECT 'Negative qty, NOT a C invoice',      count_if(NOT is_cancellation AND quantity < 0), round(100 * count_if(NOT is_cancellation AND quantity < 0) / count(*), 2) FROM t
# MAGIC UNION ALL SELECT 'Price = 0',                          count_if(price = 0), round(100 * count_if(price = 0) / count(*), 2) FROM t
# MAGIC UNION ALL SELECT 'A-invoice (bad-debt) lines',         count_if(invoice LIKE 'A%'), round(100 * count_if(invoice LIKE 'A%') / count(*), 4) FROM t
# MAGIC UNION ALL SELECT 'Exact duplicate rows (all columns)', (SELECT extra_rows FROM dup), round(100 * (SELECT extra_rows FROM dup) / 1067371, 2)
# MAGIC UNION ALL SELECT '  ...of which the sheet overlap',    count_if(source_sheet = 'Year 2010-2011' AND invoice_ts < '2010-12-10'), NULL FROM t;

# COMMAND ----------

# MAGIC %md
# MAGIC | Claim in the Kaggle discussion | Verdict |
# MAGIC |---|---|
# MAGIC | Invoice / StockCode look numeric but are categorical | ✅ The `C`/`A` prefixes and letter suffixes carry meaning. |
# MAGIC | Price and Quantity have zero / negative values | ✅ But they mean **four different things**: cancellations, stock write-offs (`damaged`, `?`), zero-price lines, and bad-debt write-offs (`A` invoices). Each needs its own rule, not one blanket filter. |
# MAGIC | InvoiceDate stored as text | ✅ In pandas. Typed here; every value parses. |
# MAGIC | Customer ID ~22% null; some Description null | ✅ 22.8% and 4,382 rows. The missing IDs are *not* random (§4e). |
# MAGIC | 34,335 duplicates, *"some may be repeated transactions"* | ⚠️ **The count is right, the explanation isn't.** 22,523 are the **sheet overlap**, a data-assembly error. The rest are measured below. |
# MAGIC | Odd descriptions like 'DotCom', 'Manual' | ✅ These are **non-product lines** (postage, manual adjustments, fees). Classified below, not deleted. |
# MAGIC
# MAGIC ### Cleaning rules
# MAGIC Every line gets exactly one `line_type`. Nothing is deleted except the overlap copy.
# MAGIC
# MAGIC One rule needs explaining: **`reversed_within_hour`**. These are sales cancelled by the same customer, for exactly the same amount and product (or through a manual `M` credit), within 60 minutes, matched strictly one-to-one. They're order-entry corrections, not demand. The rule catches the extreme mis-keys shown below, including a £38,970 order reversed through a manual (`M`) credit rather than a product cancellation.

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE VIEW synaptiq.online_retail.transactions_clean
# MAGIC COMMENT 'One copy of each row (sheet overlap removed), each line classified. Base for all analysis.'
# MAGIC AS WITH t AS (
# MAGIC     SELECT * FROM synaptiq.online_retail.transactions
# MAGIC     WHERE NOT (source_sheet = 'Year 2010-2011' AND invoice_ts < '2010-12-10')),    -- drop the overlap copy
# MAGIC -- Same-hour reversals: a sale and a cancellation by the same customer, for the exact opposite amount, on
# MAGIC -- the same product (or via a manual 'M' credit), within 60 minutes. Paired strictly one-to-one: each
# MAGIC -- cancellation takes its nearest preceding sale and each sale its nearest following cancellation.
# MAGIC pairs AS (
# MAGIC     SELECT s.line_id AS sale_id, c.line_id AS cancel_id,
# MAGIC            row_number() OVER (PARTITION BY c.line_id ORDER BY s.invoice_ts DESC, s.line_id) AS rank_for_cancel,
# MAGIC            row_number() OVER (PARTITION BY s.line_id ORDER BY c.invoice_ts, c.line_id)      AS rank_for_sale
# MAGIC     FROM t s JOIN t c
# MAGIC       ON NOT s.is_cancellation AND c.is_cancellation AND s.line_amount > 0
# MAGIC      AND c.customer_id = s.customer_id AND c.line_amount = -s.line_amount
# MAGIC      AND (c.stock_code = s.stock_code OR c.stock_code = 'M')
# MAGIC      AND c.invoice_ts BETWEEN s.invoice_ts AND s.invoice_ts + INTERVAL 60 MINUTES),
# MAGIC reversed AS (
# MAGIC     SELECT sale_id AS line_id FROM pairs WHERE rank_for_cancel = 1 AND rank_for_sale = 1
# MAGIC     UNION ALL
# MAGIC     SELECT cancel_id FROM pairs WHERE rank_for_cancel = 1 AND rank_for_sale = 1)
# MAGIC SELECT t.*,
# MAGIC     CASE
# MAGIC         WHEN invoice LIKE 'A%' THEN 'bad_debt_adjustment'
# MAGIC         WHEN line_id IN (SELECT line_id FROM reversed) THEN 'reversed_within_hour'   -- order-entry corrections, both sides
# MAGIC         WHEN NOT (stock_code RLIKE '^[0-9]{5}[A-Z]{0,2}$' OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'SP%')
# MAGIC                                THEN 'non_product'               -- postage, fees, manual, discounts
# MAGIC         WHEN is_cancellation   THEN 'cancellation'
# MAGIC         WHEN quantity <= 0 OR price <= 0 THEN 'stock_adjustment'  -- write-offs, zero-price lines
# MAGIC         ELSE 'sale'
# MAGIC     END                             AS line_type,
# MAGIC     date_trunc('month', invoice_ts) AS month
# MAGIC FROM t;
# MAGIC
# MAGIC SELECT line_type, count(*) AS lines, round(100 * count(*) / sum(count(*)) OVER (), 2) AS pct_lines,
# MAGIC        sum(line_amount) AS value_gbp, count_if(customer_id IS NULL) AS lines_without_customer
# MAGIC FROM synaptiq.online_retail.transactions_clean
# MAGIC GROUP BY line_type ORDER BY lines DESC;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- The largest same-hour reversals: data-entry events, not demand.
# MAGIC SELECT invoice, invoice_ts, stock_code, description, quantity, price, line_amount, customer_id
# MAGIC FROM synaptiq.online_retail.transactions_clean
# MAGIC WHERE line_type = 'reversed_within_hour'
# MAGIC ORDER BY abs(line_amount) DESC LIMIT 6;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Remaining exact duplicates among sale lines (same invoice, item, minute, qty, price): keep or drop?
# MAGIC SELECT sum(c - 1) AS duplicate_sale_lines, round(sum((c - 1) * amt)) AS their_value_gbp,
# MAGIC        round(100 * sum((c - 1) * amt) / (SELECT sum(line_amount) FROM synaptiq.online_retail.transactions_clean WHERE line_type = 'sale'), 2) AS pct_of_sales
# MAGIC FROM (SELECT count(*) AS c, first(line_amount) AS amt FROM synaptiq.online_retail.transactions_clean
# MAGIC       WHERE line_type = 'sale'
# MAGIC       GROUP BY invoice, stock_code, description, quantity, invoice_ts, price, customer_id HAVING count(*) > 1);

# COMMAND ----------

# MAGIC %md
# MAGIC **Decisions.**
# MAGIC * **`sale` lines = demand.** Ordinary cancellations are reported separately (they don't reference the original invoice, so line-by-line matching would be guesswork).
# MAGIC * **The remaining in-sheet duplicates are kept.** They're 0.3% of sales, and repeated single-unit scans on one invoice are plausible. Dropping them changes no finding.
# MAGIC * **The DQ issues that matter most** are the sheet overlap, the same-hour reversals and the non-random missing customer IDs. Each one changes a conclusion. The rest are housekeeping.
# MAGIC
# MAGIC ## 4. Exploratory analysis
# MAGIC ### 4a. Is the business growing?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Like-for-like 12-month windows (Dec–Nov; Dec 2011 holds only 9 days so it is excluded), split by whether
# MAGIC -- the customer is identified. Change = Y2 vs Y1 in %.
# MAGIC WITH y AS (
# MAGIC     SELECT CASE WHEN customer_id IS NULL THEN 'no customer id (dotcom)' ELSE 'identified customers' END AS segment,
# MAGIC            invoice_ts >= '2010-12-01' AS is_y2, line_amount, quantity, invoice
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND invoice_ts < '2011-12-01')
# MAGIC SELECT coalesce(segment, 'ALL')                                           AS segment,
# MAGIC        round(sum(line_amount) FILTER (WHERE NOT is_y2))                   AS y1_sales,
# MAGIC        round(sum(line_amount) FILTER (WHERE is_y2))                       AS y2_sales,
# MAGIC        round(100 * (sum(line_amount) FILTER (WHERE is_y2) / sum(line_amount) FILTER (WHERE NOT is_y2) - 1), 1) AS sales_chg_pct,
# MAGIC        round(100 * (sum(quantity) FILTER (WHERE is_y2) / sum(quantity) FILTER (WHERE NOT is_y2) - 1), 1)       AS units_chg_pct,
# MAGIC        round(100 * ((sum(line_amount) FILTER (WHERE is_y2) / sum(quantity) FILTER (WHERE is_y2))
# MAGIC                   / (sum(line_amount) FILTER (WHERE NOT is_y2) / sum(quantity) FILTER (WHERE NOT is_y2)) - 1), 1) AS gbp_per_unit_chg_pct,
# MAGIC        round(100 * (count(DISTINCT invoice) FILTER (WHERE is_y2) / count(DISTINCT invoice) FILTER (WHERE NOT is_y2) - 1), 1) AS orders_chg_pct
# MAGIC FROM y
# MAGIC GROUP BY ROLLUP(segment)
# MAGIC ORDER BY segment NULLS FIRST;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Identified customers paid ~9% more per unit. Real price rises, or a shift to pricier items?
# MAGIC -- Same products sold in both years, three standard index methods (they disagree, so I report the range):
# MAGIC --   unit_value:   each product's £/unit (sum £ / sum units), weighted by Y1 units
# MAGIC --   geometric:    same unit values, geometric mean of price relatives weighted by Y1 value share
# MAGIC --   median_price: each product's median line price, weighted by Y1 units (ignores quantity-break mix)
# MAGIC WITH p AS (
# MAGIC     SELECT stock_code,
# MAGIC            sum(quantity) FILTER (WHERE invoice_ts < '2010-12-01')                                                  AS q1,
# MAGIC            sum(line_amount) FILTER (WHERE invoice_ts < '2010-12-01')  / sum(quantity) FILTER (WHERE invoice_ts < '2010-12-01')  AS p1,
# MAGIC            sum(line_amount) FILTER (WHERE invoice_ts >= '2010-12-01') / sum(quantity) FILTER (WHERE invoice_ts >= '2010-12-01') AS p2,
# MAGIC            percentile(price, 0.5) FILTER (WHERE invoice_ts < '2010-12-01')                                           AS m1,
# MAGIC            percentile(price, 0.5) FILTER (WHERE invoice_ts >= '2010-12-01')                                          AS m2
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND customer_id IS NOT NULL AND invoice_ts < '2011-12-01'
# MAGIC     GROUP BY stock_code)
# MAGIC SELECT count(*)                                                     AS products_sold_both_years,
# MAGIC        round(100 * (sum(q1 * p2) / sum(q1 * p1) - 1), 1)            AS unit_value_index_chg_pct,
# MAGIC        round(100 * (exp(sum(q1 * p1 * ln(p2 / p1)) / sum(q1 * p1)) - 1), 1) AS geometric_index_chg_pct,
# MAGIC        round(100 * (sum(q1 * m2) / sum(q1 * m1) - 1), 1)            AS median_price_index_chg_pct,
# MAGIC        round(100 * sum(q1 * p1) / (SELECT sum(line_amount) FROM synaptiq.online_retail.transactions_clean
# MAGIC                                    WHERE line_type = 'sale' AND customer_id IS NOT NULL AND invoice_ts < '2010-12-01'), 1) AS pct_of_y1_value_covered
# MAGIC FROM p WHERE p1 IS NOT NULL AND p2 IS NOT NULL;

# COMMAND ----------

# MAGIC %md
# MAGIC **Flat overall, but not flat underneath.** Identified customers spent 2.8% less: **11% fewer units**, partly offset by 9% more value per unit. Was that price rises? On the same products the answer depends on the method, from about −2% to +5%. Without list prices I can't separate real price rises from quantity-break and discount mix, so I treat the per-unit rise as **mostly mix, cause unproven**. The whole year's growth comes from the unidentified dotcom channel.

# COMMAND ----------

import matplotlib.pyplot as plt

# 24 pre-aggregated rows: safe to bring to the driver for plotting.
m = spark.sql("""
    SELECT month, sum(line_amount) / 1e3 AS sales_k
    FROM synaptiq.online_retail.transactions_clean
    WHERE line_type = 'sale' AND invoice_ts < '2011-12-01'
    GROUP BY month ORDER BY month
""").toPandas()
labels = ["Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
BLUE, ORANGE, INK, MUTED, GRID = "#2a78d6", "#eb6834", "#0b0b0b", "#52514e", "#e6e5e1"

def style(ax, title, ylabel):
    ax.set_title(title, loc="left", fontsize=12, color=INK, pad=12)
    ax.set_ylabel(ylabel, color=MUTED)
    ax.grid(axis="y", color=GRID, linewidth=0.8); ax.set_axisbelow(True)
    for s in ("top", "right", "left"): ax.spines[s].set_visible(False)
    ax.tick_params(colors=MUTED, length=0)

fig, ax = plt.subplots(figsize=(9, 4))
ax.plot(labels, m["sales_k"][:12].values, color=BLUE, linewidth=2, marker="o", markersize=4, label="Y1  Dec 2009 – Nov 2010")
ax.plot(labels, m["sales_k"][12:].values, color=ORANGE, linewidth=2, marker="o", markersize=4, label="Y2  Dec 2010 – Nov 2011")
ax.axvspan(8.5, 11.5, color=GRID, alpha=0.5, zorder=0)
ax.text(10, 120, "Sep–Nov", ha="center", color=MUTED, fontsize=9)
ax.set_ylim(0, None)
ax.legend(loc="upper left", frameon=False, fontsize=9)
style(ax, "Monthly product sales: the same seasonal shape in both years", "£ thousands")
plt.tight_layout(); plt.show()

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT CASE WHEN invoice_ts < '2010-12-01' THEN 'Y1' ELSE 'Y2' END AS year,
# MAGIC        round(100 * sum(line_amount) FILTER (WHERE month(invoice_ts) IN (9, 10, 11)) / sum(line_amount), 1) AS sep_to_nov_pct_of_year
# MAGIC FROM synaptiq.online_retail.transactions_clean
# MAGIC WHERE line_type = 'sale' AND invoice_ts < '2011-12-01'
# MAGIC GROUP BY 1 ORDER BY 1;

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4b. Who buys?

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT country, round(sum(line_amount)) AS sales_gbp,
# MAGIC        round(100 * sum(line_amount) / sum(sum(line_amount)) OVER (), 1) AS pct_sales,
# MAGIC        count(DISTINCT customer_id) AS customers
# MAGIC FROM synaptiq.online_retail.transactions_clean
# MAGIC WHERE line_type = 'sale'
# MAGIC GROUP BY country ORDER BY sales_gbp DESC LIMIT 6;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- The two largest non-UK "markets": how many accounts are they really?
# MAGIC SELECT country, customer_id, sales_gbp, pct_of_country FROM (
# MAGIC     SELECT country, customer_id, round(sum(line_amount)) AS sales_gbp,
# MAGIC            round(100 * sum(line_amount) / sum(sum(line_amount)) OVER (PARTITION BY country), 1) AS pct_of_country,
# MAGIC            row_number() OVER (PARTITION BY country ORDER BY sum(line_amount) DESC) AS rnk
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND country IN ('EIRE', 'Netherlands')
# MAGIC     GROUP BY country, customer_id)
# MAGIC WHERE rnk <= 2 ORDER BY country, sales_gbp DESC;

# COMMAND ----------

# MAGIC %md
# MAGIC The UK is **85%** of sales. The next two "markets" are really **key accounts**: one customer is ~96% of the Netherlands, and two customers are ~92% of EIRE. Losing one of them would look like a whole country disappearing.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 4c. Concentration among identified customers.
# MAGIC WITH c AS (
# MAGIC     SELECT customer_id, sum(line_amount) AS sales, count(DISTINCT invoice) AS orders
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND customer_id IS NOT NULL
# MAGIC     GROUP BY customer_id),
# MAGIC r AS (SELECT *, percent_rank() OVER (ORDER BY sales DESC) AS pr FROM c)
# MAGIC SELECT count(*)                                                          AS customers,
# MAGIC        round(100 * sum(sales) FILTER (WHERE pr < 0.01) / sum(sales), 1) AS top_1pct_share,
# MAGIC        round(100 * sum(sales) FILTER (WHERE pr < 0.10) / sum(sales), 1) AS top_10pct_share,
# MAGIC        round(100 * count_if(orders = 1) / count(*), 1)                  AS one_order_only_pct
# MAGIC FROM r;

# COMMAND ----------

p = spark.sql("""
    WITH c AS (SELECT customer_id, sum(line_amount) AS sales
               FROM synaptiq.online_retail.transactions_clean
               WHERE line_type = 'sale' AND customer_id IS NOT NULL GROUP BY customer_id)
    SELECT row_number() OVER (ORDER BY sales DESC) / count(*) OVER () * 100 AS pct_customers,
           sum(sales) OVER (ORDER BY sales DESC) / sum(sales) OVER () * 100 AS pct_sales
    FROM c
""").toPandas()   # one row per customer (~5.9k): small

fig, ax = plt.subplots(figsize=(6.5, 4))
ax.plot(p["pct_customers"], p["pct_sales"], color=BLUE, linewidth=2)
ax.plot([0, 100], [0, 100], color=MUTED, linewidth=1, linestyle="--")
y10 = p.loc[p["pct_customers"] <= 10, "pct_sales"].max()
ax.scatter([10], [y10], color=BLUE, s=40, zorder=3, edgecolor="white", linewidth=2)
ax.annotate(f"Top 10% of customers\n= {y10:.0f}% of sales", (10, y10), xytext=(18, -6),
            textcoords="offset points", color=INK, fontsize=9)
ax.text(62, 55, "if every customer were equal", color=MUTED, fontsize=8, rotation=33)
style(ax, "Cumulative share of sales by customer (Pareto curve)", "cumulative % of sales")
ax.set_xlabel("cumulative % of customers, largest first", color=MUTED)
plt.tight_layout(); plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4d. Do customers come back, and are new ones arriving?

# COMMAND ----------

# MAGIC %sql
# MAGIC WITH c AS (
# MAGIC     SELECT customer_id,
# MAGIC            min(invoice_ts)                                                AS first_ts,
# MAGIC            max(invoice_ts <  '2010-12-01')                                AS bought_y1,
# MAGIC            max(invoice_ts >= '2010-12-01' AND invoice_ts < '2011-12-01')  AS bought_y2
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND customer_id IS NOT NULL
# MAGIC     GROUP BY customer_id),
# MAGIC y2 AS (
# MAGIC     SELECT customer_id, sum(line_amount) AS y2_sales
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND customer_id IS NOT NULL AND invoice_ts >= '2010-12-01' AND invoice_ts < '2011-12-01'
# MAGIC     GROUP BY customer_id)
# MAGIC SELECT count_if(bought_y1)                                                      AS y1_customers,
# MAGIC        round(100 * count_if(bought_y1 AND bought_y2) / count_if(bought_y1), 1)  AS retention_pct,
# MAGIC        round(100 * sum(y2_sales) FILTER (WHERE first_ts < '2010-12-01') / sum(y2_sales), 1) AS pct_y2_sales_from_y1_customers
# MAGIC FROM c LEFT JOIN y2 USING (customer_id);

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Is new-customer acquisition slowing? Naively, "first purchase ever" looks like it halved. But in Y1
# MAGIC -- "ever" means "since Dec 2009" (the data start), so long-standing customers look new. A fair test gives
# MAGIC -- both years the SAME lookback: count customers whose first purchase within each 12-month window is
# MAGIC -- in Jan–Nov (i.e. not seen in that window's first month).
# MAGIC WITH f AS (
# MAGIC     SELECT customer_id, CASE WHEN invoice_ts < '2010-12-01' THEN 'Y1' ELSE 'Y2' END AS year, min(invoice_ts) AS first_in_window
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     WHERE line_type = 'sale' AND customer_id IS NOT NULL AND invoice_ts < '2011-12-01'
# MAGIC     GROUP BY customer_id, 2),
# MAGIC g AS (SELECT customer_id, min(invoice_ts) AS first_ever FROM synaptiq.online_retail.transactions_clean
# MAGIC       WHERE line_type = 'sale' AND customer_id IS NOT NULL GROUP BY customer_id)
# MAGIC SELECT year,
# MAGIC        count_if(month(first_in_window) <> 12)                                  AS first_seen_jan_nov_equal_lookback,
# MAGIC        count_if(first_in_window = first_ever AND month(first_in_window) <> 12) AS first_purchase_ever_naive
# MAGIC FROM f JOIN g USING (customer_id)
# MAGIC GROUP BY year ORDER BY year;

# COMMAND ----------

# MAGIC %md
# MAGIC **Loyal base: yes.** 64% of year-1 customers bought again, and they produced **83%** of identified year-2 sales.
# MAGIC
# MAGIC **Slowing acquisition: not shown.** The naive count ("first purchase ever") drops from ~3,300 to ~1,500 and looks like a collapse. But with an equal lookback, the number of first-seen customers is *flat* (~3,300 → ~3,400). The naive drop is mostly an artefact of where the data starts. Two years of history can't separate genuinely new customers from returning ones, so I don't report an acquisition trend.
# MAGIC
# MAGIC ### 4e. Who are the customers without an ID?

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT CASE WHEN customer_id IS NULL THEN 'no customer id' ELSE 'has customer id' END AS segment,
# MAGIC        round(sum(line_amount))                                          AS sales_gbp,
# MAGIC        round(100 * sum(line_amount) / sum(sum(line_amount)) OVER (), 1) AS pct_sales,
# MAGIC        count(DISTINCT invoice)                                          AS invoices,
# MAGIC        round(count(*) / count(DISTINCT invoice), 1)                     AS lines_per_invoice,
# MAGIC        round(avg(quantity), 1)                                          AS avg_units_per_line,
# MAGIC        round(avg(price), 2)                                             AS avg_unit_price
# MAGIC FROM synaptiq.online_retail.transactions_clean
# MAGIC WHERE line_type = 'sale'
# MAGIC GROUP BY 1;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Do these invoices carry 'DOTCOM POSTAGE' (stock code DOT)? And how big are they?
# MAGIC SELECT count(*)                                                              AS no_id_invoices,
# MAGIC        count_if(has_dot)                                                     AS with_dotcom_postage,
# MAGIC        round(100 * sum(sales) FILTER (WHERE has_dot) / sum(sales), 1)        AS pct_of_no_id_sales,
# MAGIC        percentile(lines, 0.5) FILTER (WHERE has_dot)                         AS median_lines_per_dotcom_invoice
# MAGIC FROM (SELECT invoice, max(stock_code = 'DOT') AS has_dot,
# MAGIC              sum(line_amount) FILTER (WHERE line_type = 'sale') AS sales, count_if(line_type = 'sale') AS lines
# MAGIC       FROM synaptiq.online_retail.transactions_clean
# MAGIC       WHERE customer_id IS NULL GROUP BY invoice)
# MAGIC WHERE sales > 0;

# COMMAND ----------

# MAGIC %md
# MAGIC The missing-ID rows are **not missing at random**. Most of their value sits on invoices carrying **DOTCOM POSTAGE**, and those invoices have a **median of ~120 lines**. No consumer places a 120-line order, so these look like **batched web orders booked to one invoice**. Two consequences:
# MAGIC * Their "order size" isn't comparable to wholesale orders.
# MAGIC * **Every customer metric in this notebook describes the wholesale side only.**
# MAGIC
# MAGIC ### 4f. What sells?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Ranked by sales after removing same-hour reversals; the second column shows the rank if mis-keys were counted.
# MAGIC WITH g AS (
# MAGIC     SELECT stock_code, max_by(description, invoice_ts) AS description,
# MAGIC            sum(line_amount) FILTER (WHERE line_type = 'sale')                                   AS sales,
# MAGIC            sum(line_amount) FILTER (WHERE line_type IN ('sale', 'reversed_within_hour') AND NOT is_cancellation) AS sales_incl_mis_keys,
# MAGIC            count(DISTINCT customer_id) FILTER (WHERE line_type = 'sale')                        AS customers
# MAGIC     FROM synaptiq.online_retail.transactions_clean
# MAGIC     GROUP BY stock_code),
# MAGIC r AS (SELECT *, row_number() OVER (ORDER BY sales DESC NULLS LAST)               AS sales_rank,
# MAGIC                 row_number() OVER (ORDER BY sales_incl_mis_keys DESC NULLS LAST) AS rank_if_mis_keys_counted
# MAGIC       FROM g)
# MAGIC SELECT sales_rank, rank_if_mis_keys_counted, stock_code, description, round(sales) AS sales_gbp, customers
# MAGIC FROM r
# MAGIC WHERE sales_rank <= 8 OR stock_code = '23843'
# MAGIC ORDER BY sales_rank;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Long tail: how many products make 80% of sales?
# MAGIC WITH p AS (SELECT stock_code, sum(line_amount) AS sales FROM synaptiq.online_retail.transactions_clean
# MAGIC            WHERE line_type = 'sale' GROUP BY stock_code),
# MAGIC r AS (SELECT *, sum(sales) OVER (ORDER BY sales DESC) / sum(sales) OVER () AS cum_share,
# MAGIC              row_number() OVER (ORDER BY sales DESC) AS rnk FROM p)
# MAGIC SELECT count(*) AS products, min(rnk) FILTER (WHERE cum_share >= 0.8) AS products_for_80pct_of_sales,
# MAGIC        round(100 * min(rnk) FILTER (WHERE cum_share >= 0.8) / count(*), 1) AS pct_of_catalogue
# MAGIC FROM r;

# COMMAND ----------

# MAGIC %md
# MAGIC The leaders are durable gift and home items (cake stand, T-light holder, jumbo bags), each bought by **~900–1,500 customers**. "Paper Craft, Little Birdie" would rank **#4** on raw sales from a single mis-keyed order, which is why the reversal rule matters. About **22% of products make 80% of sales**.
# MAGIC
# MAGIC ## 5. Findings and hypotheses
# MAGIC
# MAGIC | # | Finding / hypothesis | Why it matters | Confidence |
# MAGIC |---|---|---|---|
# MAGIC | 1 | **The identified wholesale base is shrinking in volume** (−11% units, −2.8% sales), cushioned by higher value per unit. Total sales look flat (+1.2%) only because the dotcom channel grew 32%. | "Flat" is misleading. The core wholesale business is buying less. | **High** for the volume decline and the channel split. **Low** for *why* value per unit rose: price indices disagree, −2% to +5%. |
# MAGIC | 2 | **Strong Q4 seasonality**: Sep–Nov is 36–38% of the year, identically in both years. | It drives stock, staffing and cash planning. A weak September is an early warning. | **High.** Repeats across two years. |
# MAGIC | 3 | **Revenue is concentrated in a few accounts**: the top 10% of customers bring 63% of sales; the Netherlands and EIRE are 1–2 accounts each. | Key-account churn is the largest single risk. | **High** for identified customers. |
# MAGIC | 4 | **Missing customer IDs mark the dotcom channel** (batched web orders), now the only growing part of the business. | Customer metrics ignore 13% of sales and the growth engine. Fixing the ID capture is a prerequisite for understanding web customers. | **Medium.** Strong behavioural evidence, but no field names the channel. |
# MAGIC | 5 | **Retention is solid** (64% of customers return and drive 83% of identified sales). **An acquisition trend can't be measured** from 2 years of data. | Growth plans should lean on account retention and expansion. Measuring acquisition needs longer history. | Retention: **High**. Acquisition: **not established** (equal-lookback test). |
# MAGIC
# MAGIC **What I trust most:** seasonality and concentration. They're simple counts, stable across both years, and insensitive to every cleaning choice.
# MAGIC **What I trust least:** the channel interpretation of missing IDs (finding 4) and *why* wholesale volume fell (finding 1). Both are inferences the data can suggest but not prove.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Caveats
# MAGIC
# MAGIC * **Only 2 years (+9 days).** One year-on-year comparison can't separate a trend from noise.
# MAGIC * **Left-censoring.** Customer history starts in Dec 2009, so tenure and "new vs returning" are unreliable early on (§4d).
# MAGIC * **Cancellations aren't linked to their original invoices.** Beyond the same-hour reversals, cancellations are reported separately, not netted from the sales they reverse.
# MAGIC * **Revenue = product value** only: no VAT, postage, discounts or fees, and no cost data. So no margin.
# MAGIC * **Price indices cover products sold in both years** (92% of year-1 value), and the three methods disagree (−2% to +5%). Proper attribution needs list prices.
# MAGIC * **`Country` is assumed to be the billing country.** For key accounts it describes one buyer, not a market.
# MAGIC * **The 60-minute reversal window is a judgement call.** Besides the three large mis-keys it catches small same-hour corrections (the `reversed_within_hour` row in the line-type table: two lines per reversal, netting to £0). A wider window would start catching genuine returns.
# MAGIC
# MAGIC ## 7. Recommended next steps (real client project)
# MAGIC
# MAGIC 1. **Validate with the client:** the dotcom/no-ID interpretation, the `M`/`D`/`A` adjustment processes, and how the overlapping sheets were produced.
# MAGIC 2. **Diagnose the wholesale volume decline:** split it into lost accounts vs. smaller orders from retained accounts, and check whether it lines up with the price rises (price elasticity).
# MAGIC 3. **Key-account early warning:** track order intervals for the top ~10% of customers and flag gaps longer than their norm.
# MAGIC 4. **Get the full history plus channel and cost fields**, to measure acquisition properly and move from revenue to margin by channel.
# MAGIC 5. **Productionise the cleaning rules** (overlap, line types, reversals) as one governed table, so every report uses the same definition of a sale.
# MAGIC
# MAGIC ## 8. Use of GenAI
# MAGIC
# MAGIC * **How I used it:** Claude Code as a pair analyst. It drafted the SQL, the ingest and chart code, and first-draft wording, and ran exploratory queries against the warehouse. I then used a **second, independent AI review** of the finished notebook against the brief.
# MAGIC * **Where the AI got it wrong, and how it was caught:**
# MAGIC   1. **Headline growth.**
# MAGIC      * The first draft said "growth came from bigger orders". Splitting by customer type showed the opposite: wholesale down, dotcom up. The draft had also left the mis-keyed orders it had already flagged inside year-2 sales.
# MAGIC      * Its replacement claim, "+4.8% like-for-like price rise", depended on the index method. Three methods give −2% to +5%, so I report the range.
# MAGIC      * Its first reversal rule matched loosely (no same-product check, not one-to-one). It is now a strict 1:1 pairing.
# MAGIC   2. **Acquisition.** The first draft claimed new customers had "slowed sharply" and that a month-by-month comparison avoided the data-start effect. The equal-lookback test (§4d) showed both claims were false.
# MAGIC   3. **Traceability.** The first draft quoted numbers from exploration that weren't in any notebook cell. Each now has a query.
# MAGIC * **What I verified myself:**
# MAGIC   * that this file matches the Kaggle copy. Outside the notebook, I rebuilt the Kaggle CSV from it to the exact byte size (94.85 MB);
# MAGIC   * every Kaggle-discussion claim, re-measured;
# MAGIC   * the sheet overlap, proven row for row (`EXCEPT ALL`), not just by matching totals.
# MAGIC * **What I decided, not the AI:** the definition of a sale, the reversal and duplicate rules, and the confidence ratings.
