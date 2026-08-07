---
name: timem-general-memory
description: >-
  TiMEM long-term memory for personal + office/general context (prefs, habits,
  role/background, durable work facts — decisions, owners, deadlines, meeting
  conclusions). AUTO on every turn when TiMEM MCP is connected: call
  search_memories BEFORE answering, then create_memory AFTER answering. Do not
  wait for remember/记住. Skip only pure trivia or pure mood chit-chat with no
  durable content. Coding/debug/architecture → timem-coding-memory; writing
  style/audience → timem-writing-memory.
---

# TiMEM General Memory

`domain=general`. The server extracts facts and dedups against history — your job is only to call the tools every turn.

## Every turn (AUTO, no opt-in needed)

```
1) search_memories   BEFORE answering — even if the user did not say remember/记得
2) answer            use relevant hits; ignore noise; abstain if stale
3) create_memory     AFTER answering — pass 2–4 recent turns
```

Do **not** wait for "remember / 记住". Do **not** skip because you can answer without it. "This is about work, not the person" is **not** a skip reason.

## Skip (narrow)

| Skip search | Skip create |
|---|---|
| pure trivia ("今天星期几") | pure mood / disposable chit-chat ("今天有点累") |
| user said "别搜" / "don't search" | nothing new vs. what you just searched |
| | process-only narration with no durable conclusion |

When in doubt → search. False positives are cheap, missed context is expensive.

## Parameters

| Field | Value |
|---|---|
| `domain` | `general` |
| `session_id` | `personal` for prefs/identity; stable topic/project name for office work (e.g. `timem-product`, `acme-q3`). Never omit; never a random UUID. |
| `query_text` | 3–12 task-oriented words (required for search) |
| `messages` | 2–4 recent `{role, content}` turns; never paste long logs |

**Memory vs rule:** facts / preferences / context → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Scene boundary

| Turn looks like | Use |
|-----------------|-----|
| Repo, debug, architecture | `timem-coding-memory` (`domain=coding`) |
| Copy, tone, audience, draft style | `timem-writing-memory` (`domain=writing`) |
| Prefs / office durable facts / topic context | this skill (`domain=general`) |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Forget

User asks to forget → `search_memories` first → confirm if ambiguous → `delete_memory(memory_id="...")`.

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

Optional paste template: [assets/agents-snippet.md](assets/agents-snippet.md)
