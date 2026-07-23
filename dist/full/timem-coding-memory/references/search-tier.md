# Coding Search Tier model

Classify each user message **before** calling `search_memories`. Decide with the **Must / Should / Skip** table first; map to an `S*` value for the `search_tier` parameter. Do not search every turn.

## Primary buckets

| Bucket | When | Map to `search_tier` | Action |
|--------|------|----------------------|--------|
| **Must** | Explicit recall; delete lookup; cross-project planning; project module / architecture / design questions | `S0`, `S1`, `S3` (overview), `S6` | **Search**; pass `search_tier` |
| **Should** | Ongoing project work with known repo; repo unclear (clarify first); before arch / cross-module edits; recurring debug | `S2`, `S3` (ongoing), `S4`, `S5` | **Search** (after clarify if `S2`); pass `search_tier` |
| **Skip** | Typo / single-line format only; unrelated trivia; zero-project syntax | `S-skip` | **Do not search** |

### Skip (narrow only)

Use Skip **only** for:

- Typo or single-line formatting/indent fixes
- Unrelated chit-chat with no project context
- Generic syntax with zero project context (e.g. "Python list comprehension syntax")

### Do NOT classify as Skip

- "模块有哪些" / "架构是什么" / project overview → **Must** (`S3`)
- Technical discussion when `session_id` applies → **Should** or **Must**
- Historical decisions / lessons → **Must** (`S0`) or **Should** (`S3`)

**Note:** AGENTS.md may hold static conventions — still **search** for historical decisions, lessons, or corrections not fully captured there.

## S* parameter map (pass as `search_tier`)

| `search_tier` | When | Call notes |
|---------------|------|------------|
| **S0** | User explicitly asks to recall | `limit=10` |
| **S1** | Cross-project planning | no `session_id`; `limit=10` |
| **S2** | Project work but **repo unclear** | Clarify repo → then search with `session_id` |
| **S3** | Project-bound technical work (incl. module/arch overview) | `session_id` + required `query_text` |
| **S4** | Before architecture / cross-module edits | query expresses intent |
| **S5** | Debugging recurring symptom | symptom keywords in query |
| **S6** | Before `delete_memory` | search to obtain `memory_id` |
| **S-skip** | Narrow fix / trivia only | do not call search |

### Project technical questions (`S3`, bucket Must)

When `session_id` is known, use **Must** / `S3` (not Skip) for:

- Module layout or responsibilities
- Architecture, layers, or design
- Project conventions or past technical decisions in this repo

Flow: **search first** (with `search_tier`) → verify vs code/AGENTS.md → then read codebase.

After a code-verified answer with `likely_reuse`, apply write-rubric **`project_discovery`**. See [write-rubric.md](write-rubric.md).

## Recommended call

```
search_memories(
  query_text="<concise technical question>",  # required, 3–12 words
  domain="coding",
  session_id="<repo-name>",  # omit for S1; required when repo known
  search_tier="S3",  # required for coding — enables empty-search elevate_create
  limit=5,  # task-start; use 10 for S0 / S1
)
```

## Order rule

When bucket is not Skip: call `search_memories` **before** exploratory codebase grep/read.

After Skip: proceed directly to codebase work.

## Empty results

When `count=0` and `domain=coding`, read optional fields: `memory_gap`, `guidance`, `elevate_create`, `suggested_next`.

- Work from codebase; empty search ≠ auto-create.
- `elevate_create` is a soft signal for gated WRITE EVAL only (needs non-empty `search_tier` + `session_id` from MCP).
- Verified project orientation with `likely_reuse` → default **create** via `project_discovery` when write gate hits.
