# TiMEM Skills

Agent Skills for [TiMEM](https://timem.cloud) memory workflows. Skills orchestrate **when and how** to call [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) atomic tools (`search_memories`, `create_memory`, `delete_memory`).

**Language:** English | [简体中文](README_zh.md)

## Skills

| Skill | Scene | Install when |
|-------|-------|--------------|
| [timem-general-memory](skills/timem-general-memory/) | `general` | Personal preferences, everyday facts |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | Copywriting, style, tone, content creation |
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | Software development, debugging, architecture |

Each scene is a **separate skill** (one job per skill). Cursor routes by each skill's `description` — no router skill required.

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

Install all three skills for full TiMEM coverage. See [docs/installation.md](docs/installation.md).

## Architecture

Skill = orchestration (search/write rules). MCP = atomic API (`search_memories`, `create_memory`, `delete_memory`).

Details: [docs/architecture.md](docs/architecture.md)

## License

MIT — see [LICENSE](LICENSE).
