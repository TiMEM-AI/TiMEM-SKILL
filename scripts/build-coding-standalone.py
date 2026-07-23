#!/usr/bin/env python3
"""Build coding skill dist packages: full (multi-file) and standalone (single SKILL.md)."""

from __future__ import annotations

import re
import shutil
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "skills" / "timem-coding-memory"
DIST_FULL = ROOT / "dist" / "full" / "timem-coding-memory"
DIST_STANDALONE = ROOT / "dist" / "standalone" / "timem-coding-memory"

LINE_WARN_THRESHOLD = 400  # prefer ≤350; warn above 400

# (source filename, H2 heading used in standalone)
REF_SECTIONS = [
    ("search-tier.md", "Coding Search Tier (full)"),
    ("write-rubric.md", "Coding write rubric (full)"),
    ("examples.md", "Coding memory examples"),
    ("mcp-tools.md", "MCP tools (coding)"),
]

# Map relative .md targets → standalone section titles for link scrubbing.
LINK_TARGET_TO_SECTION = {
    "write-rubric.md": "Coding write rubric (full)",
    "references/write-rubric.md": "Coding write rubric (full)",
    "search-tier.md": "Coding Search Tier (full)",
    "references/search-tier.md": "Coding Search Tier (full)",
    "examples.md": "Coding memory examples",
    "references/examples.md": "Coding memory examples",
    "mcp-tools.md": "MCP tools (coding)",
    "references/mcp-tools.md": "MCP tools (coding)",
    "agents-snippet.md": "dist/full/timem-coding-memory/assets/agents-snippet.md",
    "assets/agents-snippet.md": "dist/full/timem-coding-memory/assets/agents-snippet.md",
}

# Keep high-signal examples: remember, closure, Must recall, empty-gap.
# Drop ongoing-task / gate-miss / duplicate orientation (anti-patterns + ex.4).
KEEP_EXAMPLE_ORIG_NUMS = {2, 3, 4, 5}


def _strip_md_title(text: str) -> str:
    """Remove a leading single H1 so nested sections stay under the parent H2."""
    lines = text.splitlines()
    if lines and lines[0].startswith("# "):
        lines = lines[1:]
        if lines and lines[0].strip() == "":
            lines = lines[1:]
    return "\n".join(lines).strip() + "\n"


def _demote_headings(text: str) -> str:
    """Demote headings so content sits under an outer H2 (# → ###, ## → ###, ### → ####)."""
    lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("# ") and not line.startswith("## "):
            lines.append("###" + line[1:])  # # → ###
        elif line.startswith("#### "):
            lines.append("#" + line)  # #### → #####
        elif line.startswith("### "):
            lines.append("#" + line)  # ### → ####
        elif line.startswith("## "):
            lines.append("#" + line)  # ## → ###
        else:
            lines.append(line)
    return "\n".join(lines).strip() + "\n"


def _scrub_inlined_markdown(text: str) -> str:
    """Rewrite relative *.md links to in-document section pointers."""

    def repl(match: re.Match[str]) -> str:
        label, target = match.group(1), match.group(2)
        # Ignore http(s) and mailto
        if re.match(r"^(https?:|mailto:|#)", target, flags=re.I):
            return match.group(0)
        # Strip anchors/query
        path = target.split("#", 1)[0].split("?", 1)[0]
        if not path.endswith(".md"):
            return match.group(0)
        # Normalize ./prefix
        path = path.lstrip("./")
        section = LINK_TARGET_TO_SECTION.get(path) or LINK_TARGET_TO_SECTION.get(
            Path(path).name
        )
        if section and section.startswith("dist/"):
            return f"see `{section}` in the full package"
        if section:
            # Avoid leaving "*.md" in the visible text (fails path assertions).
            return f"**{section}**"
        # Unknown .md — keep label only if it is not itself a filename
        if label.endswith(".md"):
            return "inlined section below"
        return label

    # [label](target)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", repl, text)
    # Normalize "See **Section**" / "see **Section** below" (sentence-case See)
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
    # Bare See write-rubric.md style leftovers
    text = re.sub(
        r"\bSee\s+write-rubric\.md\b",
        "see **Coding write rubric (full)** below",
        text,
    )
    return text


def _assert_no_md_file_refs(text: str) -> None:
    """Fail if standalone still points at skill-relative .md files."""
    bad_links = re.findall(r"\[[^\]]+\]\(([^)]+\.md(?:#[^)]*)?)\)", text)
    bad_links = [
        t for t in bad_links if not re.match(r"^(https?:|mailto:)", t, flags=re.I)
    ]
    if bad_links:
        raise SystemExit(f"Standalone still has relative .md links: {bad_links}")

    # Known skill-relative basenames that must not appear as file paths.
    for basename in (
        "write-rubric.md",
        "search-tier.md",
        "examples.md",
        "mcp-tools.md",
        "agents-snippet.md",
    ):
        for m in re.finditer(re.escape(basename), text):
            start = m.start()
            # Allow the documented full-package AGENTS path.
            window = text[max(0, start - 80) : m.end()]
            if basename == "agents-snippet.md" and "dist/full/timem-coding-memory/assets/" in window:
                continue
            raise SystemExit(f"Standalone still references file path {basename!r}")


