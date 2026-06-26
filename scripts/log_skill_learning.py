#!/usr/bin/env python3
"""Append sanitized skill-usage learnings to a local JSONL event log."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_LOG = Path.home() / ".local" / "state" / "open-skills" / "skill-learnings.jsonl"
SCHEMA_VERSION = "1.0"

SECRET_PATTERNS = [
    (
        re.compile(r"(?i)\b(password|passwd|pwd|secret|token|api[_-]?key|client_secret|pat)\b\s*[:=]\s*['\"]?[^'\"\s,;]+"),
        r"\1=<redacted>",
    ),
    (re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._~+/=-]+"), "Bearer <redacted>"),
    (re.compile(r"\bsk-[A-Za-z0-9]{16,}\b"), "sk-<redacted>"),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def redact_text(value: str | None) -> str:
    if not value:
        return ""
    redacted = value
    for pattern, replacement in SECRET_PATTERNS:
        redacted = pattern.sub(replacement, redacted)
    return redacted


def build_id(record: dict[str, object]) -> str:
    material = "|".join(
        str(record.get(key, "")) for key in ("timestamp_utc", "skill", "event", "summary")
    )
    return hashlib.sha256(material.encode("utf-8")).hexdigest()[:16]


def build_record(args: argparse.Namespace) -> dict[str, object]:
    record: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "timestamp_utc": utc_now(),
        "skill": args.skill,
        "event": args.event,
        "severity": args.severity,
        "summary": redact_text(args.summary),
        "detail": redact_text(args.detail),
        "source_task": redact_text(args.source_task),
        "artifacts": [redact_text(item) for item in args.artifact],
        "agent": args.agent or os.environ.get("USER", "unknown"),
        "status": "candidate",
    }
    record["id"] = build_id(record)
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill", required=True, help="skill name or folder, for example databricks-genie")
    parser.add_argument("--event", default="learning", choices=["learning", "failure", "friction", "success", "suggestion"])
    parser.add_argument("--severity", default="medium", choices=["low", "medium", "high"])
    parser.add_argument("--summary", required=True, help="short reusable learning")
    parser.add_argument("--detail", default="", help="supporting detail without secrets or customer-specific data")
    parser.add_argument("--source-task", default="", help="sanitized task shape that produced the learning")
    parser.add_argument("--artifact", action="append", default=[], help="sanitized related artifact path or URL; repeatable")
    parser.add_argument("--agent", default="", help="optional agent/runtime name")
    parser.add_argument("--out", type=Path, default=DEFAULT_LOG, help=f"JSONL output path (default: {DEFAULT_LOG})")
    parser.add_argument("--dry-run", action="store_true", help="print the record without writing")
    args = parser.parse_args()

    record = build_record(args)
    line = json.dumps(record, ensure_ascii=False, sort_keys=True)
    if args.dry_run:
        print(line)
        return 0

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")
    print(f"logged {record['id']} to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
