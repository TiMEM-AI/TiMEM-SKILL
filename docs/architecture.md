# TiMEM Skill vs MCP Architecture

## Division of labor

| Layer | Repository | Responsibility |
|-------|------------|----------------|
| **Skill** | timem-skill | When to search/create, scene-specific rules, verify steps, closure |
| **MCP** | timem-mcp | Atomic tools: `search_memories`, `create_memory`, `delete_memory`, `ready`, `search_knowledge`, `upload_document`, `list_knowledge_bases`, `list_documents` |

Skills follow the Context7-style pattern: Skill orchestrates, MCP executes.

The MCP runtime can optionally reduce its public schema with
`TiMEM_MCP_TOOL_PROFILE`. A Rule-only runtime exposes the 8 public Rule tools
plus the always-available `ready` diagnostic. This selection is explicit and
static per server instance: installing a Skill does not automatically change an
MCP server's tools, and Tool Profiles are not authorization boundaries. Use
`timem://capabilities` to inspect the active runtime surface.

```
User message
    → Agent matches skill description
    → Skill workflow (checklists, tiers, rubric)
    → MCP tool calls (search / create / delete)
    → Skill formats answer
```

## Packaging (source vs dist)

| Location | Role |
|----------|------|
| `skills/` | **Source of truth** for authors |
| `skills/shared/mcp-tools.md` | Shared MCP parameter reference (hand-edit here only) |
| `skills/timem-*-memory/references/mcp-tools.md` | **Generated** via `scripts/sync-shared-mcp-tools.py` (self-contained installs) |
| `dist/full/timem-coding-memory/` | User package — multi-file coding skill |
| `dist/standalone/timem-coding-memory/` | User package — single inlined `SKILL.md` |

Rebuild user packages: `python scripts/build-all.py`.

## Three scenes, three memory skills

MCP defines three memory scenes in `timem_mcp/scenes.py`:

| Scene | `domain` | `expert_id` | Skill |
|-------|----------|-------------|-------|
| general | `general` | `default` | timem-general-memory |
| coding | `coding` | `coder` | timem-coding-memory |
| writing | `writing` | `writer` | timem-writing-memory |
| knowledge | — | — | timem-knowledge |

**One job per skill.** The agent loads each skill's `name` + `description` at discovery; the full `SKILL.md` loads only when relevant. No router skill is required.

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
| general | Explicit recall or answer needs prefs/facts | vs current conversation | gated create (stable prefs/facts; 0–5/task) |
| writing | Style/audience recall | vs draft intent | Style, tone, audience |
| coding | Must/Should/Skip → S0–S-skip; pass `search_tier` | vs code + AGENTS.md | gated WRITE EVAL (decision/constraint/lesson/…) |
| knowledge | Document retrieval | vs user's question | Upload only when reusable |

Coding is the most detailed skill; general stays lean with dual-track `dist/` packages; writing and knowledge stay lean.

## Canonical sources

| Content | Canonical location |
|---------|-------------------|
| Coding search/write rules | `skills/timem-coding-memory/` (author); user installs from `dist/` |
| General search/write rules | `skills/timem-general-memory/` (author); user installs from `dist/` |
| Writing rules | `skills/timem-writing-memory/` |
| Rule-learning orchestration | `skills/timem-rule-learning/` (keep consistent with MCP resource `timem://guides/rule-learning`) |
| MCP tool API | `skills/shared/mcp-tools.md` (source) → synced into memory skills; rule tools: `skills/timem-rule-learning/references/mcp-tools.md` |
| Legacy MCP guides | timem-mcp resources (appendix; point to timem-skill) |

## session_id conventions

| Scene | session_id |
|-------|------------|
| general | Optional; omit for cross-topic prefs; use stable topic name when scoped |
| writing | Optional series/doc name (e.g. `blog-2026`) |
| coding | Required stable repo name (e.g. `timem-mcp`) |
| rules (timem-rule-learning) | Not used — scope is `user_id` + `agent_id` (stable per role); project via `attributes`/`filters` |
| knowledge | Not applicable — uses `kb_id` instead |

Never use a random UUID per turn.
