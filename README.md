# TiMEM Skills

Agent Skills for [TiMEM](https://timem.cloud) memory workflows. Skills orchestrate **when and how** to call [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) atomic tools — memories (`search_memories`, `create_memory`, `delete_memory`) and rules (`recall_rules`, `learn_rule`, `record_rule_outcome`).

**Language:** English | [简体中文](README_zh.md)

Skills follow the [Agent Skills](https://agentskills.io/specification) open standard (portable across Cursor, Claude Code, Codex, and other compatible agents).

## Recommended (coding)

If TiMEM MCP is already connected and you write code, install **one** coding package:

| Package | Path | When |
|---------|------|------|
| **Full** (progressive disclosure) | [`dist/full/timem-coding-memory/`](dist/full/timem-coding-memory/) | Default — multi-file skill |
| **Standalone** (single `SKILL.md`) | [`dist/standalone/timem-coding-memory/`](dist/standalone/timem-coding-memory/) | Simplest copy — one markdown file |

Copy the folder into your client's skills directory (name must stay `timem-coding-memory`):

| Client | Project | User (global) |
|--------|---------|-----------------|
| Agents / Codex-style | `.agents/skills/` | `~/.agents/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |

```bash
git clone https://github.com/TiMEM-AI/timem-skill.git
cd your-project

# Full package (recommended)
mkdir -p .agents/skills   # or .claude/skills / .cursor/skills
cp -r /path/to/timem-skill/dist/full/timem-coding-memory .agents/skills/

# Or standalone (single SKILL.md inside the folder)
cp -r /path/to/timem-skill/dist/standalone/timem-coding-memory .agents/skills/
```

Helper:

```bash
python /path/to/timem-skill/scripts/install.py --skill coding --target agents
# python .../install.py --skill coding-standalone --target cursor --global
```

**No separate `shared` folder is required** for install. Packages are self-contained.

## All skills

| Skill | Scene | Install from |
|-------|-------|--------------|
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | **`dist/full/` or `dist/standalone/`** (prefer these) |
| [timem-general-memory](skills/timem-general-memory/) | `general` | **`dist/full/` or `dist/standalone/`** (prefer these) |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | `skills/timem-writing-memory/` (self-contained) |
| [timem-rule-learning](skills/timem-rule-learning/) | rules (cross-scene) | `skills/timem-rule-learning/` (self-contained) |
| [timem-knowledge](skills/timem-knowledge/) | knowledge | `skills/timem-knowledge/` |

Each skill is **one job**. The agent routes by each skill's `description`. `timem-rule-learning` is not a memory scene: it runs alongside memory skills and is scoped by `agent_id`.

Source of truth for development lives under `skills/`. User-facing coding and general packages are built into `dist/` via `python scripts/build-all.py`.

## Prerequisites

1. Configure [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) in your MCP client (`TiMEM_API_KEY`, `TiMEM_USER_ID`).
2. Install the skill package(s) you need (see above and [docs/installation.md](docs/installation.md)).

## Architecture

Skill = orchestration (search/write memories; recall/learn/grade rules). MCP = atomic API tools.

Details: [docs/architecture.md](docs/architecture.md)

## License

MIT — see [LICENSE](LICENSE).
