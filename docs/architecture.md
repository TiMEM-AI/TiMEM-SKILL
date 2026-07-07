# TiMEM Skill vs MCP Architecture

## Division of labor

| Layer | Repository | Responsibility |
|-------|------------|----------------|
| **Skill** | timem-skill | When to search/create, scene-specific rules, verify steps, closure |
| **MCP** | timem-mcp | Atomic tools: `search_memories`, `create_memory`, `delete_memory`, `ready` |

Skills follow the Context7-style pattern: Skill orchestrates, MCP executes.

```
User message
    → Cursor matches skill description
    → Skill workflow (checklists, tiers, rubric)
    → MCP tool calls (search / create / delete)
    → Skill formats answer
```

## Three scenes, three skills

MCP defines three scenes in `timem_mcp/scenes.py`:

| Scene | `domain` | `expert_id` | Skill |
|-------|----------|-------------|-------|
| general | `general` | `default` | timem-general-memory |
| coding | `coding` | `coder` | timem-coding-memory |
| writing | `writing` | `writer` | timem-writing-memory |

**One job per skill.** Cursor loads each skill's `name` + `description` at discovery; the full `SKILL.md` loads only when relevant. No router skill is required.

## What skills must NOT use (legacy MCP)

These embed orchestration inside MCP and conflict with the skill-first model:

- `should_search_memories` / `should_create_memory`
- `begin_coding_turn` / `end_coding_turn`

Use atomic tools with explicit `domain` instead.

Optional helper: `classify_memory_scene(messages)` when scene is unclear.

## Complexity by scene

| Scene | Search model | Verify | Write rubric |
|-------|--------------|--------|--------------|
| general | Simple recall triggers | vs current conversation | Stable preferences/facts |
| writing | Style/audience recall | vs draft intent | Style, tone, audience |
| coding | Search Tier S0–S-skip | vs code + AGENTS.md | decision/constraint/lesson/… |

Coding is the most detailed skill; general and writing stay lean.

## Canonical sources

| Content | Canonical location |
|---------|-------------------|
| Coding search/write rules | timem-skill `skills/timem-coding-memory/` |
| General/write rules | timem-skill respective skills |
| MCP tool API | timem-skill `skills/shared/mcp-tools.md` + timem-mcp server |
| Legacy MCP guides | timem-mcp resources (appendix; point to timem-skill) |

## session_id conventions

| Scene | session_id |
|-------|------------|
| general | Optional; omit for cross-topic prefs; use stable topic name when scoped |
| writing | Optional series/doc name (e.g. `blog-2026`) |
| coding | Required stable repo name (e.g. `timem-mcp`) |

Never use a random UUID per turn.
