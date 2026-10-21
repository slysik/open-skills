#!/usr/bin/env python3
"""Offline helper for Fabric Ontology definitions (generation 2 / TMDL layout).

No network calls. Python 3.9+ standard library only.

Commands
  unpack  <envelope.json> <dir>   decode a getDefinition response or definition envelope into a part tree
  pack    <dir> [-o file]         encode a part tree into {"definition": {"parts": [...]}} (InlineBase64)
  check   <dir|envelope.json>     static checks against the documented layout and TMDL indentation rules
  detect  <dir|envelope.json>     print "generation-2-tmdl", "generation-1-json" or "unknown" from the part layout

What `check` covers (all offline, so it cannot prove the service will accept a payload):
  * required parts (.platform, database.tmdl), .platform type Ontology
  * allowed part paths, forward slashes only, entity file names `namespace#name.tmdl`
  * TMDL single-tab indentation rule (space indentation is a parse error per the TMDL overview)
  * explicit metrics with a DAX dialect (Learn ontology-definition page, error ExplicitMetricDaxNotAllowed;
    that page's error table was only partly read, so this rule is marked unverified)
  * documented size limits that are cheap to test
Sources: Microsoft Learn ontology-definition (2026-09-10) and TMDL overview (analysis-services/tmdl).
"""

from __future__ import annotations

import argparse
import base64
import json
import re
import sys
from pathlib import Path

ALLOWED_PATTERNS = [
    r"^\.platform$",
    r"^database\.tmdl$",
    r"^model\.tmdl$",
    r"^expressions\.tmdl$",
    r"^relationships\.tmdl$",
    r"^entityRelationships\.tmdl$",
    r"^namespaces/[^/#]+\.tmdl$",
    r"^tables/[^/#]+\.tmdl$",
    r"^metrics/[^/#]+\.tmdl$",
    r"^rules/[^/#]+\.tmdl$",
    r"^entities/(?:[^/#]+#)?[^/#]+\.tmdl$",
]
LEGACY_PREFIXES = ("EntityTypes/", "RelationshipTypes/")
TOP_LEVEL_OBJECTS = (
    "database", "model", "table", "entity", "entityRelationship", "rule",
    "namespace", "metric", "expression", "relationship", "ref",
)
NAME_LIMIT = 512
DESCRIPTION_LIMIT = 4000


def _load_parts(src: Path) -> dict[str, bytes]:
    """Return {path: bytes} from a directory tree or a JSON envelope file."""
    if src.is_dir():
        parts = {}
        for f in sorted(src.rglob("*")):
            if f.is_file():
                parts[f.relative_to(src).as_posix()] = f.read_bytes()
        return parts
    doc = json.loads(src.read_text(encoding="utf-8"))
    definition = doc.get("definition", doc)
    parts = {}
    for p in definition.get("parts", []):
        if p.get("payloadType") != "InlineBase64":
            raise ValueError(f"unsupported payloadType for {p.get('path')}: {p.get('payloadType')}")
        parts[p["path"]] = base64.b64decode(p["payload"])
    return parts


def detect_generation(parts: dict[str, bytes]) -> str:
    paths = list(parts)
    if any(p.startswith(LEGACY_PREFIXES) for p in paths):
        return "generation-1-json"
    if "database.tmdl" in parts or any(p.endswith(".tmdl") for p in paths):
        return "generation-2-tmdl"
    return "unknown"


