#!/usr/bin/env python3
"""Shared helpers for open-skills skill maintenance scripts."""

from __future__ import annotations

import ast
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_DIR = REPO_ROOT / "skills"
SUMMARY_LIMIT = 160

_TOP_LEVEL_KEY = re.compile(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$")


@dataclass(frozen=True)
class Skill:
    path: Path
    platform: str
    dir_name: str
    name: str
    description: str
    metadata: dict[str, str]
    frontmatter: dict[str, Any]
    router_lines: int
    summary: str


def is_top_level_skill_path(path: Path, root: Path = REPO_ROOT) -> bool:
    try:
        rel = path.relative_to(root)
    except ValueError:
        return False
    return (
        len(rel.parts) == 4
        and rel.parts[0] == "skills"
        and rel.parts[3] == "SKILL.md"
    )


def git_tracked_skill_paths(root: Path = REPO_ROOT) -> list[Path]:
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "skills/*/*/SKILL.md"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return []
    paths = [root / line.strip() for line in result.stdout.splitlines() if line.strip()]
    return sorted(path for path in paths if is_top_level_skill_path(path, root))


def discover_skill_paths(root: Path = REPO_ROOT, include_untracked: bool = True) -> list[Path]:
    if include_untracked:
        return sorted(root.glob("skills/*/*/SKILL.md"))
    tracked = git_tracked_skill_paths(root)
    if tracked:
        return tracked
    return sorted(root.glob("skills/*/*/SKILL.md"))


def all_skill_paths(root: Path = REPO_ROOT) -> list[Path]:
    return sorted((root / "skills").glob("**/SKILL.md"))


def extract_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---"):
        raise ValueError("missing YAML frontmatter")
    end = text.find("\n---", 3)
    if end < 0:
        raise ValueError("unterminated YAML frontmatter")
    frontmatter = text[3:end].strip("\n")
    body = text[end + len("\n---") :].lstrip("\n")
    return frontmatter, body


def _strip_scalar(value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    if value[0] in {"'", '"'}:
        try:
            parsed = ast.literal_eval(value)
            return str(parsed)
        except (SyntaxError, ValueError):
            return value.strip("'\"")
    return value


def _dedent_block(lines: list[str]) -> list[str]:
    nonblank = [line for line in lines if line.strip()]
    if not nonblank:
        return []
    indent = min(len(line) - len(line.lstrip(" ")) for line in nonblank)
    return [line[indent:] if len(line) >= indent else line for line in lines]


def _fold_block(lines: list[str], style: str) -> str:
    dedented = _dedent_block(lines)
    if style.startswith("|"):
        return "\n".join(line.rstrip() for line in dedented).strip()
    parts: list[str] = []
    paragraph: list[str] = []
    for line in dedented:
        if line.strip():
            paragraph.append(line.strip())
        elif paragraph:
            parts.append(" ".join(paragraph))
            paragraph = []
    if paragraph:
        parts.append(" ".join(paragraph))
    return "\n\n".join(parts).strip()


def parse_frontmatter(frontmatter: str) -> dict[str, Any]:
    lines = frontmatter.splitlines()
    data: dict[str, Any] = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line[:1].isspace():
            i += 1
            continue
        match = _TOP_LEVEL_KEY.match(line)
        if not match:
            i += 1
            continue

        key, raw_value = match.group(1), (match.group(2) or "")
        value = raw_value.strip()
        i += 1

        if value in {">", ">-", ">|", "|", "|-"}:
            block: list[str] = []
            while i < len(lines):
                next_line = lines[i]
                if next_line and not next_line[:1].isspace() and _TOP_LEVEL_KEY.match(next_line):
                    break
                block.append(next_line)
                i += 1
            data[key] = _fold_block(block, value)
            continue

        if not value:
            block = []
            while i < len(lines):
                next_line = lines[i]
                if next_line and not next_line[:1].isspace() and _TOP_LEVEL_KEY.match(next_line):
                    break
                block.append(next_line)
                i += 1
            if key == "metadata":
                metadata: dict[str, str] = {}
                for child in block:
                    child_match = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(.*)$", child)
                    if child_match:
                        metadata[child_match.group(1)] = _strip_scalar(child_match.group(2))
                data[key] = metadata
            else:
                data[key] = "\n".join(block).strip()
            continue

        data[key] = _strip_scalar(value)

    return data


def summarize_description(description: str, limit: int = SUMMARY_LIMIT) -> str:
    summary = re.sub(r"\s+", " ", description).strip()
    if len(summary) <= limit:
        return summary
    return summary[: limit - 3].rstrip() + "..."


def load_skill(path: Path) -> Skill:
    text = path.read_text(encoding="utf-8")
    frontmatter_text, _ = extract_frontmatter(text)
    frontmatter = parse_frontmatter(frontmatter_text)
    metadata = frontmatter.get("metadata") if isinstance(frontmatter.get("metadata"), dict) else {}
    rel = path.relative_to(REPO_ROOT)
    description = str(frontmatter.get("description", "")).strip()
    return Skill(
        path=path,
        platform=rel.parts[1],
        dir_name=rel.parts[2],
        name=str(frontmatter.get("name", "")).strip(),
        description=description,
        metadata={str(k): str(v) for k, v in metadata.items()},
        frontmatter=frontmatter,
        router_lines=len(text.splitlines()),
        summary=summarize_description(description),
    )


def load_skills(root: Path = REPO_ROOT, include_untracked: bool = True) -> list[Skill]:
    return [load_skill(path) for path in discover_skill_paths(root, include_untracked)]


def suspicious_summary(summary: str) -> bool:
    return summary.strip() in {">", ">-", "|", "|-"} or summary.lstrip().startswith("'>")


def count_text_lines(path: Path) -> int:
    try:
        return len(path.read_text(encoding="utf-8").splitlines())
    except UnicodeDecodeError:
        return 0


def count_skill_tree_lines(skill: Skill) -> int:
    return sum(count_text_lines(path) for path in skill.path.parent.rglob("*") if path.is_file())


def write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
