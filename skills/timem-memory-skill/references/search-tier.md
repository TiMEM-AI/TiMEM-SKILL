# Coding Search Tier (simplified)

**Default: search on every coding turn.** Call `search_memories` BEFORE exploratory codebase grep/read — even if you could just read the code. Retrieval is cheap; missed context is expensive.

## search_tier

`search_tier` is a coding-search parameter that affects empty-result behavior (`elevate_create`). You do **not** need to classify each turn — default to `S3`.

| `search_tier` | When | Call notes |
|---------------|------|------------|
| **S3** | Default — any project-bound coding turn with a known repo (implement, edit, explain, review, refactor, debug, module/arch overview, follow-up) | `session_id` + required `query_text` |
| **S0** | User explicitly asks to recall ("你记得之前怎么定的吗") | `limit=10` |
| **S6** | Before `delete_memory` | search to obtain `memory_id` |

Everything else → `S3`. When unsure → `S3` and search.

If the repo is unclear, clarify first, then search with `session_id` and `S3`.

## Recommended call

```
search_memories(
  query_text="<concise technical question>",  # required, 3–12 words
  domain="coding",
  session_id="<repo-name>",
  search_tier="S3",
  limit=5,
)
```

## Skip search (narrow only)

- Typo or single-line formatting/indent fixes
- Generic syntax with zero project context (e.g. "Python list comprehension syntax")
- Unrelated trivia
- User explicitly said "别搜"

Module/architecture/overview questions are **not** skip — always search those.

## Empty results

When `count=0` and `domain=coding`, read optional fields: `memory_gap`, `guidance`, `elevate_create`, `suggested_next`.

- Work from codebase; empty search ≠ auto-create.
- `elevate_create` is a soft hint, not a command — still apply your own judgment.