def _condense_examples(text: str) -> str:
    """Keep high-signal examples and renumber Example 1..N consecutively."""
    parts = re.split(r"(?=## Example \d+)", text)
    intro = parts[0] if parts and not parts[0].startswith("## Example") else ""
    examples = [p for p in parts if p.startswith("## Example")]

    kept: list[str] = []
    for part in examples:
        m = re.match(r"## Example (\d+)", part)
        if not m:
            continue
        num = int(m.group(1))
        if num not in KEEP_EXAMPLE_ORIG_NUMS:
            continue
        kept.append(part)

    renumbered: list[str] = []
    for i, part in enumerate(kept, start=1):
        renumbered.append(
            re.sub(r"^## Example \d+", f"## Example {i}", part, count=1)
        )

    out = intro + "".join(renumbered)
    return out.strip() + "\n"


def _collapse_extra_rules(text: str) -> str:
    """Remove empty / duplicate horizontal rules left after cuts."""
    text = re.sub(r"(?:\n---\n){2,}", "\n\n---\n\n", text)
    text = re.sub(r"\n---\n\s*\n---\n", "\n\n---\n\n", text)
    # Drop a rule that only sits in whitespace before the next heading.
    text = re.sub(r"\n---\n+(?=#{1,6} )", "\n\n", text)
    # Collapse 3+ blank lines to 2.
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def _condense_search_tier_for_standalone(text: str) -> str:
    """Keep Must/Should/Skip + S* map + call + empty; drop duplicate prose."""
    # Drop verbose Skip / Do NOT subsections (covered by primary table + SKILL anti-patterns).
    text = re.sub(
        r"\n### Skip \(narrow only\).*?(?=\n## |\n### |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n### Do NOT classify as Skip.*?(?=\n## |\n### |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n\*\*Note:\*\* AGENTS\.md.*?\n",
        "\n",
        text,
        count=1,
    )
    # Collapse project technical subsection into one line after S* table.
    text = re.sub(
        r"\n### Project technical questions.*?(?=\n## |\n### |\Z)",
        "\n\n`S3` overview/module/arch questions are **Must** (not Skip): "
        "search first → verify → then read code; then `project_discovery` write gate.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    # Order rule duplicates SKILL checklist.
    text = re.sub(
        r"\n## Order rule.*?(?=\n## |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    return _collapse_extra_rules(text)


def _condense_write_rubric_for_standalone(text: str) -> str:
    """Keep gates + required rubric + noise + budget; drop duplicate tables."""
    text = re.sub(
        r"\n## `memory_hint` checklist.*?(?=\n## |\Z)",
        "\n\n`memory_hint`: decision|constraint|lesson|convention|preference|correction "
        "(agent typing hint; MCP may not persist to Engine).\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n## Rubric — advisory.*?(?=\n## |\Z)",
        "\n\nAdvisory: `bounded_content`, `freshness_ok`, `non_duplicate`.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n## NOT valid skip reasons.*?(?=\n## |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n## Recommended call.*?(?=\n## |\Z)",
        "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"\n## Priority \(when choosing memory_hint\).*?(?=\n## |\Z)",
        "\n\nHint priority: constraint > decision > convention > preference > lesson.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    # Shorten project_discovery prose.
    text = re.sub(
        r"\n## `project_discovery` \(default create when gated\).*?(?=\n## |\Z)",
        "\n\n## `project_discovery`\n\n"
        "For Must/`S3` module/arch answers: verify from code; if search empty/incomplete "
        "→ default `create_memory` (`memory_hint=convention`, ≤10 bullets). "
        "Skip if highly similar complete entry exists.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    return _collapse_extra_rules(text)


def _memory_only_mcp_tools(text: str) -> str:
    """Slim MCP reference for coding standalone (memory tools + scene map)."""
    text = re.sub(
        r"^# MCP tools \(coding scene\).*?\n---\n+",
        "",
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

    # Prefer coding-domain create_memory example in standalone.
    text = text.replace(
        """create_memory(
  domain="general",
  session_id="personal",
  messages=[
    {"role": "user", "content": "Remember I prefer concise answers."},
    {"role": "assistant", "content": "Stored: prefer concise answers."},
  ],
)""",
        """create_memory(
  domain="coding",
  session_id="timem-mcp",
  memory_hint="convention",
  messages=[
    {"role": "user", "content": "What are the memory-related modules?"},
    {"role": "assistant", "content": "Verified summary: modules, paths, roles."},
  ],
)""",
    )
    # Drop optional classify + ready prose (SKILL prerequisites cover ready).
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
    # Compact delete_memory steps.
    text = re.sub(
        r"\n## `delete_memory`.*?(?=\n---\n|\n## |\Z)",
        "\n## `delete_memory`\n\n"
        "Soft-delete by ID after user intent. Search with `search_tier=\"S6\"` to get `memory_id`, "
        "confirm if ambiguous, then `delete_memory(memory_id=\"...\")`.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    # Compact empty-search field table to one paragraph.
    text = re.sub(
        r"\n### Empty coding search.*?(?=\n---\n|\n## |\Z)",
        "\n\n### Empty coding search (`domain=coding`, `count=0`)\n\n"
        "May include `memory_gap`, `guidance`, `elevate_create`, `suggested_next` "
        "(does **not** auto-create). Work from code; apply write rubric before create. "
        "`elevate_create` needs `search_tier` + `session_id`.\n\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    return _collapse_extra_rules(text)


def _split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("SKILL.md missing YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("SKILL.md frontmatter not closed")
    fm = text[: end + 5]  # include closing ---\n
    body = text[end + 5 :]
    return fm, body


def _rewrite_body_for_standalone(body: str) -> str:
    """Point checklist/summaries at inlined sections; drop AGENTS + external refs."""
    body = body.replace(
        "Classify Must / Should / Skip (references/search-tier.md)",
        "Classify Must / Should / Skip (see Coding Search Tier below)",
    )
    body = body.replace(
        "Gated WRITE EVAL only (references/write-rubric.md)",
        "Gated WRITE EVAL only (see Coding write rubric below)",
    )
    body = body.replace(
        "Details: [references/search-tier.md](references/search-tier.md)",
        "Details: see **Coding Search Tier (full)** below.",
    )
    body = body.replace(
        "See [write-rubric.md](references/write-rubric.md).",
        "See **Coding write rubric (full)** below.",
    )
    body = body.replace(
        "MCP tools: [references/mcp-tools.md](references/mcp-tools.md)",
        "MCP tools: see **MCP tools (coding)** below.",
    )

    # Remove AGENTS.md snippet section (template lives in full package assets/).
    body = re.sub(
        r"\n## AGENTS\.md snippet\n\n.*?(?=\n## |\Z)",
        "\n",
        body,
        count=1,
        flags=re.DOTALL,
    )

    # Replace ## References link list with an in-document TOC.
    body = re.sub(
        r"\n## References\n\n(?:- \[.*?\]\(.*?\)\n)+",
        "\n## References\n\n"
        "Inlined below:\n\n"
        "- Coding Search Tier (full)\n"
        "- Coding write rubric (full)\n"
        "- Coding memory examples\n"
        "- MCP tools (coding)\n\n"
        "Optional AGENTS.md paste template (human-facing, not required at runtime): "
        "in the repo at `dist/full/timem-coding-memory/assets/agents-snippet.md`.\n\n",
        body,
        count=1,
    )
    return body


def _validate_standalone(text: str) -> list[str]:
    """Return human-readable section headings (##) for logging."""
    return re.findall(r"^## (.+)$", text, flags=re.MULTILINE)


def _assert_standalone_quality(text: str) -> None:
    if not text.startswith("---\n") or "name: timem-coding-memory" not in text:
        raise SystemExit("Standalone SKILL.md failed frontmatter/name check")
    if "../../shared" in text:
        raise SystemExit("Standalone still references ../../shared")

    _assert_no_md_file_refs(text)

    # Example titles must be consecutive Example 1..N (## or ### after demote)
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
        "\n<!-- Generated by scripts/build-coding-standalone.py; do not edit by hand. -->\n",
        body.rstrip() + "\n",
    ]

    for filename, heading in REF_SECTIONS:
        path = SRC / "references" / filename
        content = _strip_md_title(path.read_text(encoding="utf-8"))
        content = re.sub(r"<!-- Generated from .*? -->\n+", "", content)
        if filename == "examples.md":
            content = _condense_examples(content)
        if filename == "search-tier.md":
            content = _condense_search_tier_for_standalone(content)
        if filename == "write-rubric.md":
            content = _condense_write_rubric_for_standalone(content)
        if filename == "mcp-tools.md":
            content = _memory_only_mcp_tools(content)
        content = _scrub_inlined_markdown(content)
        content = _demote_headings(content)
        content = _collapse_extra_rules(content)
        parts.append(f"\n## {heading}\n\n")
        parts.append(content if content.endswith("\n") else content + "\n")

    # Do not inline AGENTS snippet into standalone (full package keeps assets/).
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
    sections = _validate_standalone(standalone_md)
    print(f"Wrote standalone: {out.relative_to(ROOT)} ({line_count} lines)")
    print("Sections:")
    for s in sections:
        print(f"  - {s}")
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
