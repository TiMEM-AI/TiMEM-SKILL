# Coding Search Tier model

Classify each user message **before** calling `search_memories`. Do not search every turn.

| Tier | When | Example | Action |
|------|------|---------|--------|
| **S0** | User explicitly asks to recall | "你记得吗" "之前 auth 怎么定的" | `search_memories(domain=coding, query_text=...)` |
| **S1** | Cross-project planning | "今天该做什么" | search without `session_id`; `limit=10` |
| **S2** | Project work but repo unclear | No project name in message | Clarify repo → search with `session_id` |
| **S3** | Project task start (implicit) | "继续 MCP 挂载" | `domain=coding`, `session_id=repo`, **required query_text** |
| **S4** | Before architecture / cross-module edits | "改 middleware 顺序" | query expresses intent |
| **S5** | Debugging recurring symptom | "又 502 了" | query with symptom keywords |
| **S6** | Before `delete_memory` | User wants to delete | search to obtain `memory_id` |
| **S-skip** | Narrow fix / trivia | typo, indent, "1+1" | **Do not search** |

## Do NOT search

- Generic syntax questions answerable without project context
- Unrelated trivia
- Every turn automatically
- Facts already in AGENTS.md / CLAUDE.md

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

Zero hits does **not** mean create immediately. Work from code; apply write rubric when a durable decision or lesson emerges.
