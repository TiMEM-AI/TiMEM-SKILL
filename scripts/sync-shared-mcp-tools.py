#!/usr/bin/env python3
"""Sync skills/shared/mcp-tools.md into each memory skill's references/mcp-tools.md."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHARED = ROOT / "skills" / "shared" / "mcp-tools.md"

# Scene-specific preface (kept above the shared body).
PREFACES: dict[str, str] = {
    "timem-coding-memory": """# MCP tools (coding scene)

Use **`domain=coding`** on search and create. Use stable **`session_id`** = repo name.

Coding-specific: optional `memory_hint` on `create_memory` (`decision`, `constraint`, `lesson`, `convention`, `preference`, `correction`).

Atomic MCP memory tools only. Full parameter reference follows.

""",
    "timem-general-memory": """# MCP tools (general scene)

Use **`domain=general`**. `session_id` is optional (omit for cross-topic preferences).

Atomic MCP memory tools only. Full parameter reference follows.

""",
    "timem-writing-memory": """# MCP tools (writing scene)

Use **`domain=writing`**. `session_id` is optional (stable series/doc name when scoped).

Atomic MCP memory tools only. Full parameter reference follows.

""",
}

MARKER = "<!-- Generated from skills/shared/mcp-tools.md; do not edit by hand. Run: python scripts/sync-shared-mcp-tools.py -->\n"


def sync() -> list[Path]:
    if not SHARED.is_file():
        raise SystemExit(f"Missing shared source: {SHARED}")

    shared_body = SHARED.read_text(encoding="utf-8").strip() + "\n"
    written: list[Path] = []

    for skill_name, preface in PREFACES.items():
        out = ROOT / "skills" / skill_name / "references" / "mcp-tools.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        content = MARKER + "\n" + preface.rstrip() + "\n\n---\n\n" + shared_body
        out.write_text(content, encoding="utf-8", newline="\n")
        written.append(out)

    return written


def main() -> None:
    paths = sync()
    print(f"Synced shared MCP tools into {len(paths)} skill(s):")
    for p in paths:
        print(f"  {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
