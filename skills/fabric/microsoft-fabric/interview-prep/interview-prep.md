# Senior Microsoft Fabric Data Engineer — Interview Prep & Team Standards

This guide maps the requirements of the job description directly to technical
narratives, architectural decisions, and situational "tough questions" you can expect
in a Senior interview.

---

## 1. Direct Job Description Mapping & Talking Points

| JD Requirement | Senior-Level Narrative / Talking Points |
|---|---|
| **Design pipelines to ingest from SQL Server & REST APIs** | "I design **metadata-driven pipelines** using a control-table architecture. Instead of 50 pipelines, I build 1 master pipeline that loops over a JSON configuration to fetch parameters, run lookups, dynamically build the SQL queries using a watermark, and execute the copy activities." |
| **Build and maintain Medallion architecture** | "Bronze is strictly **append-only** to preserve raw data history, stamped with a pipeline `RunId` and ingestion metadata. Silver is where we run **Delta MERGE** operations to deduplicate and clean. Gold tables are modeled as a **Star Schema** to provide optimal performance for Power BI semantic models in DirectLake mode." |
| **Develop PySpark notebooks for transformation** | "I enforce strict notebook standards: parameter cells are tagged for overrides, all custom imports are standardized, and notebooks must use `mssparkutils.notebook.exit()` to return programmatic JSON back to the pipeline to control downstream execution paths." |
| **Incremental strategies (Watermarking, CDC)** | "For high-volume tables, I implement SQL Server Change Data Capture (CDC) with LSN binary watermarks. For standard tables, I use timestamp-based watermarks stored in a centralized control table to drive incremental pulls." |
| **Diagnose and resolve pipeline issues** | "I classify failures into four classes: Auth (Entra SP expiration), Network (gateway drops), Data (schema drift), and Capacity. I implement built-in retries, and when a failure occurs, we leverage 'Rerun from failed activity' after performing any manual cleanup." |
| **Pipeline logging & monitoring framework** | "We don't rely on the portal alone. I design an automated failure-handling branch on all pipelines to log errors directly to a central SQL control table (`ctl.pipeline_errors`) and immediately ping the on-call team via Teams webhook or Outlook." |
| **Manage Fabric workspace capacity** | "I actively monitor capacity using the **Fabric Capacity Metrics App**. I manage background compute debt by setting Spark pool keep-alive times to 2 minutes, using high-concurrency pools, and staggering pipeline schedules to prevent concurrent spikes." |
| **CI/CD deployment with Git (Dev, Test, Prod)** | "I establish Git integration on the Dev workspace, using feature branches to allow engineers to build in isolated personal workspaces. We use **Fabric Deployment Pipelines** with deployment rules to promote items and auto-rewrite connections and parameters." |
| **Mentor junior team members** | "I establish clear code-review templates, PR checklists, and design-pattern runbooks to help junior developers transition from ADF to Fabric while maintaining high-quality code." |

---

## 2. Tricky Architectural Questions & Answers

### Q1: "We are getting a `DeltaConcurrentAppendException` when our pipeline runs. What is causing this, and how would you fix it?"
* **The Cause:** "This occurs in Delta Lake because of **optimistic concurrency control**. Two different spark sessions or pipeline runs are attempting to write to the exact same Delta table partition at the same time. Even if they are appending different rows, Delta thinks a collision might occur and aborts one of the transactions."
* **The Fix:** 
  1. "If the runs don't need to be parallel, I serialize them by setting the pipeline `concurrency` property to `1`."
  2. "If they must run in parallel, I ensure the table is partitioned (e.g., by `load_date` or `region`) and that each write operation contains a strict partition filter predicate, allowing Delta to realize the writes are non-overlapping."
  3. "Lastly, I add an optimistic retry policy (e.g., `retry: 5`, `retryIntervalInSeconds: 30`) on the notebook or script activity doing the merge, which gracefully resolves most collisions."

### Q2: "When should we use a Fabric Warehouse versus a Fabric Lakehouse? How would you explain the difference to a junior developer?"
* **The Explanation:**
  - **Lakehouse:** "Think of it as a **code-first, open-format** store. It supports files, folders, and Delta tables. It's built for PySpark engineers, machine learning workloads, and highly customized data engineering. It supports ACID transactions via Delta Lake but is managed with Python/Scala code."
  - **Warehouse:** "Think of it as a **SQL-first, traditional relational** warehouse experience. It fully supports standard T-SQL (DDL/DML like `CREATE TABLE`, `INSERT`, `UPDATE`), multi-table transactions, and primary/foreign keys (enforced for statistics). Everything in it is stored as Delta/Parquet on OneLake under the hood, but engineers manage it completely using SQL."
  - **The Guideline:** "Use Lakehouse for unstructured/semi-structured data, high-scale Python ingestion, and data science. Use Warehouse for structured dimensional modeling, SQL-heavy BI teams, and strict multi-table transaction requirements."

