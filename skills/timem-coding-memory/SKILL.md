---
name: timem-coding-memory
description: >-
  Orchestrates TiMEM coding-scene memory recall and persistence via MCP atomic tools.
  Use when TiMEM MCP is connected and the user is doing software development, debugging,
  architecture decisions, or asks to recall technical context (代码, 调试, 架构, repo, 之前怎么定的).
paths: "**/*.{py,ts,tsx,js,jsx,go,rs,java,kt,cs,cpp,h,c,hpp,md,json,yml,yaml,toml}"
---

# TiMEM Coding Memory

Orchestrate **coding** scene (`domain=coding`, `expert_id=coder`) memory search and create using MCP atomic tools only.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: [references/mcp-tools.md](references/mcp-tools.md)

## Parameters

| Field | Value |
|-------|-------|
| `domain` | `coding` |
| `session_id` | **Required** — stable repo/project name (e.g. `timem-mcp`), not random UUID per turn |

Static repo rules → **AGENTS.md** / **CLAUDE.md**. Dynamic decisions and lessons → TiMEM coder space.

## Per-turn checklist

```
- [ ] 1. Classify Search Tier (references/search-tier.md)
- [ ] 2. If not S-skip → search_memories BEFORE exploratory codebase grep/read
- [ ] 3. Verify hits vs current code and AGENTS.md
- [ ] 4. Codebase work (read, grep, edit)
- [ ] 5. Write rubric check (references/write-rubric.md)
- [ ] 6. If pass → create_memory with memory_hint when applicable
- [ ] 7. On task closure → create_memory with 4–8 turn summary (see below)
```

## Search (summary)

Classify tier **before** searching. Do not search every turn.

| Tier | Action |
|------|--------|
| S0–S6 | Search when tier table says so |
| S-skip | Do **not** search (typo, trivia, narrow fix) |

Details: [references/search-tier.md](references/search-tier.md)

**Required:** non-empty `query_text` (3–12 words).

## Verify (mandatory after search)

1. Treat results as evidence, not truth.
2. Compare with current code and AGENTS.md.
3. Abstain if stale or contradictory; offer to delete/update.
4. Use top summaries; optional `enable_memories_rethink=true` for synthesized context.

## Write (summary)

Create when rubric passes: decisions, constraints, lessons, conventions worth keeping across sessions.

Details: [references/write-rubric.md](references/write-rubric.md)

Max **0–5** memories per task (decision≤2, lesson≤2, other≤1).

## Closure

Run when: user signals done; sub-task complete; topic shift; 3+ substantive turns without durable write.

```
create_memory(
  domain="coding",
  session_id="<repo-name>",
  memory_hint="decision|lesson|...",
  messages=[4–8 recent user/assistant turns from the task],
)
```

## Anti-patterns

- Do **not** call `should_search_memories`, `should_create_memory`, `begin_coding_turn`, `end_coding_turn`
- Do **not** search on S-skip or every turn automatically
- Do **not** paste full files or logs into `messages`

## References

- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)
