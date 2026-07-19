# TiMEM Skill vs MCP Architecture

## Division of labor

| Layer | Repository | Responsibility |
|-------|------------|----------------|
| **Skill** | timem-skill | When to search/create/recall/learn, scene-specific rules, verify steps, closure |
| **MCP** | timem-mcp | Atomic memory tools and the 8-tool public Rule surface (runtime, lifecycle, authenticated-user usage) |

Skills follow the Context7-style pattern: Skill orchestrates, MCP executes.

The MCP runtime can optionally reduce its public schema with
`TiMEM_MCP_TOOL_PROFILE`. A Rule-only runtime exposes the 8 public Rule tools
plus the always-available `ready` diagnostic. This selection is explicit and
static per server instance: installing a Skill does not automatically change an
MCP server's tools, and Tool Profiles are not authorization boundaries. Use
`timem://capabilities` to inspect the active runtime surface.

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

## Rule learning (cross-scene, not a scene)

`timem-rule-learning` orchestrates the rule loop (recall → apply → grade → learn). It
complements the memory skills instead of replacing them:

| Axis | Memory skills | timem-rule-learning |
|------|---------------|---------------------|
| Stores | Facts, preferences, context | "In situation X, do Y" lessons |
| Scope | `domain` (+ `session_id`) | `user_id` + `agent_id` (+ `attributes` filters) |
| Tools | `search_memories` / `create_memory` / `delete_memory` | `recall_rules` / `learn_rule` / `record_rule_outcome` / lifecycle management / `get_rule_usage_report` |
| Feedback loop | — | `record_rule_outcome` grades applied rules; backend refines |

Decision boundary: content with a situation→action lesson → rule; everything else → memory.
The skill is self-contained (own `references/mcp-tools.md`; no `skills/shared` dependency).

## MCP memory API

Skills orchestrate when to call MCP atomic memory tools. Optional helper: `classify_memory_scene(messages)` when scene is unclear.

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
| Rule-learning orchestration | timem-skill `skills/timem-rule-learning/` (keep consistent with MCP resource `timem://guides/rule-learning`) |
| MCP tool API | timem-skill `skills/shared/mcp-tools.md` + timem-mcp server; rule tools: `skills/timem-rule-learning/references/mcp-tools.md` |
| Legacy MCP guides | timem-mcp resources (appendix; point to timem-skill) |

## session_id conventions

| Scene | session_id |
|-------|------------|
| general | Optional; omit for cross-topic prefs; use stable topic name when scoped |
| writing | Optional series/doc name (e.g. `blog-2026`) |
| coding | Required stable repo name (e.g. `timem-mcp`) |
| rules (timem-rule-learning) | Not used — scope is `user_id` + `agent_id` (stable per role); project via `attributes`/`filters` |

Never use a random UUID per turn.
