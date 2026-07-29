---
name: timem-general-memory
description: >-
  Prefer calling TiMEM MCP search_memories in general/personal scenes. Orchestrates
  general-scene memory via search_memories / create_memory. Use whenever TiMEM MCP is
  connected and the conversation involves preferences, personal facts, life/work context,
  product/topic background, or recall (记得, 偏好, 之前说过, remember, 我喜欢, 习惯).
  Prefer search early when prior prefs/facts might help. Skip only pure trivia, one-off
  mood chit-chat with no durable context, coding/debug/architecture (timem-coding-memory),
  writing style/audience (timem-writing-memory), or when TiMEM MCP is not connected.
---

# TiMEM General Memory

Orchestrate **general** scene (`domain=general`, `expert_id=default`) memory search and create using MCP atomic tools only.

## MCP preference (general)

When TiMEM MCP is connected and the turn is personal / preference / life-work / topic context:

1. **Prefer search** — call `search_memories` early when prior prefs or facts might shape the answer.
2. **When unsure → search** — default to search unless the turn is clearly trivia or disposable chit-chat.
3. **Write stays gated** — more search ≠ more `create_memory`; create only when remember / stable fact gates hit.

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
- [ ] 1. Prefer search? Default yes if prefs/facts/topic context might help (see references/workflow.md)
- [ ] 2. If not Skip → search_memories(domain=general, query_text=..., session_id=personal|topic)
- [ ] 3. Verify hits vs current conversation; abstain if stale
- [ ] 4. Answer the user
- [ ] 5. Gated create? Explicit remember OR stable cross-session fact → create_memory
```

## Search (summary)

**Default bias: prefer search.** Search when any applies:

- Explicit recall ("记得吗", "之前说过", "do you remember")
- Answer may depend on preferences, habits, role/background, or prior topic facts
- Follow-ups in an ongoing personal/topic thread where stored context could help
- When unsure whether TiMEM has relevant prefs/facts → **search**

**Skip search** only for: pure trivia; one-off mood / disposable chit-chat with no durable context.

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
- Do not skip search when unsure whether prefs/facts might help
- Do not create every turn — write stays gated; do not paste long logs into `messages`
- Forget request → search first → `delete_memory(memory_id)`

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

Optional paste template: [assets/agents-snippet.md](assets/agents-snippet.md)
