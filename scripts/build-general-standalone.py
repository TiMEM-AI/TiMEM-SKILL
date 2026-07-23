#!/usr/bin/env python3
"""Build general skill dist packages: full (multi-file) and standalone (single SKILL.md)."""

from __future__ import annotations

import re
import shutil
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "skills" / "timem-general-memory"
DIST_FULL = ROOT / "dist" / "full" / "timem-general-memory"
DIST_STANDALONE = ROOT / "dist" / "standalone" / "timem-general-memory"

LINE_WARN_THRESHOLD = 250  # prefer ≤220; warn above 250
LINE_TARGET = 220

REF_SECTIONS = [
    ("workflow.md", "General workflow (full)"),
    ("examples.md", "General memory examples"),
    ("mcp-tools.md", "MCP tools (general)"),
]

LINK_TARGET_TO_SECTION = {
    "workflow.md": "General workflow (full)",
    "references/workflow.md": "General workflow (full)",
    "examples.md": "General memory examples",
    "references/examples.md": "General memory examples",
    "mcp-tools.md": "MCP tools (general)",
    "references/mcp-tools.md": "MCP tools (general)",
    "agents-snippet.md": "dist/full/timem-general-memory/assets/agents-snippet.md",
    "assets/agents-snippet.md": "dist/full/timem-general-memory/assets/agents-snippet.md",
}


def _strip_md_title(text: str) -> str:
    lines = text.splitlines()
    if lines and lines[0].startswith("# "):
        lines = lines[1:]
        if lines and lines[0].strip() == "":
            lines = lines[1:]
    return "\n".join(lines).strip() + "\n"


def _demote_headings(text: str) -> str:
    lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("# ") and not line.startswith("## "):
            lines.append("###" + line[1:])
        elif line.startswith("#### "):
            lines.append("#" + line)
        elif line.startswith("### "):
            lines.append("#" + line)
        elif line.startswith("## "):
            lines.append("#" + line)
        else:
            lines.append(line)
    return "\n".join(lines).strip() + "\n"


