---
name: timem-coding-memory
description: >-
  TiMEM long-term memory for coding context (decisions, lessons, conventions,
  module/architecture orientation). AUTO on every coding turn when TiMEM MCP is
  connected: call search_memories BEFORE exploratory codebase work, then
  create_memory AFTER answering. Do not skip because "the repo might answer".
  Skip only typo/single-line format fixes or pure trivia. Personal/office →
  timem-general-memory; writing style/audience → timem-writing-memory.
---

# TiMEM Coding Memory

`domain=coding`. The server extracts facts and dedups against history — your job is only to call the tools every coding turn.

## Trigger

When TiMEM MCP is connected and the user is doing any of:
- Coding, debugging, architecture, or module-related work
- Asking about repo decisions, conventions, or lessons
- Any turn where exploratory grep/read of codebase would happen

## Instructions

1. **Search**: Call `search_memories` BEFORE exploratory codebase work (domain=coding, search_tier=S3)
2. **Verify**: Check recalled hits vs current code/AGENTS.md; apply only what fits
3. **Work**: Do the coding task
4. **Create**: Call `create_memory` AFTER answering, passing 2-4 relevant turns

## Example

Input: User asks "timem-mcp 的 rule learning 循环是怎么实现的？"

1. `search_memories(domain="coding", query_text="rule learning 循环实现", session_id="timem-mcp")` → returns 2 hits about rule loop architecture
2. Read the recalled context, verify against actual code
3. Answer the question using recalled + fresh code context
4. `create_memory(domain="coding", session_id="timem-mcp", messages=[...recent turns...])`

## Changelog

- 0.1.0 (2026-08-18): Initial config.yaml, added Trigger/Instructions/Example/Changelog sections per skill development spec

## Every coding turn (AUTO, no opt-in needed)

```
1) search_memories   BEFORE exploratory grep/read — even if you could just read the code
2) work              verify hits vs code/AGENTS.md; if count=0 read memory_gap / elevate_create
3) create_memory     AFTER answering — pass 2–4 relevant turns
```

Do **not** wait for "remember / 请记住". "I can just read the repo" is **not** a skip reason. Module/architecture/overview questions are coding turns — search, don't skip.

## search_tier (simplified)

Default is `S3` for almost everything. Only two exceptions:

| When | `search_tier` |
|---|---|
| Default — any coding turn with a known repo | `S3` |
| User explicitly asks to recall ("你记得之前怎么定的吗") | `S0`, `limit=10` |
| Before `delete_memory` (to get `memory_id`) | `S6` |

No Must/Should/Skip classification. When unsure → `S3`.

## Skip (narrow)

| Skip search | Skip create |
|---|---|
| typo / single-line format fix | unverified guess (summarized without reading code) |
| pure trivia ("Python list comprehension syntax") | transient debug state ("breakpoint at L42") |
| user said "别搜" / "don't search" | nothing new vs. what you just searched |

When in doubt → search. False positives are cheap, missed context is expensive.

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
