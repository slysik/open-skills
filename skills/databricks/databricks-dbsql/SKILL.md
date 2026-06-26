---
name: databricks-dbsql
description: >-
  Databricks SQL (DBSQL) advanced features and SQL warehouse capabilities.
  This skill MUST be invoked when the user mentions: "DBSQL", "Databricks SQL",
  "SQL warehouse", "SQL scripting", "stored procedure", "CALL procedure",
  "materialized view", "CREATE MATERIALIZED VIEW", "pipe syntax", "|>",
  "geospatial", "H3", "ST_", "spatial SQL", "collation", "COLLATE",
  "ai_query", "ai_classify", "ai_extract", "ai_gen", "AI function",
  "http_request", "remote_query", "read_files", "Lakehouse Federation",
  "recursive CTE", "WITH RECURSIVE", "multi-statement transaction",
  "temp table", "temporary view", "pipe operator".
  SHOULD also invoke when the user asks about SQL best practices, data modeling
  patterns, or advanced SQL features on Databricks.
---

# Databricks SQL (DBSQL) - Advanced Features

## Quick Reference

| Feature | Key Syntax | Since | Reference |
|---------|-----------|-------|-----------|
| SQL Scripting | `BEGIN...END`, `DECLARE`, `IF/WHILE/FOR` | DBR 16.3+ | [sql-scripting.md](sql-scripting.md) |
| Stored Procedures | `CREATE PROCEDURE`, `CALL` | DBR 17.0+ | [sql-scripting.md](sql-scripting.md) |
| Recursive CTEs | `WITH RECURSIVE` | DBR 17.0+ | [sql-scripting.md](sql-scripting.md) |
| Transactions | `BEGIN ATOMIC...END` | Preview | [sql-scripting.md](sql-scripting.md) |
| Materialized Views | `CREATE MATERIALIZED VIEW` | Pro/Serverless | [materialized-views-pipes.md](materialized-views-pipes.md) |
| Temp Tables | `CREATE TEMPORARY TABLE` | All | [materialized-views-pipes.md](materialized-views-pipes.md) |
| Pipe Syntax | `\|>` operator | DBR 16.1+ | [materialized-views-pipes.md](materialized-views-pipes.md) |
| Geospatial (H3) | `h3_longlatash3()`, `h3_polyfillash3()` | DBR 11.2+ | [geospatial-collations.md](geospatial-collations.md) |
| Geospatial (ST) | `ST_Point()`, `ST_Contains()`, 80+ funcs | DBR 16.0+ | [geospatial-collations.md](geospatial-collations.md) |
| Collations | `COLLATE`, `UTF8_LCASE`, locale-aware | DBR 16.1+ | [geospatial-collations.md](geospatial-collations.md) |
| AI Functions | `ai_query()`, `ai_classify()`, 11+ funcs | DBR 15.1+ | [ai-functions.md](ai-functions.md) |
| http_request | `http_request(conn, ...)` | Pro/Serverless | [ai-functions.md](ai-functions.md) |
| remote_query | `SELECT * FROM remote_query(...)` | Pro/Serverless | [ai-functions.md](ai-functions.md) |
| read_files | `SELECT * FROM read_files(...)` | All | [ai-functions.md](ai-functions.md) |
| Data Modeling | Star schema, Liquid Clustering | All | [best-practices.md](best-practices.md) |

---


## Reference Files

Load these for detailed syntax, full parameter lists, and advanced patterns:

| File | Contents | When to Read |
|------|----------|--------------|
| [patterns.md](patterns.md) | Common patterns: scripting, MVs, geospatial, AI funcs, federation, CTEs, transactions (full inline set) | Need a worked example fast |
| [sql-scripting.md](sql-scripting.md) | SQL Scripting, Stored Procedures, Recursive CTEs, Transactions | Procedural SQL, error handling, loops, dynamic SQL |
| [materialized-views-pipes.md](materialized-views-pipes.md) | Materialized Views, Temp Tables/Views, Pipe Syntax | MVs, refresh scheduling, temp objects, pipe operator |
| [geospatial-collations.md](geospatial-collations.md) | 39 H3 functions, 80+ ST functions, Collation types | Spatial analysis, H3 indexing, case/accent handling |
| [ai-functions.md](ai-functions.md) | 13 AI functions, http_request, remote_query, read_files | AI enrichment, API calls, federation, file ingestion |
| [best-practices.md](best-practices.md) | Data modeling, performance, Liquid Clustering, anti-patterns | Architecture, optimization, modeling advice |

## Key Guidelines

- **Always use Serverless SQL warehouses** for AI functions, MVs, and http_request
- **Use `LIMIT` during development** with AI functions to control costs
- **Prefer Liquid Clustering over partitioning** for new tables (1-4 keys max)
- **Use `CLUSTER BY AUTO`** when unsure about clustering keys
- **Star schema in Gold layer** for BI; OBT acceptable in Silver
- **Define PK/FK constraints** on dimensional models for query optimization
- **Use `COLLATE UTF8_LCASE`** for user-facing string columns that need case-insensitive search
- **Use MCP tools** (`execute_sql`, `execute_sql_multi`) to test and validate all SQL before deploying