def _scrub_inlined_markdown(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        label, target = match.group(1), match.group(2)
        if re.match(r"^(https?:|mailto:|#)", target, flags=re.I):
            return match.group(0)
        path = target.split("#", 1)[0].split("?", 1)[0]
        if not path.endswith(".md"):
            return match.group(0)
        path = path.lstrip("./")
        section = LINK_TARGET_TO_SECTION.get(path) or LINK_TARGET_TO_SECTION.get(
            Path(path).name
        )
        if section and section.startswith("dist/"):
            return f"see `{section}` in the full package"
        if section:
            return f"**{section}**"
        if label.endswith(".md"):
            return "inlined section below"
        return label

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", repl, text)
    text = re.sub(
        r"([.!?]\s+)[Ss]ee\s+\*\*([^*]+)\*\*(?:\s+below)?",
        r"\1See **\2** below",
        text,
    )
    text = re.sub(
        r"(?<![.!?]\s)(?<![.!?])\bsee\s+\*\*([^*]+)\*\*(?:\s+below)?",
        r"see **\1** below",
        text,
    )
    return text


def _assert_no_md_file_refs(text: str) -> None:
    bad_links = re.findall(r"\[[^\]]+\]\(([^)]+\.md(?:#[^)]*)?)\)", text)
    bad_links = [
        t for t in bad_links if not re.match(r"^(https?:|mailto:)", t, flags=re.I)
    ]
    if bad_links:
        raise SystemExit(f"Standalone still has relative .md links: {bad_links}")

    for basename in ("workflow.md", "examples.md", "mcp-tools.md", "agents-snippet.md"):
        for m in re.finditer(re.escape(basename), text):
            start = m.start()
            window = text[max(0, start - 80) : m.end()]
            if basename == "agents-snippet.md" and "dist/full/timem-general-memory/assets/" in window:
                continue
            raise SystemExit(f"Standalone still references file path {basename!r}")


def _collapse_extra_rules(text: str) -> str:
    text = re.sub(r"(?:\n---\n){2,}", "\n\n---\n\n", text)
    text = re.sub(r"\n---\n\s*\n---\n", "\n\n---\n\n", text)
    text = re.sub(r"\n---\n+(?=#{1,6} )", "\n\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def _memory_only_mcp_tools(text: str) -> str:
    """Slim MCP reference for general standalone (memory tools + scene map)."""
    text = re.sub(
        r"^# MCP tools \(general scene\).*?\n---\n+",
        "",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n### Empty coding search.*?(?=\n---\n|\n## |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    cut = re.search(
        r"\n---\n\n## `list_knowledge_bases`.*?(?=\n---\n\n## Scene → domain mapping)",
        text,
        flags=re.DOTALL,
    )
    if cut:
        text = text[: cut.start()] + "\n" + text[cut.end() :]

    # Drop ready / classify long sections; keep one-liner classify.
    text = re.sub(
        r"\n---\n\n## `ready`.*?(?=\n---\n\n## Scene → domain mapping|\n## Scene → domain mapping|\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n---\n\n## `classify_memory_scene`.*?(?=\n---\n\n## Scene → domain mapping|\n## Scene → domain mapping|\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n## `delete_memory`.*?(?=\n---\n|\n## |\Z)",
        "\n## `delete_memory`\n\n"
        "Soft-delete by ID after user intent. Search first → confirm → "
        "`delete_memory(memory_id=\"...\")`.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    # Drop fenced examples to save lines.
    text = re.sub(r"\nExample:\n\n```[\s\S]*?```\n", "\n", text)
    # Drop search_tier row (coding-oriented).
    text = re.sub(
        r"\| `search_tier` \|.*?\n",
        "",
        text,
    )
    # Clarify session_id for general (always required — personal or topic).
    text = re.sub(
        r"\| `session_id` \| Scene-dependent \| .*?\|\n",
        "| `session_id` | **Yes** | Always `personal` or a stable topic; never omit. |\n",
        text,
        count=1,
    )
    text = re.sub(
        r"\| `session_id` \| \*\*Yes\*\*.*?\| .*?\|\n",
        "| `session_id` | **Yes** | Always `personal` or a stable topic; never omit. |\n",
        text,
        count=1,
    )
    # Drop memory_hint Engine note verbosity if present — keep row.
    text = re.sub(
        r"\| `memory_hint` \| No \| .*?\|\n",
        "| `memory_hint` | No | Coding-oriented; omit for general |\n",
        text,
        count=1,
    )
    # Append compact classify + scene map if scene map still present.
    if "## Scene → domain mapping" not in text and "Scene → domain mapping" not in text:
        text += (
            "\n## Scene → domain mapping\n\n"
            "| domain | expert_id |\n|--------|-----------|\n"
            "| `general` | `default` |\n"
            "| `coding` | `coder` |\n"
            "| `writing` | `writer` |\n\n"
            "Ambiguous domain: `classify_memory_scene(messages=[...])`.\n"
        )
    else:
        text += "\nAmbiguous domain: `classify_memory_scene(messages=[...])`.\n"
    return _collapse_extra_rules(text)


def _condense_workflow_for_standalone(text: str) -> str:
    """Drop scene-boundary duplicate (already in SKILL body)."""
    text = re.sub(
        r"\n## Scene boundary.*?(?=\n## |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    return _collapse_extra_rules(text)


def _condense_examples(text: str) -> str:
    """Keep examples 1–4; drop gate-miss duplicate of anti-patterns."""
    keep = {1, 2, 3, 4}
    parts = re.split(r"(?=## Example \d+)", text)
    intro = parts[0] if parts and not parts[0].startswith("## Example") else ""
    kept: list[str] = []
    for part in parts:
        if not part.startswith("## Example"):
            continue
        m = re.match(r"## Example (\d+)", part)
        if m and int(m.group(1)) in keep:
            kept.append(part)
    renumbered = [
        re.sub(r"^## Example \d+", f"## Example {i}", p, count=1)
        for i, p in enumerate(kept, start=1)
    ]
    return (intro + "".join(renumbered)).strip() + "\n"


def _split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("SKILL.md missing YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("SKILL.md frontmatter not closed")
    fm = text[: end + 5]
    body = text[end + 5 :]
    return fm, body


def _rewrite_body_for_standalone(body: str) -> str:
    body = body.replace(
        "Search? Explicit recall OR answer needs known prefs/facts (references/workflow.md)",
        "Search? Explicit recall OR answer needs known prefs/facts (see General workflow below)",
    )
    body = body.replace(
        "Details: [references/workflow.md](references/workflow.md)",
        "Details: see **General workflow (full)** below.",
    )
    body = body.replace(
        "MCP tools: see [references/mcp-tools.md](references/mcp-tools.md)",
        "MCP tools: see **MCP tools (general)** below.",
    )

    body = re.sub(
        r"\n## AGENTS\.md snippet\n\n.*?(?=\n## |\Z)",
        "\n",
        body,
        count=1,
        flags=re.DOTALL,
    )

    body = re.sub(
        r"\n## References\n\n(?:- \[.*?\]\(.*?\)\n)+",
        "\n## References\n\n"
        "Inlined below:\n\n"
        "- General workflow (full)\n"
        "- General memory examples\n"
        "- MCP tools (general)\n\n"
        "Optional AGENTS.md paste template: "
        "`dist/full/timem-general-memory/assets/agents-snippet.md`.\n\n",
        body,
        count=1,
    )
    return body


def _assert_standalone_quality(text: str) -> None:
    if not text.startswith("---\n") or "name: timem-general-memory" not in text:
        raise SystemExit("Standalone SKILL.md failed frontmatter/name check")
    if "../../shared" in text:
        raise SystemExit("Standalone still references ../../shared")
    _assert_no_md_file_refs(text)
    nums = [int(n) for n in re.findall(r"^#{2,3} Example (\d+)\b", text, flags=re.MULTILINE)]
    if nums and nums != list(range(1, len(nums) + 1)):
        raise SystemExit(f"Standalone example numbers not consecutive: {nums}")
    if re.search(r"^## AGENTS\.md snippet\s*$", text, flags=re.MULTILINE):
        raise SystemExit("Standalone must not contain AGENTS.md snippet section")


def build_standalone_skill_md() -> str:
    skill_text = (SRC / "SKILL.md").read_text(encoding="utf-8")
    frontmatter, body = _split_frontmatter(skill_text)
    body = _rewrite_body_for_standalone(body)

    parts = [
        frontmatter.rstrip() + "\n",
        "\n<!-- Generated by scripts/build-general-standalone.py; do not edit by hand. -->\n",
        body.rstrip() + "\n",
    ]

    for filename, heading in REF_SECTIONS:
        path = SRC / "references" / filename
        content = _strip_md_title(path.read_text(encoding="utf-8"))
        content = re.sub(r"<!-- Generated from .*? -->\n+", "", content)
        if filename == "workflow.md":
            content = _condense_workflow_for_standalone(content)
        if filename == "examples.md":
            content = _condense_examples(content)
        if filename == "mcp-tools.md":
            content = _memory_only_mcp_tools(content)
        content = _scrub_inlined_markdown(content)
        content = _demote_headings(content)
        content = _collapse_extra_rules(content)
        parts.append(f"\n## {heading}\n\n")
        parts.append(content if content.endswith("\n") else content + "\n")

    return "".join(parts)


def copy_full_package() -> None:
    if DIST_FULL.exists():
        shutil.rmtree(DIST_FULL)
    shutil.copytree(
        SRC,
        DIST_FULL,
        ignore=shutil.ignore_patterns(".DS_Store", "Thumbs.db"),
    )


def build() -> None:
    if not (SRC / "SKILL.md").is_file():
        raise SystemExit(f"Missing source skill: {SRC}")

    copy_full_package()
    print(f"Wrote full package: {DIST_FULL.relative_to(ROOT)}")
    if not (DIST_FULL / "assets" / "agents-snippet.md").is_file():
        raise SystemExit("Full package missing assets/agents-snippet.md")

    standalone_md = build_standalone_skill_md()
    _assert_standalone_quality(standalone_md)

    DIST_STANDALONE.mkdir(parents=True, exist_ok=True)
    for child in DIST_STANDALONE.iterdir():
        if child.name != "SKILL.md":
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
    out = DIST_STANDALONE / "SKILL.md"
    out.write_text(standalone_md, encoding="utf-8", newline="\n")

    line_count = standalone_md.count("\n") + (0 if standalone_md.endswith("\n") else 1)
    sections = re.findall(r"^## (.+)$", standalone_md, flags=re.MULTILINE)
    print(f"Wrote standalone: {out.relative_to(ROOT)} ({line_count} lines)")
    print("Sections:")
    for s in sections:
        print(f"  - {s}")
    if line_count > LINE_TARGET:
        print(f"Note: standalone is {line_count} lines (target ≤{LINE_TARGET})")
    if line_count > LINE_WARN_THRESHOLD:
        warnings.warn(
            f"Standalone SKILL.md has {line_count} lines (recommended < {LINE_WARN_THRESHOLD})",
            UserWarning,
            stacklevel=1,
        )


def main() -> None:
    build()


if __name__ == "__main__":
    main()
