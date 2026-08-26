# Installation

Install [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) first, then install one or more Agent Skills.

## Prerequisites

- TiMEM MCP configured (`TiMEM_API_KEY`)
- An Agent Skills–compatible client (Cursor, Claude Code, Codex, etc.)

## Global agent instructions

The one-click installers update only verified user-global or Agent-workspace instruction targets. They never search repositories for instruction files or change project-level rules.

| Client | Instruction target | Behavior |
|---|---|---|
| Codex | `$CODEX_HOME/AGENTS.md` (default: `~/.codex/AGENTS.md`) | Create or append. The installer honors `CODEX_HOME`. |
| Claude Code | `~/.claude/CLAUDE.md` | Create or append. |
| Cursor | `~/.cursor/rules/timem-memory.mdc` | Create a local `.mdc` User Rule with `alwaysApply: true`. |
| TRAE | `~/.trae/user_rules/timem-memory.md` | Create an independent Markdown Global Rule with `alwaysApply: true`. |
| Qoder CLI | `${QODER_CONFIG_DIR:-~/.qoder}/AGENTS.md` | Local extension; create or append. This does **not** apply to Qoder IDE project rules. |
| OpenClaw | `<resolved-agent-workspace>/AGENTS.md` | Create or append for the default workspace and configured per-Agent workspaces. |
| Hermes | `${HERMES_HOME:-~/.hermes}/SOUL.md` | Append only when `SOUL.md` already exists. |
| WorkBuddy | `~/.workbuddy/SOUL.md` | Append only when `SOUL.md` already exists. |

For OpenClaw, the resolver honors `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_PROFILE`, `agents.defaults.workspace`, and configured Agent workspace entries. It does not write `~/.openclaw/AGENTS.md`.

Hermes and WorkBuddy are intentionally append-only. Their `SOUL.md` files contain the Agent's identity and persistent behavior; the installer does not create them, so enabling TiMEM cannot silently replace the default behavior.

Cursor documents `~/.cursor/rules` as the per-machine User Rule directory. The installer creates `timem-memory.mdc` there with the documented rule-file format and `alwaysApply: true`; it applies to Cursor Agent Chat, not Tab, Inline Edit, or Bugbot. TRAE documents `~/.trae/user_rules` as its Global Rules directory, so the installer creates its own `timem-memory.md` there with `alwaysApply: true` and never modifies project `.trae/rules`. Claude Code's user-level MCP entry is written to `~/.claude.json`. On Windows, TRAE MCP resolution prioritizes `%APPDATA%\Trae\User\mcp.json`, then the TRAE Solo variants, and finally legacy `~/.trae/mcp.json`.

The installer searches each selected file once for `TiMEM-SPACE`, `太忆空间`, or `timem-memory`; if none is found, it appends:

```text
每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程
```

This operation is idempotent. To opt out, use `--skip-agent-instructions` in Bash or `-SkipAgentInstructions` in PowerShell. The verification evidence and source links are in [agent-instruction-research.md](agent-instruction-research.md).

## What to install

| Project type | Skills |
|--------------|--------|
| Software development | **`timem-coding-memory`** from `dist/standalone/` (recommended) or `dist/full/`; optional **`timem-general-memory`** |
| Content / copywriting | `timem-writing-memory` (+ optional general from `dist/`) |
| General assistant | **`timem-general-memory`** from `dist/standalone/` (recommended) or `dist/full/` |
| Agent self-improvement (rules) | `timem-rule-learning` (self-contained) |
| Knowledge RAG | `timem-knowledge` |
| Full TiMEM | Coding + general from `dist/standalone/` + other skills from `skills/` as needed |

**Prefer standalone** for clients that progressively load only `SKILL.md` (critical search/write rules stay in one file). Use `dist/full/` when you want separate `references/` on disk.

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
