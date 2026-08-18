---
name: timem-general-memory
description: >-
  TiMEM long-term memory for personal + office/general context (prefs, habits,
  role/background, durable work facts — decisions, owners, deadlines, meeting
  conclusions). AUTO on EVERY turn when TiMEM MCP is connected: call
  search_memories BEFORE generating reply, then create_memory AFTER generating
  reply. No exceptions, no skip. If user message contains "记", MUST call
  create_memory. Coding/debug/architecture → timem-coding-memory; writing
  style/audience → timem-writing-memory.
---

# TiMEM General Memory

`domain=general`. The server extracts facts and dedups against history — your job is only to call the tools every turn.

## Trigger

When TiMEM MCP is connected — **every turn, no exceptions**.

## Instructions

1. **Search**: Call `search_memories` BEFORE generating reply (domain=general)
2. **Reply**: Generate reply using relevant hits; ignore noise; abstain if stale
3. **Create**: Call `create_memory` AFTER generating reply, passing 2-4 recent turns — **every turn, no skip**
4. **"记"字强制**: If user message contains "记", MUST call `create_memory` even if you think there's nothing new to store

## Example

Input: User says "我们团队 Q3 的 OKR 是什么？"

1. `search_memories(domain="general", query_text="团队 Q3 OKR 目标", session_id="acme-q3")` → returns 1 hit with Q3 OKR details
2. Answer using the recalled information
3. `create_memory(domain="general", session_id="acme-q3", messages=[...recent turns...])`

Input: User says "记一下，下周三开会"

1. `search_memories(domain="general", query_text="下周三 开会", session_id="personal")`
2. Reply confirming
3. `create_memory(domain="general", session_id="personal", messages=[...recent turns...])` — "记"字触发，必须保存

## Changelog

- 0.1.0 (2026-08-18): Initial config.yaml, added Trigger/Instructions/Example/Changelog sections per skill development spec

## Every turn (AUTO, no opt-in needed, no skip)

```
1) search_memories   BEFORE generating reply — every turn, no exceptions
2) reply             use relevant hits; ignore noise; abstain if stale
3) create_memory     AFTER generating reply — every turn, no exceptions
```

No skip conditions. No "this is trivia". No "this is just chit-chat". Every turn: search before, create after.

**"记"字规则**: If user message contains "记", MUST call `create_memory`. No exceptions.

## Skip

No skip. Every turn: search before reply, create after reply.

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
