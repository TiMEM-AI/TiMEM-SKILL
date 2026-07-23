---
name: timem-general-memory
description: >-
  Orchestrates TiMEM general-scene memory recall and persistence via MCP atomic tools.
  Use when TiMEM MCP is connected and the conversation involves personal preferences,
  everyday facts, life/work context, or explicit recall (记得, 偏好, 之前说过, remember).
  Do not use for coding/debug/architecture (timem-coding-memory), writing style/audience
  (timem-writing-memory), pure trivia, or when TiMEM MCP is not connected.
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
| `session_id` | **Required** — `personal` for global prefs, or a stable topic name (e.g. `timem-product`). Never omit; never use random UUIDs. |

**Memory vs rule:** facts / preferences / context → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Per-turn checklist

```
- [ ] 1. Search? Explicit recall OR answer needs known prefs/facts (references/workflow.md)
- [ ] 2. If yes → search_memories(domain=general, query_text=..., session_id=personal|topic)
- [ ] 3. Verify hits vs current conversation; abstain if stale
- [ ] 4. Answer the user
- [ ] 5. Gated create? Explicit remember OR stable cross-session fact → create_memory
```

## Search (summary)

Search **only when**:

- User explicitly asks to recall ("记得吗", "之前说过", "do you remember")
- Answer depends on preferences or facts likely stored in TiMEM

Do **not** search every turn or for pure trivia.

Details: [references/workflow.md](references/workflow.md)

## Write (summary)

**Gated create** — only when:

- User says remember / save
- A **stable** preference, role/background, or cross-session fact is confirmed

Do **not** create one-off chit-chat, temporary mood, unverified guesses, or content that belongs in coding/writing scenes.

Max **0–5** memories per task.

## Scene boundary

| Turn looks like | Use |
|-----------------|-----|
| Repo, debug, architecture | `timem-coding-memory` (`domain=coding`) |
| Copy, tone, audience, draft style | `timem-writing-memory` (`domain=writing`) |
| Personal prefs / general facts | this skill (`domain=general`) |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Anti-patterns

- Do not use `domain=coding` / `domain=writing` for general chat
- Do not search or create every turn; do not paste long logs into `messages`
- Forget request → search first → `delete_memory(memory_id)`

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

Optional paste template: [assets/agents-snippet.md](assets/agents-snippet.md)
