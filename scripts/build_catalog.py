#!/usr/bin/env python3
"""Build catalog.json, docs payloads, and the README skill catalog."""

from __future__ import annotations

import argparse
import json
import re
from collections import OrderedDict
from pathlib import Path

from skill_repo import REPO_ROOT, Skill, count_skill_tree_lines, load_skills, write_json


PLATFORM_LABELS = {
    "databricks": ("Databricks", "Lakehouse · Unity Catalog · Spark · MLflow · Genie"),
    "fabric": ("Microsoft Fabric", "OneLake · Eventhouse · Power BI · Dataflows · Warehouse"),
    "snowflake": ("Snowflake", "Cortex AI · Snowpark · Kafka · Dynamic Tables"),
    "foundry": ("Microsoft Foundry", "Azure AI Foundry · Agents · Projects · Endpoints"),
}
PLATFORM_ORDER = ["databricks", "fabric", "snowflake", "foundry"]


def skill_item(skill: Skill) -> dict[str, object]:
    item: dict[str, object] = {
        "name": skill.name,
        "dir": skill.dir_name,
        "router_lines": skill.router_lines,
        "summary": skill.summary,
    }
    if skill.metadata.get("version"):
        item["version"] = skill.metadata["version"]
    if skill.metadata.get("updated"):
        item["updated"] = skill.metadata["updated"]
    return item


def build_catalog(include_untracked: bool = True) -> dict[str, object]:
    skills = load_skills(REPO_ROOT, include_untracked)
    platform_names = PLATFORM_ORDER + sorted(
        platform for platform in {skill.platform for skill in skills} if platform not in PLATFORM_ORDER
    )
    platforms: OrderedDict[str, list[dict[str, object]]] = OrderedDict()
    for platform in platform_names:
        platform_skills = sorted(
            (skill for skill in skills if skill.platform == platform),
            key=lambda skill: (skill.name != platform, skill.name),
        )
        items = [skill_item(skill) for skill in platform_skills]
        if items:
            platforms[platform] = items

    router_lines = [skill.router_lines for skill in skills]
    total_lines = sum(count_skill_tree_lines(skill) for skill in skills)
    meta = {
        "skills": len(skills),
        "avg_router_lines": round(sum(router_lines) / len(router_lines), 1) if router_lines else 0,
        "routers_over_150": sum(1 for count in router_lines if count > 150),
        "total_lines": total_lines,
    }
    return {"platforms": platforms, "meta": meta}


def render_markdown_table(items: list[dict[str, object]]) -> str:
    lines = [
        "| Skill | What it does | Router |",
        "|---|---|---|",
    ]
    for item in items:
        lines.append(
            f"| `{item['name']}` | {item['summary']} | {item['router_lines']} |"
        )
    return "\n".join(lines)


def render_catalog_markdown(catalog: dict[str, object]) -> str:
    platforms = catalog["platforms"]
    lines = ["## 📚 Skill catalog", ""]
    for platform, items in platforms.items():
        title, subtitle = PLATFORM_LABELS.get(platform, (platform.title(), "Agent skills"))
        lines.extend(
            [
                "",
                f"### {title} ({len(items)})",
                "",
                f"*{subtitle}*",
                "",
                "<details>",
                f"<summary><b>Show {len(items)} skills</b></summary>",
                "",
                render_markdown_table(items),
                "",
                "</details>",
                "",
            ]
        )
    lines.extend(["", "---", ""])
    return "\n".join(lines)


def update_readme(readme_path: Path, catalog: dict[str, object]) -> None:
    text = readme_path.read_text(encoding="utf-8")
    meta = catalog["meta"]
    skills = meta["skills"]
    avg = meta["avg_router_lines"]
    over = meta["routers_over_150"]
    under = skills - over
    total_lines = f"{meta['total_lines']:,}"

    replacements = [
        (r"\*\*\d+ production skills\*\*", f"**{skills} production skills**"),
        (r"badge/skills-\d+", f"badge/skills-{skills}"),
        (r"badge/avg_router-[0-9.]+_lines", f"badge/avg_router-{avg}_lines"),
        (r"Installs \*\*all \d+ skills\*\*", f"Installs **all {skills} skills**"),
        (r"\| \*\(none\)\* \| install all \d+ skills \|", f"| *(none)* | install all {skills} skills |"),
        (
            r"- \*\*Thin-router architecture\*\* — `SKILL\.md` is a \*router\*, not a manual\. Average \*\*[0-9.]+ lines\*\* \(target < 100, hard cap 150\)\. \d+ of \d+ routers are under 150\.",
            f"- **Thin-router architecture** — `SKILL.md` is a *router*, not a manual. Average **{avg} lines** (target < 100, hard cap 150). {under} of {skills} routers are under 150.",
        ),
        (
            r"\*\*Suite totals:\*\* \d+ skills · [0-9.]+ avg router lines · [0-9,]+ total lines of curated playbook\.",
            f"**Suite totals:** {skills} skills · {avg} avg router lines · {total_lines} total lines of curated playbook.",
        ),
    ]
    for pattern, replacement in replacements:
        text = re.sub(pattern, replacement, text)

    start = text.index("## 📚 Skill catalog")
    end = text.index("## 🛠️ Uninstall")
    text = text[:start] + render_catalog_markdown(catalog) + "\n" + text[end:]
    readme_path.write_text(text, encoding="utf-8")


def write_outputs(catalog: dict[str, object], root: Path) -> None:
    write_json(root / "catalog.json", catalog)
    docs = root / "docs"
    docs.mkdir(exist_ok=True)
    write_json(docs / "catalog.json", catalog)
    compact = json.dumps(catalog, ensure_ascii=False, separators=(",", ":"))
    (docs / "_data.js").write_text(f"window.SKILLS={compact};\n", encoding="utf-8")
    readme = root / "README.md"
    if readme.exists():
        update_readme(readme, catalog)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--include-untracked", action="store_true", default=True, help="include untracked top-level skills (default)")
    parser.add_argument("--tracked-only", action="store_true", help="only include git-tracked top-level skills")
    parser.add_argument("--write", action="store_true", help="write catalog outputs instead of printing JSON")
    args = parser.parse_args()

    catalog = build_catalog(include_untracked=not args.tracked_only)
    if args.write:
        write_outputs(catalog, REPO_ROOT)
    else:
        print(json.dumps(catalog, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