### Q3: "Our business users are complaining that their Power BI reports are loading slowly at 9:00 AM. How do you investigate this using Fabric tools?"
* **The Investigation:**
  1. "First, I would check if the Power BI semantic models are connected to our Lakehouse/Warehouse via **DirectLake** mode or **Import** mode. If it's Import mode, a massive refresh might be running at 9 AM, hogging all the memory. If it's DirectLake, the model reads directly from OneLake Parquet files, which shouldn't spike memory unless there is massive schema paging."
  2. "Second, I would open the **Fabric Capacity Metrics App** and drill down to the 9:00 AM window. I would analyze the **Interactive VS Background** split. If Interactive CUs are spiking, it's caused by concurrent report views. If Background CUs are spiking, it means our ETL pipelines are running too late into the morning and overlapping with business hours."
  3. "If ETL is the culprit, I would stagger the schedules or scale up the capacity temporarily during that window using Azure CLI."

### Q4: "How does Fabric connect securely to our on-premises SQL Server databases without opening public firewalls?"
* **The Security Path:**
  1. "We install the Microsoft **On-premises Data Gateway** on a VM inside the on-premises network that has local access to the SQL Server."
  2. "The gateway establishes an outbound encrypted connection to the Azure Service Bus, meaning we do not need to open any inbound ports on our corporate firewall."
  3. "In the Fabric Portal, we register the gateway, and then create a new **Gateway Connection** using Windows or SQL Authentication."
  4. "Inside our Fabric Pipeline, we set the source connection of the Copy Activity to this Gateway Connection. Fabric automatically routes the copy job's execution payload through the secure outbound connection."

---

## 3. How to Conduct a Fabric Code Review (Standards)

As a Senior, you set the quality bar. Here are the templates you should use during PR reviews.

### 3.1 What to reject in a Data Pipeline PR:
* [ ] **Hardcoded connection strings or credentials:** All connections must use Fabric Workspace Connections or Azure Key Vault references.
* [ ] **No retry policy on network activities:** Reject any Web, Copy, or Script activity with `retry: 0` unless it is explicitly non-idempotent.
* [ ] **Missing error pathways:** Reject pipelines where a failure in the main copy branch just silently dies without triggering an alert or logging to `ctl.pipeline_errors`.
* [ ] **Lack of `concurrency` setting:** Orchestrator/master pipelines that process sequential increments must be pinned to `concurrency: 1`.

### 3.2 What to reject in a Notebook PR:
* [ ] **Absence of a `parameters` cell:** Reject notebooks that hardcode date filters or file paths instead of using parameterized inputs.
* [ ] **Expensive data collection:** Look for `df.collect()`, `df.toPandas()`, or `.show(1000)` on production dataframes. These action calls pull all data to the driver node and cause Out-Of-Memory (OOM) crashes.
* [ ] **Over-repetition of Spark joins:** Look for notebooks that read and join the same large dimension table multiple times in different cells. The table should be read once, joined once, or broadcast-joined if small enough.
* [ ] **Ad-hoc `%pip install`:** Production notebooks should use environment-scoped library management (Workspace settings → Environment) to prevent installing packages during pipeline execution.

---

## 4. Architectural Blueprint: The Medallion Standard

```
  [ Source: SQL / API ]
          │
          │  Copy Activity (Stamps _ingest_run_id)
          ▼
   ┌───────────────┐
   │ BRONZE Layer  │ ── Delta tables containing raw append-only history.
   └───────┬───────┘    No cleaning, no deletions.
           │
           │  PySpark Notebook (Delta MERGE + Partitioning)
           ▼
   ┌───────────────┐
   │ SILVER Layer  │ ── Cleaned, structured, deduped Delta tables.
   └───────┬───────┘    Data conforms to corporate schemas and types.
           │
           │  SQL Views / Stored Procedures (Star Schema)
           ▼
   ┌───────────────┐
   │  GOLD Layer   │ ── Fact and Dimension tables ready for business users.
   └───────────────┘    Accessed via DirectLake by Power BI. Zero import delay.
```
