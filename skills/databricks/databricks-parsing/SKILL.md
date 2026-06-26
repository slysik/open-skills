---
name: databricks-parsing
description: "Parse documents (PDF, DOCX, PPTX, images) using ai_parse_document, or build custom RAG pipelines. Use when the user asks to parse documents or build a custom RAG."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Databricks Document Parsing

Parse unstructured documents into structured text using `ai_parse_document` — the foundation for document processing and custom RAG pipelines on Databricks.

## When to Use

Use this skill when:
- Parsing PDFs, DOCX, PPTX, or images into text
- Extracting structured data from unstructured documents
- Building a custom RAG pipeline (parse → chunk → index → query)
- Ingesting documents from Unity Catalog Volumes for search or analysis

## Overview

`ai_parse_document` is a SQL AI function that extracts content from binary documents. It runs on serverless SQL warehouses and supports PDF, DOC/DOCX, PPT/PPTX, JPG/JPEG, and PNG.

| Aspect | Detail |
|--------|--------|
| **Function** | `ai_parse_document(content)` or `ai_parse_document(content, options)` |
| **Input** | Binary document content (from `read_files` with `format => 'binaryFile'`) |
| **Output** | VARIANT with `document.pages[]`, `document.elements[]`, `metadata` |
| **Requirements** | Databricks Runtime 17.1+, Serverless SQL Warehouse |
| **Tool** | Use via `execute_sql` — no dedicated MCP tool needed |

## Quick Start

Parse all documents in a Volume:

```sql
SELECT
  path,
  ai_parse_document(content) AS parsed
FROM read_files('/Volumes/catalog/schema/volume/docs/', format => 'binaryFile');
```

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [patterns.md](patterns.md) | Common patterns: `ai_parse_document` options, batch parsing, chunking, custom RAG pipeline (parse→chunk→index→query), Spark/SQL forms. |

## Output Schema

`ai_parse_document` returns a VARIANT with this structure:

```
document
├── pages[]          -- page id, image_uri
└── elements[]       -- extracted content
    ├── type         -- "text", "table", "figure", etc.
    ├── content      -- extracted text
    ├── bbox         -- bounding box coordinates
    └── description  -- AI-generated description
metadata             -- file info, schema version
error_status[]       -- errors per page (if any)
```

## Common Issues

| Issue | Solution |
|-------|----------|
| **Function not available** | Requires Runtime 17.1+ and Serverless SQL Warehouse |
| **Region not supported** | US/EU regions, or enable cross-geography routing |
| **Large documents** | Use `LIMIT` during development to control costs |
| **`explode()` fails with VARIANT** | `explode()` requires ARRAY, not VARIANT. Use `variant_get(doc, '$.document.elements', 'ARRAY<VARIANT>')` to cast before exploding |
| **Short/noisy chunks** | Filter with `length(trim(...)) > 10` — parsing produces tiny fragments (page numbers, headers) that pollute the index |
| **`ai_query` returns markdown fences** | Use `returnType => 'STRING'` for clean output. If fences still appear, strip with `regexp_replace(result, '```(json)?\\s*|```', '')` |
| **Re-parsing unchanged documents** | Use Structured Streaming with checkpoints — see Pattern 3, Step 1a |

## Related Skills

- **[databricks-vector-search](../databricks-vector-search/SKILL.md)** — Create indexes and query embeddings (Step 2 of RAG)
- **[databricks-agent-bricks](../databricks-agent-bricks/SKILL.md)** — Pre-built Knowledge Assistants (out-of-the-box RAG without custom parsing)
- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** — Production pipelines for batch document processing
- **[databricks-dbsql](../databricks-dbsql/SKILL.md)** — Full AI functions reference including `ai_query`, `ai_extract`, `ai_classify`
