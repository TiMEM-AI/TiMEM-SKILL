<!-- Generated from skills/shared/mcp-tools.md; do not edit by hand. Run: python scripts/sync-shared-mcp-tools.py -->

# MCP tools (general scene)

Use **`domain=general`**. `session_id` is optional (omit for cross-topic preferences).

Atomic MCP memory tools only. Full parameter reference follows.

---

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
| `search_tier` | Coding: **strongly recommended** | `S0`–`S6` / `S-skip` from timem-coding-memory Search Tier; enables empty-search `elevate_create` |
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

---

## `list_knowledge_bases`

List all knowledge bases for the current user.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `user_id` | No | Overrides env default |

Returns `knowledge_bases[]` with `id`, `name`, `description`, `is_default`, `file_count`, `created_at`.

---

## `search_knowledge`

Semantic search within a knowledge base (BM25 hybrid retrieval with keyword boost).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query` | **Yes** | Natural language question |
| `kb_id` | No | Omit to use default KB |
| `user_id` | No | Overrides env default |

Example:
```
search_knowledge(query="API 认证方案")
```

---

## `upload_document`

Upload a document to a knowledge base. Processing is async — returns immediately with `pending` status.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `file_content` | **Yes** | Base64-encoded file bytes |
| `filename` | **Yes** | Original filename with extension |
| `kb_id` | No | Omit to use default KB |
| `user_id` | No | Overrides env default |

Example:
```
upload_document(file_content="<base64>", filename="report.pdf")
```

---

## `list_documents`

List documents in a knowledge base with optional filters.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `kb_id` | No | Omit to use default KB |
| `status` | No | Filter: `pending` / `success` / `failed` |
| `filename` | No | Fuzzy search by filename |
| `limit` | No | Default 50, max 100 |
| `offset` | No | Pagination offset |

---

## Scene → domain mapping

| domain | expert_id (backend) |
|--------|---------------------|
| `general` | `default` |
| `coding` | `coder` |
| `writing` | `writer` |
