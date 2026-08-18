---
name: timem-coding-memory
description: >-
  TiMEM long-term memory for coding context (decisions, lessons, conventions,
  module/architecture orientation). AUTO on EVERY turn when TiMEM MCP is
  connected: call search_memories BEFORE generating reply, then
  create_memory AFTER generating reply. No exceptions, no skip.
  If user message contains "记", MUST call create_memory.
  Personal/office → timem-general-memory; writing style/audience →
  timem-writing-memory.
---

# TiMEM Coding Memory

`domain=coding`. The server extracts facts and dedups against history — your job is only to call the tools every coding turn.

## Trigger

When TiMEM MCP is connected — **every turn, no exceptions**.

## Instructions

1. **Search**: Call `search_memories` BEFORE generating reply (domain=coding, search_tier=S3)
2. **Reply**: Generate reply using recalled context + fresh code/work context
3. **Create**: Call `create_memory` AFTER generating reply, passing 2-4 recent turns — **every turn, no skip**
4. **"记"字强制**: If user message contains "记", MUST call `create_memory` even if you think there's nothing new to store

## Example

Input: User asks "timem-mcp 的 rule learning 循环是怎么实现的？"

1. `search_memories(domain="coding", query_text="rule learning 循环实现", session_id="timem-mcp")` → returns 2 hits about rule loop architecture
2. Answer the question using recalled + fresh code context
3. `create_memory(domain="coding", session_id="timem-mcp", messages=[...recent turns...])`

Input: User says "记住这个模块用 React 19"

1. `search_memories(domain="coding", query_text="模块 React 19", session_id="timem-mcp")`
2. Reply confirming
3. `create_memory(domain="coding", session_id="timem-mcp", messages=[...recent turns...])` — "记"字触发，必须保存

## Changelog

- 0.1.0 (2026-08-18): Initial config.yaml, added Trigger/Instructions/Example/Changelog sections per skill development spec

## Every coding turn (AUTO, no opt-in needed, no skip)

```
1) search_memories   BEFORE generating reply — every turn, no exceptions
2) reply             use recalled context + fresh code/work context
3) create_memory     AFTER generating reply — every turn, no exceptions
```

No skip conditions. No "I can just read the repo". No "this is trivia". Every turn: search before, create after.

**"记"字规则**: If user message contains "记", MUST call `create_memory`. No exceptions.

## search_tier (simplified)

Default is `S3` for almost everything. Only two exceptions:

| When | `search_tier` |
|---|---|
| Default — any coding turn with a known repo | `S3` |
| User explicitly asks to recall ("你记得之前怎么定的吗") | `S0`, `limit=10` |
| Before `delete_memory` (to get `memory_id`) | `S6` |

No Must/Should/Skip classification. When unsure → `S3`.

## Skip

No skip. Every turn: search before reply, create after reply.

## Parameters

| Field | Value |
|---|---|
| `domain` | `coding` |
| `session_id` | **Required** — stable repo/project name (e.g. `timem-mcp`); never a random UUID |
| `query_text` | 3–12 task-oriented words (required for search) |
| `search_tier` | `S3` by default; see table above |
| `messages` | 2–4 recent `{role, content}` turns; never paste full files or long logs |
| `memory_hint` | Optional — `decision` / `constraint` / `lesson` / `convention` / `preference` / `correction` |

**AGENTS.md / CLAUDE.md** — team-reviewed, long-stable conventions. **TiMEM** — agent-retrievable project knowledge: decisions, lessons, preferences, code-verified module/architecture orientation.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Scene boundary

| Turn looks like | Use |
|-----------------|-----|
| Prefs / office durable facts / topic context | `timem-general-memory` (`domain=general`) |
| Copy, tone, audience, draft style | `timem-writing-memory` (`domain=writing`) |
| Repo, debug, architecture, module questions | this skill (`domain=coding`) |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Forget

User asks to forget → `search_memories(search_tier="S6")` to get `memory_id` → confirm if ambiguous → `delete_memory(memory_id="...")`.

## References

- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)
