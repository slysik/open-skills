#!/usr/bin/env python3
"""Validate skill metadata, generated catalog outputs, and router links."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

from build_catalog import build_catalog
from skill_repo import (
    REPO_ROOT,
    all_skill_paths,
    discover_skill_paths,
    extract_frontmatter,
    load_skill,
    suspicious_summary,
)


LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
TOP_LEVEL_KEYS = {"name", "description"}


@dataclass
class Issue:
    severity: str
    path: Path
    message: str

    def format(self) -> str:
        rel = self.path.relative_to(REPO_ROOT) if self.path.is_absolute() else self.path
        return f"{self.severity.upper()}: {rel}: {self.message}"


def is_external_link(link: str) -> bool:
    return (
        "://" in link
        or link.startswith("#")
        or link.startswith("mailto:")
        or link.startswith("tel:")
    )


def check_router_links(skill_path: Path, issues: list[Issue]) -> None:
    text = skill_path.read_text(encoding="utf-8")
    for link in LINK_RE.findall(text):
        if is_external_link(link):
            continue
        target = link.split("#", 1)[0]
        if not target:
            continue
        if not (skill_path.parent / target).exists():
            issues.append(Issue("error", skill_path, f"broken router link: {link}"))


def check_skill(skill_path: Path, strict_frontmatter: bool, max_router_lines: int, issues: list[Issue]) -> None:
    try:
        skill = load_skill(skill_path)
        frontmatter_text, _ = extract_frontmatter(skill_path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 - validator should report path-level failure
        issues.append(Issue("error", skill_path, str(exc)))
        return

    if not skill.name:
        issues.append(Issue("error", skill_path, "missing frontmatter name"))
    if not skill.description:
        issues.append(Issue("error", skill_path, "missing frontmatter description"))
    if suspicious_summary(skill.summary):
        issues.append(Issue("error", skill_path, f"suspicious parsed summary: {skill.summary!r}"))
    if skill.router_lines > max_router_lines:
        issues.append(Issue("warn", skill_path, f"router has {skill.router_lines} lines; target cap is {max_router_lines}"))
    if skill.name and skill.name != skill.dir_name:
        issues.append(Issue("warn", skill_path, f"frontmatter name {skill.name!r} differs from folder {skill.dir_name!r}"))

    keys = {
        line.split(":", 1)[0]
        for line in frontmatter_text.splitlines()
        if line and not line[:1].isspace() and ":" in line
    }
    extra_keys = sorted(keys - TOP_LEVEL_KEYS)
    if extra_keys and strict_frontmatter:
        issues.append(Issue("error", skill_path, f"extra frontmatter keys: {', '.join(extra_keys)}"))

    if "package.json" in skill_path.read_text(encoding="utf-8"):
        issues.append(Issue("error", skill_path, "update check references package.json; use catalog.json metadata instead"))

    check_router_links(skill_path, issues)


def nested_skill_candidates(include_untracked: bool) -> list[Path]:
    if include_untracked:
        return all_skill_paths(REPO_ROOT)
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files", "skills"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return all_skill_paths(REPO_ROOT)
    return sorted(REPO_ROOT / line for line in result.stdout.splitlines() if line.endswith("SKILL.md"))


def check_nested_skill_files(top_level: set[Path], include_untracked: bool, issues: list[Issue]) -> None:
    for path in nested_skill_candidates(include_untracked):
        if path not in top_level:
            issues.append(Issue("warn", path, "nested SKILL.md is not installable as a top-level skill"))


def check_catalog(include_untracked: bool, issues: list[Issue]) -> None:
    expected = build_catalog(include_untracked=include_untracked)
    catalog_path = REPO_ROOT / "catalog.json"
    docs_catalog_path = REPO_ROOT / "docs" / "catalog.json"
    data_js_path = REPO_ROOT / "docs" / "_data.js"

    if not catalog_path.exists():
        issues.append(Issue("error", catalog_path, "missing generated catalog"))
        return

    actual = json.loads(catalog_path.read_text(encoding="utf-8"))
    if actual != expected:
        issues.append(Issue("error", catalog_path, "catalog is stale; run scripts/build_catalog.py --write"))

    if docs_catalog_path.exists():
        docs_actual = json.loads(docs_catalog_path.read_text(encoding="utf-8"))
        if docs_actual != expected:
            issues.append(Issue("error", docs_catalog_path, "docs catalog is stale; run scripts/build_catalog.py --write"))
    else:
        issues.append(Issue("error", docs_catalog_path, "missing docs catalog"))

    if data_js_path.exists():
        data_text = data_js_path.read_text(encoding="utf-8").strip()
        prefix = "window.SKILLS="
        if not data_text.startswith(prefix) or not data_text.endswith(";"):
            issues.append(Issue("error", data_js_path, "unexpected docs data wrapper"))
        else:
            data_payload = json.loads(data_text[len(prefix) : -1])
            if data_payload != expected:
                issues.append(Issue("error", data_js_path, "docs data payload is stale; run scripts/build_catalog.py --write"))
    else:
        issues.append(Issue("error", data_js_path, "missing docs data payload"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--include-untracked", action="store_true", default=True, help="validate untracked top-level skills too (default)")
    parser.add_argument("--tracked-only", action="store_true", help="only validate git-tracked top-level skills")
    parser.add_argument("--strict-frontmatter", action="store_true", help="treat non-name/description frontmatter keys as errors")
    parser.add_argument("--max-router-lines", type=int, default=150)
    parser.add_argument("--fail-on-warnings", action="store_true")
    args = parser.parse_args()

    issues: list[Issue] = []
    include_untracked = not args.tracked_only
    skill_paths = discover_skill_paths(REPO_ROOT, include_untracked=include_untracked)
    top_level = set(skill_paths)
    if not skill_paths:
        issues.append(Issue("error", REPO_ROOT / "skills", "no top-level skills found"))

    for path in skill_paths:
        check_skill(path, args.strict_frontmatter, args.max_router_lines, issues)
    check_nested_skill_files(top_level, include_untracked, issues)
    check_catalog(include_untracked, issues)

    errors = [issue for issue in issues if issue.severity == "error"]
    warnings = [issue for issue in issues if issue.severity == "warn"]
    for issue in issues:
        print(issue.format())
    print(f"Validated {len(skill_paths)} top-level skill(s): {len(errors)} error(s), {len(warnings)} warning(s).")
    if errors or (warnings and args.fail_on_warnings):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
