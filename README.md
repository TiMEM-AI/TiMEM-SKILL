# TiMEM Skills

Agent Skills for [TiMEM](https://timem.cloud) memory workflows. Skills orchestrate **when and how** to call [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) atomic tools — memories (`search_memories`, `create_memory`, `delete_memory`) and rules (`recall_rules`, `learn_rule`, `record_rule_outcome`).

**Language:** English | [简体中文](README_zh.md)

## Skills

| Skill | Scene | Install when |
|-------|-------|--------------|
| [timem-general-memory](skills/timem-general-memory/) | `general` | Personal preferences, everyday facts |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | Copywriting, style, tone, content creation |
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | Software development, debugging, architecture |
| [timem-rule-learning](skills/timem-rule-learning/) | rules (cross-scene) | Learn from corrections and outcomes; reuse proven situation→action rules |

Each scene is a **separate skill** (one job per skill). Cursor routes by each skill's `description` — no router skill required. `timem-rule-learning` is not a scene: it runs alongside the memory skills and is scoped by `agent_id` instead of `domain`.

## Prerequisites

1. Configure [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) in your MCP client (`TiMEM_API_KEY`, `TiMEM_USER_ID`).
2. Copy the skill(s) you need into `.cursor/skills/` (see [docs/installation.md](docs/installation.md)).

## Quick install

```bash
git clone <path-to-timem-skill>
cd your-project
mkdir -p .cursor/skills
cp -r /path/to/timem-skill/skills/timem-coding-memory .cursor/skills/
cp -r /path/to/timem-skill/skills/shared .cursor/skills/timem-shared
```

Install all four skills for full TiMEM coverage (`timem-rule-learning` is self-contained — no `shared` needed). See [docs/installation.md](docs/installation.md).

## Architecture

Skill = orchestration (search/write rules). MCP = atomic API (`search_memories`, `create_memory`, `delete_memory`).

Details: [docs/architecture.md](docs/architecture.md)

## License

MIT — see [LICENSE](LICENSE).
