---
name: databricks-unstructured-pdf-generation
description: "Generate PDF documents from HTML and upload to Unity Catalog volumes. Use for creating test PDFs, demo documents, reports, or evaluation datasets."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# PDF Generation from HTML

Convert HTML content to PDF documents and upload them to Unity Catalog Volumes.

## Overview

The `generate_and_upload_pdf` MCP tool converts HTML to PDF and uploads to a Unity Catalog Volume. You (the LLM) generate the HTML content, and the tool handles conversion and upload.

## Tool Signature

```
generate_and_upload_pdf(
    html_content: str,      # Complete HTML document
    filename: str,          # PDF filename (e.g., "report.pdf")
    catalog: str,           # Unity Catalog name
    schema: str,            # Schema name
    volume: str = "raw_data",  # Volume name (default: "raw_data")
    folder: str = None,     # Optional subfolder
)
```

**Returns:**
```json
{
    "success": true,
    "volume_path": "/Volumes/catalog/schema/volume/filename.pdf",
    "error": null
}
```

## Quick Start

Generate a simple PDF:

```
generate_and_upload_pdf(
    html_content='''<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #1a73e8; border-bottom: 2px solid #1a73e8; padding-bottom: 10px; }
        .section { margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Quarterly Report Q1 2024</h1>
    <div class="section">
        <h2>Executive Summary</h2>
        <p>Revenue increased 15% year-over-year...</p>
    </div>
</body>
</html>''',
    filename="q1_report.pdf",
    catalog="my_catalog",
    schema="my_schema"
)
```

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/html-guide.md](references/html-guide.md) | Parallel multi-PDF generation, **HTML best practices**, common patterns (reports, tables, styling), and the multi-document workflow. |

## Prerequisites

- Unity Catalog schema must exist
- Volume must exist (default: `raw_data`)
- User must have WRITE permission on the volume

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Volume does not exist" | Create the volume first or use an existing one |
| "Schema does not exist" | Create the schema or check the name |
| PDF looks wrong | Check HTML/CSS syntax, use supported CSS features |
| Slow generation | Call multiple PDFs in parallel, not sequentially |
