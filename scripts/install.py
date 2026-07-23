#!/usr/bin/env python3
"""Install a TiMEM skill into a local Agent Skills directory."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SKILL_SOURCES: dict[str, Path] = {
    "coding": ROOT / "dist" / "full" / "timem-coding-memory",
    "coding-standalone": ROOT / "dist" / "standalone" / "timem-coding-memory",
    "general": ROOT / "dist" / "full" / "timem-general-memory",
    "general-standalone": ROOT / "dist" / "standalone" / "timem-general-memory",
    "writing": ROOT / "skills" / "timem-writing-memory",
}

# Project-relative and user-global skills roots per target.
TARGETS = {
    "agents": (Path(".agents") / "skills", Path.home() / ".agents" / "skills"),
    "claude": (Path(".claude") / "skills", Path.home() / ".claude" / "skills"),
    "cursor": (Path(".cursor") / "skills", Path.home() / ".cursor" / "skills"),
}


def resolve_dest(target: str, global_install: bool, project_root: Path) -> Path:
    if target not in TARGETS:
        raise SystemExit(f"Unknown target {target!r}; choose from {', '.join(TARGETS)}")
    project_rel, user_global = TARGETS[target]
    return user_global if global_install else (project_root / project_rel)


def install(skill: str, dest_root: Path, force: bool) -> Path:
    src = SKILL_SOURCES.get(skill)
    if src is None:
        raise SystemExit(
            f"Unknown skill {skill!r}; choose from {', '.join(SKILL_SOURCES)}"
        )
    if not src.is_dir() or not (src / "SKILL.md").is_file():
        hint = (
            "Run: python scripts/build-all.py"
            if skill.startswith(("coding", "general"))
            else f"Missing source at {src}"
        )
        raise SystemExit(f"Skill package not found: {src}\n{hint}")

    # Folder name must match skill `name` (agentskills.io).
    if skill in ("coding", "coding-standalone"):
        dest = dest_root / "timem-coding-memory"
    elif skill in ("general", "general-standalone"):
        dest = dest_root / "timem-general-memory"
    else:
        dest = dest_root / "timem-writing-memory"

    dest_root.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        if not force:
            raise SystemExit(f"Destination exists: {dest}\nRe-run with --force to replace.")
        shutil.rmtree(dest)

    shutil.copytree(src, dest)
    return dest


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Install a TiMEM skill into .agents/.claude/.cursor skills dirs."
    )
    parser.add_argument(
        "--skill",
        required=True,
        choices=sorted(SKILL_SOURCES),
        help="Which package to install",
    )
    parser.add_argument(
        "--target",
        required=True,
        choices=sorted(TARGETS),
        help="Client skills layout",
    )
    parser.add_argument(
        "--global",
        dest="global_install",
        action="store_true",
        help="Install under the user home skills directory",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Project root for non-global installs (default: cwd)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing skill directory",
    )
    args = parser.parse_args(argv)

    dest_root = resolve_dest(args.target, args.global_install, args.project_root.resolve())
    installed = install(args.skill, dest_root, args.force)
    print(f"Installed {args.skill} → {installed}")


if __name__ == "__main__":
    main(sys.argv[1:])
