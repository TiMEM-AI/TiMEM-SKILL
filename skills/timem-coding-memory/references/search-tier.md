# Coding Search Tier model

Classify each user message **before** calling `search_memories`. Do not search every turn.

| Tier | When | Example | Action |
|------|------|---------|--------|
| **S0** | User explicitly asks to recall | "你记得吗" "之前 auth 怎么定的" | `search_memories(domain=coding, query_text=...)` |
| **S1** | Cross-project planning | "今天该做什么" | search without `session_id`; `limit=10` |
| **S2** | Project work but repo unclear | No project name in message | Clarify repo → search with `session_id` |
| **S3** | Project-bound technical work | "继续 MCP 挂载" "记忆模块有哪些" "L1-L5 怎么分层" | `domain=coding`, `session_id=repo`, **required query_text** |
| **S4** | Before architecture / cross-module edits | "改 middleware 顺序" | query expresses intent |
| **S5** | Debugging recurring symptom | "又 502 了" | query with symptom keywords |
| **S6** | Before `delete_memory` | User wants to delete | search to obtain `memory_id` |
| **S-skip** | Narrow fix / unrelated trivia only | typo, indent, "1+1" | **Do not search** |

## Project technical questions (S3)

When `session_id` is known, classify as **S3** (not S-skip) if the user asks about:

- Module layout or responsibilities ("记忆模块有哪些")
- Architecture, layers, or design ("L1-L5 怎么分层")
- Project conventions or past technical decisions in this repo

Flow: **search first** → verify hits vs code/AGENTS.md → then read codebase. Memories supplement code; they do not replace verification.

After a code-verified answer with `likely_reuse`, apply write-rubric **`project_discovery`** — default create (`memory_hint=convention`). See [write-rubric.md](write-rubric.md).

## S-skip (narrow only)

Use S-skip **only** for:

- Typo or single-line formatting/indent fixes
- Unrelated chit-chat with no project context
- Generic syntax with zero project context (e.g. "Python list comprehension syntax")

## Do NOT classify as S-skip

- "模块有哪些" / "架构是什么" / project overview questions
- Any technical discussion when `session_id` applies
- Recalling historical decisions or lessons (use S0 or S3 search instead)

## Do NOT search

- Unrelated trivia
- Every turn automatically

**Note:** AGENTS.md may contain static conventions — you may still **search** for historical **decisions, lessons, or corrections** not fully captured there.

## Recommended call

```
search_memories(
  query_text="<concise technical question>",  # required, 3–12 words
  domain="coding",
  session_id="<repo-name>",  # S3–S6 when repo is known
  limit=5,  # task-start; use 10 for explicit recall (S0, S1)
)
```

## Order rule

When tier is not S-skip: call `search_memories` **before** exploratory codebase grep/read.

After S-skip: proceed directly to codebase work.

## Empty results

Zero hits: work from code, then apply write rubric — verified project orientation with `likely_reuse` defaults to **create** (`project_discovery`).
