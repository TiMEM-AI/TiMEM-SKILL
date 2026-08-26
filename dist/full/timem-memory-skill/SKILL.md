---
name: timem-memory-skill
description: >-
  TiMEM long-term memory skill covering coding, general, and writing domains.
  One skill replaces timem-coding-memory + timem-general-memory + timem-writing-memory.
  AUTO on EVERY turn when TiMEM MCP is connected: call search_memories BEFORE
  generating reply, then create_memory AFTER generating reply. No exceptions,
  no skip. If user message contains "记", MUST call create_memory. Pick domain
  by scene: coding (repo/debug/architecture), general (personal/office/durable
  facts), writing (copy/tone/audience/style). Ambiguous: classify_memory_scene.
---

# TiMEM Memory Skill

Use TiMEM memory with MCP (`search_memories` / `create_memory` / `delete_memory`).

One skill covering three domains (`coding`, `general`, `writing`). Pick the domain by scene, then search before reply and create after reply — every turn, no exceptions.

## Trigger

When TiMEM MCP is connected — **every turn, no exceptions**.

## Domain 选择

| 场景 | domain |
|------|--------|
| 代码/调试/架构 | `coding` |
| 个人/办公/通用 | `general` |
| 文案/写作/风格 | `writing` |

模糊时：`classify_memory_scene(messages=[...])` → returns `scene`, `expert_id`, `confidence`. If confidence is low, default to `general` or ask the user.

## Instructions

1. **选 domain** — 按上表选择 `coding` / `general` / `writing`
2. **Search**: Call `search_memories` BEFORE generating reply (pass `domain`, `query_text`; coding also passes `search_tier=S3`. **Do not pass `session_id`** — the server schema has no such field)
3. **Reply**: Generate reply using recalled context + fresh context
4. **Create**: Call `create_memory` AFTER generating reply, passing 2-4 recent turns — **every turn, no skip**
5. **"记"字强制**: If user message contains "记", MUST call `create_memory` even if you think there's nothing new to store

## Example

### Coding

Input: User asks "timem-mcp 的 rule learning 循环是怎么实现的？"

1. `search_memories(domain="coding", query_text="rule learning 循环实现", search_tier="S3")` → returns 2 hits about rule loop architecture
2. Answer the question using recalled + fresh code context
3. `create_memory(domain="coding", messages=[...recent turns...])`

### General

Input: User says "我们团队 Q3 的 OKR 是什么？"

1. `search_memories(domain="general", query_text="团队 Q3 OKR 目标")` → returns 1 hit with Q3 OKR details
2. Answer using the recalled information
3. `create_memory(domain="general", messages=[...recent turns...])`

### Writing

Input: User says "按之前的语气写一段产品介绍"

1. `search_memories(domain="writing", query_text="产品介绍 语气 风格")` → returns 1 hit with established tone guidelines
2. Write the product introduction matching the established style
3. `create_memory(domain="writing", messages=[...recent turns...])`

## Parameters

| Field | coding | general | writing |
|-------|--------|---------|---------|
| `domain` | `coding` | `general` | `writing` |
| `session_id` | **不传** — 服务端 schema 无此字段 | **不传** — 同左 | **不传** — 同左 |
| `search_tier` | `S3` 默认；`S0` 回忆；`S6` 删除前 | 不用 | 不用 |
| `memory_hint` | 6 种可选: `decision` / `constraint` / `lesson` / `convention` / `preference` / `correction` | 不用 | 不用 |
| `query_text` | 3–12 task-oriented words | 3–12 task-oriented words | 3–12 task-oriented words |
| `messages` | 2–4 recent `{role, content}` turns | 2–4 recent `{role, content}` turns | 2–4 recent `{role, content}` turns |

Never paste full files or long logs into `messages`. Never use random UUIDs per turn.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Skip

No skip. Every turn: search before reply, create after reply.

## Scene boundary

| Turn looks like | domain |
|-----------------|--------|
| Repo, debug, architecture, module questions | `coding` |
| Prefs / office durable facts / topic context | `general` |
| Copy, tone, audience, draft style | `writing` |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Forget

User asks to forget → `search_memories` (coding: `search_tier="S6"`) to get `memory_id` → confirm if ambiguous → `delete_memory(memory_id="...")`.

## References

- [mcp-tools.md](references/mcp-tools.md)
- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)

## Changelog

- 0.3.1 (2026-08-26): Remove all `session_id` requirements — server schema has no such field. Examples and parameter tables updated accordingly.
- 0.3.0 (2026-08-20): Remove all create skip conditions — create every turn, no exceptions. Server dedup handles trivial turns. Search skip conditions retained (typo/trivia/别搜).
- 0.2.0 (2026-08-19): Merge timem-coding-memory + timem-general-memory + timem-writing-memory into single skill `timem-memory-skill`. One skill, three domains, domain selection by scene.
- 0.1.0 (2026-08-18): Initial individual skill versions (coding, general, writing).