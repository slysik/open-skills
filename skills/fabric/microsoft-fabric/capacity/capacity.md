# Microsoft Fabric — Capacity Management & Job Scheduling

Fabric is a SaaS platform. You do not manage virtual machines or Spark clusters;
instead, you buy a dedicated slice of compute called **Fabric Capacity** (measured in
**Capacity Units (CUs)** and provisioned via Azure **F SKUs** from F2 to F2048).

A Senior Fabric Data Engineer is responsible for keeping workloads within the
purchased capacity, optimizing resource-intensive notebooks, and scheduling
jobs to prevent throttling.

---

## 1. How Fabric Compute Bill Works: The Core Concepts

Understanding the billing model is key to designing cost-effective pipelines:

| Metric | What it means | Notes |
|---|---|---|
| **Capacity Units (CUs)** | The raw horsepower of your capacity. | An F2 capacity has 2 CUs; an F64 has 64 CUs. |
| **Interactive Operations** | Power BI report renders, SQL queries, ad-hoc Notebook runs. | Smoothed over a **5-minute window**. If you burst, you're throttled quickly. |
| **Background Operations** | Scheduled Pipelines, Dataflows Gen2, Notebook activities. | Smoothed over a **24-hour window**. You can burst high, and Fabric averages it out. |
| **Smoothing** | Spreading a compute-heavy burst over time. | If a PySpark notebook runs for 10 minutes and uses 64 CUs on an F32 capacity, Fabric spreads that cost over 24 hours so you don't hit the ceiling. |
| **Overages** | Accumulating more compute debt than your capacity can clear. | When you carry an overage, your background jobs start getting queued or delayed. |

---

## 2. Throttling: The Three Stages of Pain

When your workspace consumes more CUs than your capacity provides, Fabric applies throttling in three distinct phases:

```
 CU% Consumption ───►  100%  ──────────────►  150%  ──────────────►  200%
                       │                       │                       │
 Throttling Phase:   [ 1. Interactive Delay ] [ 2. Interactive Reject] [ 3. Background Reject ]
                     Queries feel sluggish     Web UI shows 429s       Pipelines fail instantly
```

1. **Interactive Delay (100% CU Limit Exceeded):**
   - Fabric artificially delays interactive operations (e.g., rendering a report takes 10s instead of 1s) to force consumption down.
2. **Interactive Rejection (150% CU Limit Exceeded):**
   - Interactive requests fail immediately with a `429 Too Many Requests` error. Users cannot edit reports or run query previews.
3. **Background Rejection (200% CU Limit Exceeded):**
   - Active pipelines fail, schedules are skipped, and background jobs are outright rejected.

---

## 3. Troubleshooting Capacity Overruns

The primary tool for diagnosing issues is the **Microsoft Fabric Capacity Metrics App** (downloadable from the Power BI App source).

### How to Triage an Overrun in the Metrics App:

1. **Check the Multi-Metric Ribbon:**
   - Look at **CU %** and **Overage %**. If CU % is consistently above 100%, you are over-provisioned.
2. **Identify the Culprit (The "Drill Down" Page):**
   - Sort items by **Total CU (s)**.
   - Look for the operation type:
     - `Lakehouse` (Spark jobs, PySpark Notebooks).
     - `Warehouse` (T-SQL queries).
     - `Dataflow` (Power Query Mashup engines are notoriously CU-heavy).
3. **Analyze Background vs. Interactive:**
   - If a background job (e.g., `Notebook_Aggregate_Sales`) has a massive peak but is smoothed out, that's fine.
   - If multiple background jobs run *simultaneously*, they stack up and trigger a background rejection.

---

## 4. Job Scheduling Strategies to Prevent Throttling

To prevent capacity overruns without spending more money on a larger SKU, implement these four scheduling patterns:

### Pattern A: The Staggered Window (Avoid the Midnight Peak)
Most data engineers schedule all pipelines to run at exactly midnight UTC. This creates a massive compute cliff. **Stagger your schedules**:

```
 23:00 UTC ────────────────► [ Ingest ERP System ] (Pipeline A)
 23:30 UTC ────────────────► [ Ingest CRM System ] (Pipeline B)
 00:00 UTC ────────────────► [ Run Bronze-to-Silver PySpark Notebook ] (Notebook C)
 01:00 UTC ────────────────► [ Run Silver-to-Gold Aggregations ] (Notebook D)
```

### Pattern B: Limit Spark Pool Concurrency and Keep-Alive Times
By default, Fabric keeps Spark sessions alive for **20 minutes** after a notebook completes. During this time, those nodes are reserved and consuming idle CUs.

- Set **Auto-Shutdown** to **2 minutes** in Workspace Settings → **Spark settings** → **Automatic shutdown**.
- Use **High-concurrency pools** so multiple notebooks can share the same active executors, rather than spinning up separate nodes for every activity.

### Pattern C: Turn off "Enable Interactive Preview" in Dataflows Gen2
Dataflows Gen2 write data using staging Lakehouses. This generates significant write IO and Spark compute.
- For heavy pipelines, prefer **Copy Activity** (lightweight, highly optimized background operation) over **Dataflows Gen2** whenever possible.

### Pattern D: Programmatic Pausing for Non-Production
Development and testing capacities do not need to run 24/7. Use Azure CLI in an automation script to pause capacities outside of business hours:

```bash
# Pause dev capacity at 6 PM EST
az fabric capacity suspend \
  --resource-group rg-fabric-dev \
  --capacity-name fab-cap-dev

# Resume dev capacity at 7 AM EST
az fabric capacity resume \
  --resource-group rg-fabric-dev \
  --capacity-name fab-cap-dev
```
*Note: Pausing an F SKU stops the Azure billing meter completely.*

---

## 5. Capacity Management Checklist for Notebooks

When writing notebooks, implement these Senior-level performance safeguards to minimize CU usage:

- [ ] **Avoid long-running loops:** Never loop through thousands of files using Python `for` loops. Use `spark.read.format("parquet").load("abfss://.../*.parquet")` to read all files in parallel.
- [ ] **Partition Pruning:** Always include partition columns in `WHERE` clauses so Spark doesn't read the entire table.
- [ ] **Coalesce/Repartition intelligently:** Don't write 5,000 tiny 2KB files. Use `df.coalesce(1)` or `df.repartition(10)` before writing to merge small partitions.
- [ ] **Do not use `df.count()` for control flow:** Running `df.count()` forces Spark to scan the entire dataframe. Use `df.take(1)` or check the schema if you only need to verify if data exists.
- [ ] **Cache selectively:** Only use `.persist()` or `.cache()` if the dataframe is evaluated multiple times in downstream cells, and always `.unpersist()` when done.
