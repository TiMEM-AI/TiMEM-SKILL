---
name: timem-general-memory
description: >-
  Orchestrates TiMEM general-scene memory recall and persistence via MCP atomic tools.
  Use when TiMEM MCP is connected and the conversation involves personal preferences,
  everyday facts, life/work context, or explicit recall (记得, 偏好, 之前说过, remember).
---

# TiMEM General Memory

Orchestrate **general** scene (`domain=general`, `expert_id=default`) memory search and create using MCP atomic tools only.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: see [references/mcp-tools.md](references/mcp-tools.md)

## Parameters

| Field | Value |
|-------|-------|
| `domain` | `general` |
| `session_id` | **Optional** — omit for cross-topic preferences; use stable topic name when scoped (e.g. `timem-product`, `personal`) |

Do **not** use random UUIDs per turn.

## Per-turn checklist

Copy and track:

```
- [ ] 1. Decide if search is needed (see references/workflow.md)
- [ ] 2. If yes → search_memories(domain=general, query_text=...)
- [ ] 3. Verify hits against current conversation; abstain if stale
- [ ] 4. Answer the user
- [ ] 5. Decide if create is needed (see references/workflow.md)
- [ ] 6. If yes → create_memory(domain=general, messages=2-4 turns)
```

## When to search

Search **only when**:

- User explicitly asks to recall ("记得吗", "之前说过什么", "do you remember")
- Answer depends on known preferences or facts stored in TiMEM

Do **not** search every turn or for pure trivia.

## When to create

Create when:

- User says remember / save ("请记住", "remember that")
- A **stable** personal preference or general fact useful across sessions

Do **not** create:

- One-off chit-chat, temporary mood, noise
- Facts already in project rules or obvious from context

## Delete

User asks to forget → search first → `delete_memory(memory_id)`.

## Anti-patterns

- Do not use `domain=coding` for general chat
- Do not paste long logs into `messages`

## References

- [workflow.md](references/workflow.md) — detailed search/create rules
- [examples.md](references/examples.md) — examples
- [mcp-tools.md](references/mcp-tools.md) — MCP API
