#!/usr/bin/env python3
"""
sync_databricks_skills.py — Check and sync Databricks skills from upstream repos into open-skills.

Upstream sources:
  - databricks/databricks-agent-skills (OFFICIAL canonical repo) → Databricks skills
  - mlflow/skills                                                → MLflow skills
  - databricks-solutions/apx                                     → APX skills

Usage:
  python3 scripts/sync_databricks_skills.py          # Check and report status
  python3 scripts/sync_databricks_skills.py --apply  # Sync upstream and rebuild catalog
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
LOCAL_SKILLS = REPO_ROOT / "skills" / "databricks"

UPSTREAM_REPOS = {
    "databricks_official": {
        "url": "https://github.com/databricks/databricks-agent-skills.git",
        "branch": "main",
        "skills_path": "skills",
    },
    "mlflow": {
        "url": "https://github.com/mlflow/skills.git",
        "branch": "main",
        "skills_path": ".",
    },
    "apx": {
        "url": "https://github.com/databricks-solutions/apx.git",
        "branch": "main",
        "skills_path": "skills/apx",
    },
}

# Optional explicit aliases if local folder name differs from upstream folder name
SKILL_ALIASES = {
    "databricks-app-apx": ("apx", "databricks-app-apx"),
    "mlflow-onboarding": ("mlflow", "mlflow-onboarding"),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def clone_repo(url: str, branch: str, dest: Path) -> bool:
    try:
        subprocess.run(
            ["git", "clone", "--depth=1", "--quiet", f"--branch={branch}", url, str(dest)],
            check=True,
            capture_output=True,
            timeout=60,
        )
        return True
    except Exception as e:
        print(f"  ⚠ Failed to clone {url}: {e}", file=sys.stderr)
        return False


def read_normalized(path: Path) -> bytes:
    if path.suffix == ".md":
        text = path.read_text(encoding="utf-8", errors="replace")
        normalized = text.replace("../../skills/", "../").replace("../../../skills/", "../../")
        return normalized.encode("utf-8")
    return path.read_bytes()


def compare_skill(local_dir: Path, upstream_dir: Path) -> list[str]:
    if not local_dir.exists():
        return ["New skill available"]

    changes = []
    upstream_files = {f.relative_to(upstream_dir): f for f in upstream_dir.rglob("*") if f.is_file()}
    local_files = {f.relative_to(local_dir): f for f in local_dir.rglob("*") if f.is_file()}

    for rel, uf in upstream_files.items():
        lf = local_dir / rel
        if not lf.exists():
            changes.append(f"Added {rel}")
        elif hashlib.sha256(read_normalized(uf)).hexdigest() != hashlib.sha256(read_normalized(lf)).hexdigest():
            changes.append(f"Modified {rel}")

    for rel in local_files:
        if rel not in upstream_files:
            changes.append(f"Deleted {rel}")

    return changes


def apply_skill(local_name: str, upstream_dir: Path, local_dir: Path):
    if local_dir.exists():
        shutil.rmtree(local_dir)
    shutil.copytree(upstream_dir, local_dir)
    # Normalize upstream flat skill cross-links (../../skills/X -> ../X)
    for md in local_dir.rglob("*.md"):
        text = md.read_text(encoding="utf-8")
        if "skills/" in text:
            fixed_text = text.replace("../../skills/", "../").replace("../../../skills/", "../../")
            if fixed_text != text:
                md.write_text(fixed_text, encoding="utf-8")
    print(f"  ✓ Updated {local_name}")


def main():
    parser = argparse.ArgumentParser(description="Sync Databricks skills from upstream into open-skills")
    parser.add_argument("--apply", action="store_true", help="Apply updates and rebuild catalog")
    args = parser.parse_args()

    tmpdir = Path(tempfile.mkdtemp())
    repo_dirs = {}

    try:
        print("Fetching upstream repos...")
        for key, cfg in UPSTREAM_REPOS.items():
            dest = tmpdir / key
            if clone_repo(cfg["url"], cfg["branch"], dest):
                repo_dirs[key] = dest

        if not repo_dirs:
            print("No upstream repos could be cloned. Aborting.", file=sys.stderr)
            sys.exit(1)

        # 1. Collect skills from official Databricks repo
        skills_to_sync = {}
        if "databricks_official" in repo_dirs:
            official_skills_dir = repo_dirs["databricks_official"] / UPSTREAM_REPOS["databricks_official"]["skills_path"]
            for d in official_skills_dir.iterdir():
                if d.is_dir() and (d / "SKILL.md").exists():
                    skills_to_sync[d.name] = ("databricks_official", d)

        # 2. Add aliases and secondary repos (mlflow, apx)
        for local_name, (repo_key, upstream_name) in SKILL_ALIASES.items():
            if repo_key in repo_dirs:
                repo_cfg = UPSTREAM_REPOS[repo_key]
                upstream_dir = repo_dirs[repo_key] / repo_cfg["skills_path"] / upstream_name
                if upstream_dir.exists() and (upstream_dir / "SKILL.md").exists():
                    skills_to_sync[local_name] = (repo_key, upstream_dir)

        # 3. Compare with local
        updated_skills = []
        for local_name, (repo_key, upstream_dir) in sorted(skills_to_sync.items()):
            local_dir = LOCAL_SKILLS / local_name
            changes = compare_skill(local_dir, upstream_dir)
            if changes:
                updated_skills.append((local_name, upstream_dir, local_dir, changes))

        if not updated_skills:
            print("✅ All Databricks skills in open-skills are up to date.")
        else:
            print(f"\nFound {len(updated_skills)} updated / new skill(s):")
            for local_name, upstream_dir, local_dir, changes in updated_skills:
                tag = "NEW" if not local_dir.exists() else f"{len(changes)} changed file(s)"
                print(f"  • {local_name}: {tag}")

            if args.apply:
                print("\nApplying updates to skills/databricks/...")
                for local_name, upstream_dir, local_dir, _ in updated_skills:
                    apply_skill(local_name, upstream_dir, local_dir)

                print("\nRebuilding catalog and validating...")
                subprocess.run([sys.executable, str(REPO_ROOT / "scripts" / "build_catalog.py"), "--write"], check=True)
                subprocess.run([sys.executable, str(REPO_ROOT / "scripts" / "validate_skills.py")], check=True)
                print("✅ Skills updated and catalog refreshed.")
            else:
                print("\nRun with --apply (or 'just sync-databricks') to copy changes and rebuild catalog.")

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


if __name__ == "__main__":
    main()
