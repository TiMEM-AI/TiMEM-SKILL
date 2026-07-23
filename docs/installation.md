# Installation

Install [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) first, then install one or more Agent Skills.

## Prerequisites

- TiMEM MCP configured (`TiMEM_API_KEY`, `TiMEM_USER_ID`)
- An Agent Skills–compatible client (Cursor, Claude Code, Codex, etc.)

## What to install

| Project type | Skills |
|--------------|--------|
| Software development | **`timem-coding-memory`** from `dist/` (full or standalone); optional **`timem-general-memory`** from `dist/` |
| Content / copywriting | `timem-writing-memory` (+ optional general from `dist/`) |
| General assistant | **`timem-general-memory`** from `dist/` (full or standalone) |
| Agent self-improvement (rules) | `timem-rule-learning` (self-contained) |
| Knowledge RAG | `timem-knowledge` |
| Full TiMEM | Coding + general from `dist/` + other skills from `skills/` as needed |

**Memory coding/general/writing packages no longer require a separate `shared` install** — MCP tool docs are inlined into each skill's `references/mcp-tools.md` (synced from `skills/shared/mcp-tools.md`).

## Skills directory by client

| Client | Project | User (global) |
|--------|---------|-----------------|
| Agents / Codex-style | `.agents/skills/` | `~/.agents/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |

The installed folder name must match the skill `name` (e.g. `timem-coding-memory/SKILL.md`).

## Coding & general packages (dual-track)

| Skill | Full | Standalone |
|-------|------|------------|
| coding | `dist/full/timem-coding-memory/` | `dist/standalone/timem-coding-memory/` |
| general | `dist/full/timem-general-memory/` | `dist/standalone/timem-general-memory/` |

Rebuild after editing sources:

```bash
python scripts/build-all.py
```

## Quick install (coding / general)

```bash
TIMEM_SKILL=/path/to/timem-skill
mkdir -p .agents/skills   # or .claude/skills / .cursor/skills
cp -r "$TIMEM_SKILL/dist/full/timem-coding-memory" .agents/skills/
cp -r "$TIMEM_SKILL/dist/full/timem-general-memory" .agents/skills/
```

Or with the helper script:

```bash
python "$TIMEM_SKILL/scripts/install.py" --skill coding --target agents
python "$TIMEM_SKILL/scripts/install.py" --skill coding-standalone --target cursor --global --force
python "$TIMEM_SKILL/scripts/install.py" --skill general --target agents
python "$TIMEM_SKILL/scripts/install.py" --skill general-standalone --target claude --force
```

## Other skills

```bash
TIMEM_SKILL=/path/to/timem-skill
mkdir -p .agents/skills
cp -r "$TIMEM_SKILL/skills/timem-writing-memory" .agents/skills/
cp -r "$TIMEM_SKILL/skills/timem-rule-learning" .agents/skills/
```

## AGENTS.md snippets

- Coding: [agents-snippet.md](../skills/timem-coding-memory/assets/agents-snippet.md) (also under `dist/full/timem-coding-memory/assets/`)
- General: [agents-snippet.md](../skills/timem-general-memory/assets/agents-snippet.md) (also under `dist/full/timem-general-memory/assets/`)

## Remote import (Cursor)

After publishing timem-skill to GitHub:

1. Customize → Rules → Add Rule → Remote Rule (Github)
2. Enter repository URL
3. Select skills to import (prefer packages under `dist/` for coding when available)

## Verify

1. MCP: call `ready` or confirm TiMEM tools appear
2. Skills: invoke `/timem-coding-memory` or confirm auto-discovery
3. Coding turn: tier classify → conditional `search_memories`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Skill not listed | Confirm `<skills-root>/timem-coding-memory/SKILL.md` exists; reload client |
| MCP tools missing | Check MCP config and env vars |
| `query_text` API error | Always pass 3–12 words on search |
| Stale standalone | Re-run `python scripts/build-all.py` after editing `skills/` |
| Wrong scene | Install correct skill; pass explicit `domain` |
