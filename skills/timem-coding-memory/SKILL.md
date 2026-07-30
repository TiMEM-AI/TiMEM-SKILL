---
name: timem-coding-memory
description: >-
  Calls TiMEM MCP search_memories / create_memory for coding-scene memory (decisions,
  lessons, conventions, module/architecture orientation). Use as the default skill whenever
  TiMEM MCP is connected and the user is programming: implement, edit, debug, refactor,
  explain, review, architecture, or recall (代码, 实现, 改, 调试, 架构, 模块, repo, PR,
  review, 之前怎么定的). Default: call search_memories early before exploratory grep/read;
  when unsure → Should/S3 search. Do not skip MCP because the repo might answer. Skip only
  typo/single-line format-only fixes, non-technical chit-chat, or when MCP is disconnected.
---

# TiMEM Coding Memory

Orchestrate **coding** scene (`domain=coding`, `expert_id=coder`) memory search and create using MCP atomic tools only.

## MCP preference (coding)

**Search default on; write default off.** When TiMEM MCP is connected and the turn is programming-related:

1. **Default: call `search_memories` first** (often first among tools), before exploratory codebase grep/read.
2. **Do not under-call** — “I can just read the repo” / “I can answer from context” is **not** a reason to skip MCP on coding turns.
3. **Bias** — default Should/`S3` search; when unsure → search; Skip is rare (typo / format / trivia only).
4. **Write stays gated** — more search ≠ more `create_memory`; create only when WRITE EVAL gates hit.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: [references/mcp-tools.md](references/mcp-tools.md)

## Parameters

| Field | Value |
|-------|-------|
| `domain` | `coding` |
| `session_id` | **Required** — stable repo/project name (e.g. `timem-mcp`), not random UUID per turn |

**AGENTS.md / CLAUDE.md** — team-reviewed, long-stable conventions.

**TiMEM** — agent-retrievable project knowledge: **decisions, lessons, preferences, code-verified module/architecture orientation**.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Per-turn checklist

```
- [ ] 1. Coding turn? Classify Must / Should / Skip (default Should if unsure) — Skip only typo/format/trivia
- [ ] 2. If not Skip → search_memories(..., search_tier=S*) FIRST (before exploratory grep/read)
- [ ] 3. Verify hits vs code and AGENTS.md; if count=0 read memory_gap / guidance / elevate_create
- [ ] 4. Codebase work (read, grep, edit)
- [ ] 5. Gated WRITE EVAL only (references/write-rubric.md) → conditional create_memory
- [ ] 6. On task closure → create_memory with 4–8 turn summary if needed
```

## Search (summary)

**Default: MCP search.** Classify **Must / Should / Skip**; when unsure → **Should** (`S3`) and search. Skip is rare. Always pass `search_tier` when searching.

| Bucket | Action |
|--------|--------|
| **Must** | Explicit recall, delete lookup, cross-project plan, module/arch/design Q → **search** |
| **Should** | Any ongoing project work (implement / edit / explain / review / debug / follow-up); pre-arch edit; clarify repo if unclear → **search** |
| **Skip** | Typo / single-line format / trivia / zero-project syntax only → no search |

Details: [references/search-tier.md](references/search-tier.md)

**Required:** non-empty `query_text` (3–12 words) + `search_tier` on coding searches.

## Verify (mandatory after search)

1. Treat results as evidence, not truth.
2. Compare with current code and AGENTS.md.
3. Abstain if stale or contradictory; offer to delete/update.
4. If `count=0`: read `memory_gap` / `guidance` / `elevate_create` — empty ≠ auto-create.
5. Use top summaries; optional `enable_memories_rethink=true` for synthesized context.

## Write (summary)

**Gated WRITE EVAL** — only when a gate hits (remember / decision closed / correction / `project_discovery` / closure). See [write-rubric.md](references/write-rubric.md).

- **Required:** `project_bound` + `likely_reuse`
- **Advisory:** `bounded_content`, `freshness_ok`, `non_duplicate`
- **When gated:** code-verified project answers → **create**; skip only on noise floor
- **When not gated:** no create; no skip monologue

Max **0–8** memories per task (decision≤2, lesson≤2, convention≤3, other≤1).

## Closure

Run when: user signals done; sub-task complete; topic shift; **≥3 substantive turns with a retellable conclusion** and no durable write yet.

```
create_memory(
  domain="coding",
  session_id="<repo-name>",
  memory_hint="decision|lesson|convention|...",
  messages=[4–8 recent user/assistant turns from the task],
)
```

## Anti-patterns

- Do **not** skip TiMEM MCP on coding turns because the answer “might be in the repo”
- Do **not** classify project overview / module questions as Skip
- Do **not** skip create for verified project orientation when WRITE is gated ("just read code" is not a valid reason)
- Do **not** Skip when uncertain — default to Should/`S3` search (including mid-task follow-ups)
- Do **not** omit `search_tier` on coding `search_memories`
- Do **not** paste full files or logs into `messages`

## References

- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)
