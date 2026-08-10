# TiMEM MCP atomic tools (shared reference)

Skills orchestrate **when** to call these tools. Requires [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected in your MCP client.

Use atomic MCP memory tools only: `search_memories`, `create_memory`, `delete_memory` (and `classify_memory_scene` when domain is unclear).

Always pass **`domain`** explicitly (`general` | `coding` | `writing`). Do not rely on `TIMEM_AUTO_SCENE` in skill workflows.

---

## `search_memories`

Semantic search over stored memories.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query_text` | **Yes** | 3–12 task-oriented words; empty query causes API error |
| `domain` | Recommended | `general` / `coding` / `writing` → filters expert space |
| `session_id` | Scene-dependent | See each skill; stable name, not random UUID per turn. General: always pass `personal` or topic. |
| `search_tier` | Coding: recommended | `S3` by default; `S0` for explicit recall, `S6` before delete; enables empty-search `elevate_create` |
| `limit` | No | Default 10; use 5 for task-start, 10 for explicit recall |

Example:

```
search_memories(
  query_text="auth JWT decision",
  domain="coding",
  session_id="timem-mcp",
  search_tier="S3",
  limit=5,
)
```

### Empty coding search (`domain=coding`, `count=0`)

Response may include (does **not** auto-create):

| Field | Meaning |
|-------|---------|
| `memory_gap` | No hits for this query in coding space |
| `guidance` | Short next-step hint from MCP |
| `elevate_create` | Soft signal to consider create after verify (needs `search_tier` + `session_id`) |
| `suggested_next` | Often includes `create_memory` |

Work from codebase; apply the coding skill write rubric before `create_memory`.

---

## `create_memory`

Create memories from conversation turns (async on backend; waits by default).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `messages` | **Yes** | 2–4 decision-relevant turns; `{role, content}` |
| `session_id` | **Yes** | Stable scope. Coding: repo name. General: always `personal` or topic (never omit). Writing: series/doc name. |
| `domain` | Recommended | `general` / `coding` / `writing` |
| `memory_hint` | No | Coding only: `decision` \| `constraint` \| `lesson` \| `convention` \| `preference` \| `correction`. Agent typing hint; MCP may not persist it to Engine today. |

Example:

```
create_memory(
  domain="general",
  session_id="personal",
  messages=[
    {"role": "user", "content": "Remember I prefer concise answers."},
    {"role": "assistant", "content": "Stored: prefer concise answers."},
  ],
)
```

---

## `delete_memory`

Soft-delete one memory by ID. Requires user intent.

1. `search_memories` to find `memory_id` (coding: tier S6).
2. Confirm with user if ambiguous.
3. `delete_memory(memory_id="...")`

---

## `ready`

Health check after install or when other tools fail with auth/network errors.

---

## `classify_memory_scene` (optional)

When unsure which `domain` to use, classify recent messages:

```
classify_memory_scene(messages=[...])
```

Returns `scene`, `expert_id`, `confidence`. If confidence is low, default to `general` or ask the user.

---

## Scene → domain mapping

| domain | expert_id (backend) |
|--------|---------------------|
| `general` | `default` |
| `coding` | `coder` |
| `writing` | `writer` |