def check_parts(parts: dict[str, bytes]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    gen = detect_generation(parts)
    if gen == "generation-1-json":
        warnings.append("legacy generation 1 (JSON tree) layout: TMDL rules not applied")
        return errors, warnings
    for required in (".platform", "database.tmdl"):
        if required not in parts:
            errors.append(f"missing required part: {required}")
    for path in parts:
        if "\\" in path:
            errors.append(f"backslash in part path (use forward slashes): {path}")
        if not any(re.match(pat, path) for pat in ALLOWED_PATTERNS):
            errors.append(f"part path not in the documented layout: {path}")
    if ".platform" in parts:
        try:
            plat = json.loads(parts[".platform"].decode("utf-8"))
            if plat.get("metadata", {}).get("type") != "Ontology":
                errors.append(".platform metadata.type must be 'Ontology'")
            if plat.get("config", {}).get("version") != "2.0":
                warnings.append(".platform config.version is not '2.0'")
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            errors.append(f".platform is not valid JSON: {exc}")
    for path, raw in parts.items():
        if not path.endswith(".tmdl"):
            continue
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"{path}: not UTF-8")
            continue
        _check_tmdl(path, text, errors, warnings)
    return errors, warnings


def _check_tmdl(path: str, text: str, errors: list[str], warnings: list[str]) -> None:
    in_backticks = False
    lines = text.split("\n")
    for i, line in enumerate(lines, 1):
        if "```" in line:
            in_backticks = not in_backticks
        if in_backticks or not line.strip():
            continue
        if line.startswith(" "):
            errors.append(f"{path}:{i}: space indentation (TMDL requires tabs)")
        stripped = line.lstrip("\t")
        depth = len(line) - len(stripped)
        if depth == 0 and not stripped.startswith("///"):
            token = stripped.split(None, 1)[0]
            if token not in TOP_LEVEL_OBJECTS and "=" not in stripped and ":" not in stripped:
                warnings.append(f"{path}:{i}: unrecognized top-level token '{token}'")
        for m in re.finditer(r"^(?:\t*)(?:entity|entityRelationship|rule|metric|namespace|table)\s+('(?:[^']|'')*'|\S+)", line):
            if len(m.group(1)) > NAME_LIMIT:
                errors.append(f"{path}:{i}: name longer than {NAME_LIMIT} characters")
        if line.startswith("///") and len(line) > DESCRIPTION_LIMIT:
            errors.append(f"{path}:{i}: description longer than {DESCRIPTION_LIMIT} characters")
    if path.startswith("metrics/") or path == "metrics.tmdl":
        if re.search(r"dialect:\s*DAX\b", text, re.I):
            errors.append(f"{path}: explicit metric with DAX dialect is rejected (use a table measure); rule from an unverified summary")
    if path.startswith("entities/") and not text.lstrip("﻿").lstrip().startswith(("///", "entity")):
        warnings.append(f"{path}: expected an 'entity' declaration at the top")


def cmd_unpack(args: argparse.Namespace) -> int:
    parts = _load_parts(Path(args.src))
    out = Path(args.dir)
    for path, raw in parts.items():
        target = out / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
    print(f"unpacked {len(parts)} parts to {out}")
    return 0


def cmd_pack(args: argparse.Namespace) -> int:
    parts = _load_parts(Path(args.dir))
    envelope = {"definition": {"parts": [
        {"path": p, "payload": base64.b64encode(raw).decode("ascii"), "payloadType": "InlineBase64"}
        for p, raw in parts.items()
    ]}}
    text = json.dumps(envelope, indent=2)
    if args.output:
        Path(args.output).write_text(text + "\n", encoding="utf-8")
    else:
        print(text)
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    parts = _load_parts(Path(args.src))
    errors, warnings = check_parts(parts)
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"{detect_generation(parts)}: {len(parts)} parts, {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


def cmd_detect(args: argparse.Namespace) -> int:
    print(detect_generation(_load_parts(Path(args.src))))
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("unpack"); p.add_argument("src"); p.add_argument("dir"); p.set_defaults(fn=cmd_unpack)
    p = sub.add_parser("pack"); p.add_argument("dir"); p.add_argument("-o", "--output"); p.set_defaults(fn=cmd_pack)
    p = sub.add_parser("check"); p.add_argument("src"); p.set_defaults(fn=cmd_check)
    p = sub.add_parser("detect"); p.add_argument("src"); p.set_defaults(fn=cmd_detect)
    args = ap.parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
