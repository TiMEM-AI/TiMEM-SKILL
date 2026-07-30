---
name: timem-general-memory
description: >-
  Calls TiMEM MCP search_memories / create_memory for personal + office/general
  memory (prefs, habits, role/background; durable work facts — decisions, owners,
  deadlines, meeting conclusions, topic facts; cross-session context). Not a daily
  work log. Use when TiMEM MCP is connected and the turn may depend on stored
  prefs/facts — including without explicit recall wording (帮我, 习惯, 安排, 日程,
  会议, 结论, 对接, 截止, 排期, 项目, 纪要, 偏好, 背景, 我是, 以后, 按我的, 记住,
  记得, preference, habit, remember, schedule, meeting, deadline, owner,
  background). Default: search early; when unsure → search. Skip only pure trivia,
  disposable mood chit-chat, process-only narration with no durable conclusion,
  coding/debug/architecture (timem-coding-memory), writing style/audience
  (timem-writing-memory), or when MCP is disconnected.
---

# TiMEM General Memory

Orchestrate **general** scene (`domain=general`, `expert_id=default`) memory search and create using MCP atomic tools only.

**Scope:** prefs/identity **and** durable office/topic facts. **Not** a daily work log.

## MCP preference (general)

**Search default on; write default off.** When TiMEM MCP is connected:

1. **Default: call `search_memories` first** when prefs, habits, role/background, office/topic facts, or cross-session context could shape the answer — even if the user did not say remember/记得.
2. **When unsure → search** — Skip only pure trivia, disposable mood chit-chat, or process-only narration with no durable conclusion.
3. **Do not under-call** — “I can answer directly” / “this is work not about the person” is **not** a reason to skip search.
4. **Write stays gated** — more search ≠ more `create_memory`; create only when remember / stable fact gates hit. No per-task closure auto-create.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: see [references/mcp-tools.md](references/mcp-tools.md)

## Parameters

| Field | Value |
|-------|-------|
| `domain` | `general` |
| `session_id` | **Required** — `personal` for global prefs; stable topic/project name for office work (e.g. `timem-product`, `acme-q3`). Never omit; never use random UUIDs. |

**Memory vs rule:** facts / preferences / context → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Per-turn checklist

```
- [ ] 1. Skip only trivia / mood / process-only with no conclusion; else search_memories FIRST
- [ ] 2. search_memories(domain=general, query_text=3–12 words, session_id=personal|topic, limit=5)
- [ ] 3. Verify hits vs current conversation; abstain if stale
- [ ] 4. Answer the user
- [ ] 5. Gated create? remember / stable pref·role / durable work·topic fact confirmed → create_memory
```

## Search (summary)

**Default: search** on recall; prefs/role; prior topic/office facts; office tasks (纪要/汇报/排期/安排); personal/project follow-ups; or when unsure. **Even without** 习惯/记得.

**Skip search** only: trivia; disposable mood; process-only with no durable conclusion ("刚开完会挺累").

Details: [references/workflow.md](references/workflow.md)

## Write (summary)

**Gated create** only when: remember/save; stable preference or role/background; **durable** work/topic fact confirmed (decision, owner, deadline, meeting conclusion).

Do **not** create episodic work logs, transient state, mood, guesses, or coding/writing content. No auto-create on task end without a gate.

Max **0–5**/task. No gate → no create, no skip monologue.

## Scene boundary

| Turn looks like | Use |
|-----------------|-----|
| Repo, debug, architecture | `timem-coding-memory` (`domain=coding`) |
| Copy, tone, audience, draft style | `timem-writing-memory` (`domain=writing`) |
| Prefs / office durable facts / topic context | this skill (`domain=general`) |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Anti-patterns

- Do not treat office turns as out-of-scope because they are “about work not about the person”
- Do not skip search because the model can answer without tools or the user omitted 记得/习惯
- Do not skip search when unsure whether prefs/facts might help
- Do not create every turn or every finished task — write stays gated; not a work diary
- Do not paste long logs into `messages`
- Forget request → search first → `delete_memory(memory_id)`

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

Optional paste template: [assets/agents-snippet.md](assets/agents-snippet.md)
