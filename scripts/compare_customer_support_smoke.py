#!/usr/bin/env python3
"""Render a cross-platform customer-support smoke-test comparison report."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RESULTS = REPO_ROOT / "reports" / "customer-support-ai" / "raw"
DEFAULT_OUTPUT = REPO_ROOT / "reports" / "customer-support-ai-matrix.md"

PLATFORMS = [
    ("databricks", "Databricks"),
    ("snowflake", "Snowflake"),
    ("microsoft", "Fabric + Foundry"),
]

FEATURES = {
    "Databricks": {
        "data": "Unity Catalog + Delta + SQL Warehouse",
        "ai": "AI Functions",
        "rag": "AI Similarity smoke; Vector Search follows core pass",
        "nlq": "Genie follows core pass",
        "observability": "Query profile, system.billing, MLflow",
    },
    "Snowflake": {
        "data": "Snowflake tables/views + X-Small warehouse",
        "ai": "Cortex AI Functions",
        "rag": "Cortex Search service",
        "nlq": "Cortex Analyst follows core pass",
        "observability": "Query history + Cortex usage history",
    },
    "Fabric + Foundry": {
        "data": "Fabric Warehouse through sqlcmd",
        "ai": "Fabric Warehouse AI Functions",
        "rag": "Foundry vector store + file_search",
        "nlq": "Fabric semantic model/Fabric IQ follows core pass",
        "observability": "Capacity Metrics + Foundry traces",
    },
}


def default_result(platform: str) -> dict[str, Any]:
    return {
        "platform": platform,
        "status": "not_run",
        "duration_seconds": None,
        "cli": "",
        "cli_version": "",
        "tables_created": 0,
        "row_counts": {},
        "ai_rows": 0,
        "evaluation": {"total": 10, "passed": 0},
        "tokens": {"input": None, "output": None, "embedding": None, "cached": None},
        "cost_usd": {"compute": None, "ai": None, "total": None},
        "latency_ms": {"p50": None, "p95": None},
        "errors": [],
        "feature_gaps": ["result file is missing"],
        "notes": [],
        "skills_expected": [],
    }


def read_result(path: Path, platform: str) -> dict[str, Any]:
    if not path.exists():
        return default_result(platform)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        result = default_result(platform)
        result["status"] = "invalid_result"
        result["errors"] = [str(exc)]
        return result
    baseline = default_result(platform)
    baseline.update(data)
    for section in ("evaluation", "tokens", "cost_usd", "latency_ms"):
        merged = default_result(platform)[section]
        merged.update(data.get(section, {}))
        baseline[section] = merged
    return baseline


def value(data: Any, suffix: str = "") -> str:
    if data is None:
        return "not captured"
    if isinstance(data, float):
        return f"{data:,.4f}{suffix}"
    return f"{data}{suffix}"


def joined(items: list[str]) -> str:
    return "<br>".join(items) if items else "none reported"


def completeness(result: dict[str, Any]) -> int:
    status_points = 20 if result["status"] == "passed" else 10 if result["status"] == "dry_run" else 0
    table_points = min(int(result.get("tables_created", 0)), 7) * 4
    evaluation = result.get("evaluation", {})
    total = max(int(evaluation.get("total") or 0), 1)
    eval_points = round(32 * int(evaluation.get("passed") or 0) / total)
    telemetry = [
        result["tokens"].get("input"),
        result["cost_usd"].get("total"),
        result["latency_ms"].get("p95"),
    ]
    telemetry_points = sum(1 for item in telemetry if item is not None) * 6
    return min(status_points + table_points + eval_points + telemetry_points, 100)


def render(results: list[tuple[str, dict[str, Any]]]) -> str:
    now = datetime.now(UTC).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Customer Support AI Smoke-Test Matrix",
        "",
        f"Generated: {now}",
        "",
        "This report compares the same seven-table customer-support workload across "
        "Databricks, Snowflake, and Microsoft Fabric + Foundry. Harnesses are CLI-first, "
        "use REST only where no suitable CLI operation exists, and use no MCP tools.",
        "",
        "## Benchmark",
        "",
        "- Seven deterministic tables and 69 total source rows.",
        "- Eight ticket rows, each enriched with summary, category, and sentiment.",
        "- Six knowledge articles for retrieval.",
        "- Ten evaluation prompts: five structured, four RAG, one answer-quality.",
        "- Cloud runs are intentionally bounded; dry-run results validate command routing only.",
        "",
        "## Execution",
        "",
        "| Platform | Status | CLI/API path | Duration | Tables | AI rows | Eval | Score |",
        "|---|---:|---|---:|---:|---:|---:|---:|",
    ]
    for display_name, result in results:
        evaluation = result["evaluation"]
        lines.append(
            f"| {display_name} | {result['status']} | {result.get('cli') or 'not recorded'} "
            f"| {value(result.get('duration_seconds'), 's')} | {result.get('tables_created', 0)}/7 "
            f"| {result.get('ai_rows', 0)}/8 "
            f"| {evaluation.get('passed', 0)}/{evaluation.get('total', 10)} "
            f"| {completeness(result)}/100 |"
        )

    lines.extend(
        [
            "",
            "## Cost And Tokens",
            "",
            "| Platform | Input tokens | Output tokens | Embedding tokens | Cached tokens | Compute USD | AI USD | Total USD |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for display_name, result in results:
        tokens = result["tokens"]
        cost = result["cost_usd"]
        lines.append(
            f"| {display_name} | {value(tokens.get('input'))} | {value(tokens.get('output'))} "
            f"| {value(tokens.get('embedding'))} | {value(tokens.get('cached'))} "
            f"| {value(cost.get('compute'))} | {value(cost.get('ai'))} "
            f"| {value(cost.get('total'))} |"
        )

    lines.extend(
        [
            "",
            "## Performance",
            "",
            "| Platform | Total duration | P50 latency | P95 latency | Errors |",
            "|---|---:|---:|---:|---|",
        ]
    )
    for display_name, result in results:
        latency = result["latency_ms"]
        lines.append(
            f"| {display_name} | {value(result.get('duration_seconds'), 's')} "
            f"| {value(latency.get('p50'), ' ms')} | {value(latency.get('p95'), ' ms')} "
            f"| {joined(result.get('errors', []))} |"
        )

    lines.extend(
        [
            "",
            "## Feature Coverage",
            "",
            "| Platform | Data/SQL | AI enrichment | RAG | Natural-language SQL | Observability |",
            "|---|---|---|---|---|---|",
        ]
    )
    for display_name, _ in results:
        feature = FEATURES[display_name]
        lines.append(
            f"| {display_name} | {feature['data']} | {feature['ai']} | {feature['rag']} "
            f"| {feature['nlq']} | {feature['observability']} |"
        )

    lines.extend(
        [
            "",
            "## Missing Features And Friction",
            "",
            "| Platform | Feature gaps | Notes | Expected skill routing |",
            "|---|---|---|---|",
        ]
    )
    for display_name, result in results:
        lines.append(
            f"| {display_name} | {joined(result.get('feature_gaps', []))} "
            f"| {joined(result.get('notes', []))} "
            f"| {joined(result.get('skills_expected', []))} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "- `dry_run` proves the local data, CLI dependencies, argument parsing, and result contract.",
            "- `passed` requires cloud object creation, seven loaded tables, bounded AI enrichment, and SQL assertions.",
            "- Cost and token cells remain `not captured` until the platform exposes them to the executing identity.",
            "- A platform should not be ranked on price or latency until all three runs use the same region, model class, and eval set.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    results = [
        (display_name, read_result(args.results_dir / f"{slug}.json", slug))
        for slug, display_name in PLATFORMS
    ]
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(results), encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
