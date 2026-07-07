# Installation

Install [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) first, then copy skills into your project or user skills directory.

## Prerequisites

- TiMEM MCP configured (`TiMEM_API_KEY`, `TiMEM_USER_ID`)
- Cursor (or compatible client with Agent Skills support)

## What to install

| Project type | Skills |
|--------------|--------|
| Software development | `timem-coding-memory` (+ optional `timem-general-memory`) |
| Content / copywriting | `timem-writing-memory` (+ optional `timem-general-memory`) |
| General assistant | `timem-general-memory` |
| Full TiMEM | All three + `shared` |

## Project install (recommended)

From your project root:

```bash
# Clone or use local path to timem-skill
TIMEM_SKILL=/path/to/timem-skill

mkdir -p .cursor/skills
cp -r "$TIMEM_SKILL/skills/timem-general-memory" .cursor/skills/
cp -r "$TIMEM_SKILL/skills/timem-writing-memory" .cursor/skills/
cp -r "$TIMEM_SKILL/skills/timem-coding-memory" .cursor/skills/
cp -r "$TIMEM_SKILL/skills/shared" .cursor/skills/shared
```

Install only the folders you need; always copy `shared` if skills reference MCP tool docs.

Restart Cursor or reload the window so skills are discovered.

## Global install

```bash
mkdir -p ~/.cursor/skills
cp -r /path/to/timem-skill/skills/timem-coding-memory ~/.cursor/skills/
cp -r /path/to/timem-skill/skills/shared ~/.cursor/skills/shared
```

## Coding projects — AGENTS.md

Paste [agents-snippet.md](../skills/timem-coding-memory/assets/agents-snippet.md) into your project `AGENTS.md`.

## Remote Rule (GitHub)

After publishing timem-skill to GitHub:

1. Cursor → Customize → Rules → Add Rule → Remote Rule (Github)
2. Enter repository URL
3. Select skills to import

## Verify

1. MCP: call `ready` or confirm TiMEM tools appear in Agent
2. Skills: type `/` in Agent chat — skills should appear by name
3. Test a coding turn: tier classify → conditional `search_memories` → no `begin_coding_turn`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Skill not listed | Confirm `.cursor/skills/<name>/SKILL.md` exists; reload window |
| MCP tools missing | Check `~/.cursor/mcp.json` and env vars |
| `query_text` API error | Always pass 3–12 words on search |
| Wrong scene | Install correct skill; pass explicit `domain` |
