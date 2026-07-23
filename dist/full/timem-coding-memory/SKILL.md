---
name: timem-coding-memory
description: >-
  Orchestrates TiMEM coding-scene memory recall and persistence via MCP atomic tools.
  Use when TiMEM MCP is connected and the user is doing software development, debugging,
  architecture decisions, or asks to recall technical context (代码, 调试, 架构, repo, 之前怎么定的).
  Do not use for typo/single-line format-only fixes, non-technical chit-chat, or when TiMEM MCP
  is not connected.
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

**AGENTS.md / CLAUDE.md** — team-reviewed, long-stable conventions.

**TiMEM** — agent-retrievable project knowledge: **decisions, lessons, preferences, code-verified module/architecture orientation**.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Per-turn checklist

```
- [ ] 1. Classify Must / Should / Skip (references/search-tier.md) → map to search_tier S*
- [ ] 2. If not Skip → search_memories(..., search_tier=S*) BEFORE exploratory grep/read
- [ ] 3. Verify hits vs code and AGENTS.md; if count=0 read memory_gap / guidance / elevate_create
- [ ] 4. Codebase work (read, grep, edit)
- [ ] 5. Gated WRITE EVAL only (references/write-rubric.md) → conditional create_memory
- [ ] 6. On task closure → create_memory with 4–8 turn summary if needed
```

## Search (summary)

Classify **Must / Should / Skip** before searching. Do not search every turn. Always pass `search_tier` when searching.

| Bucket | Action |
|--------|--------|
| **Must** | Explicit recall, delete lookup, cross-project plan, module/arch/design Q → search |
| **Should** | Ongoing project work, pre-arch edit, recurring debug; clarify repo if unclear → search |
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

- Do **not** classify project overview / module questions as Skip
- Do **not** skip create for verified project orientation when WRITE is gated ("just read code" is not a valid reason)
- Do **not** search every turn automatically
- Do **not** omit `search_tier` on coding `search_memories`
- Do **not** paste full files or logs into `messages`

## References

- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)
