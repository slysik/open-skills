---
name: spark-python-data-source
description: Build custom Python data sources for Apache Spark using the PySpark DataSource API — batch and streaming readers/writers for external systems. Use this skill whenever someone wants to connect Spark to an external system (database, API, message queue, custom protocol), build a Spark connector or plugin in Python, implement a DataSourceReader or DataSourceWriter, pull data from or push data to a system via Spark, or work with the PySpark DataSource API in any way. Even if they just say "read from X in Spark" or "write DataFrame to Y" and there's no native connector, this skill applies.
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# spark-python-data-source

Build custom Python data sources for Apache Spark 4.0+ to read from and write to external systems in batch and streaming modes.


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [guide.md](guide.md) | Full instructions: DataSource/DataSourceReader/Writer API, batch + streaming, registration, examples. |

## Example Prompts

```
Create a Spark data source for reading from MongoDB with sharding support
Build a streaming connector for RabbitMQ with at-least-once delivery
Implement a batch writer for Snowflake with staged uploads
Write a data source for REST API with OAuth2 authentication and pagination
```

## Related

- databricks-testing: Test data sources on Databricks clusters
- databricks-spark-declarative-pipelines: Use custom sources in DLT pipelines
- python-dev: Python development best practices

## References

- [implementation-template.md](references/implementation-template.md) — Full annotated skeleton; read when starting a new data source
- [partitioning-patterns.md](references/partitioning-patterns.md) — Read when the source supports parallel reads and you need to split work across executors
- [authentication-patterns.md](references/authentication-patterns.md) — Read when the external system requires credentials or tokens
- [type-conversion.md](references/type-conversion.md) — Read when mapping between Spark types and the external system's type system
- [streaming-patterns.md](references/streaming-patterns.md) — Read when implementing `DataSourceStreamReader` or `DataSourceStreamWriter`
- [error-handling.md](references/error-handling.md) — Read when adding retry logic or handling transient failures
- [testing-patterns.md](references/testing-patterns.md) — Read when writing tests; covers unit, integration, and performance testing
- [production-patterns.md](references/production-patterns.md) — Read when hardening for production: observability, security, input validation
- [Official Databricks Documentation](https://docs.databricks.com/aws/en/pyspark/datasources)
- [Apache Spark Python DataSource Tutorial](https://spark.apache.org/docs/latest/api/python/tutorial/sql/python_data_source.html)
- [awesome-python-datasources](https://github.com/allisonwang-db/awesome-python-datasources) — Directory of community implementations
