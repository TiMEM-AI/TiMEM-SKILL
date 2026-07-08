# MCP tools (knowledge base)

Use these tools for knowledge base operations. No `domain` parameter needed — knowledge base is a separate system from memory.

Full parameter reference: [shared mcp-tools.md](../../shared/mcp-tools.md) — install `skills/shared` to `.cursor/skills/shared`.

---

## `search_knowledge`

Semantic search within a knowledge base (BM25 hybrid retrieval).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query` | **Yes** | Natural language question |
| `kb_id` | No | Omit to use default KB |
| `user_id` | No | Overrides env default |

Example:
```
search_knowledge(query="认证方案设计")
```

---

## `upload_document`

Upload a document to a knowledge base (async processing).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `file_content` | **Yes** | Base64-encoded file bytes |
| `filename` | **Yes** | Original filename with extension |
| `kb_id` | No | Omit to use default KB |
| `user_id` | No | Overrides env default |

Example:
```
upload_document(file_content="<base64>", filename="design-doc.md")
```

---

## `list_knowledge_bases`

List all knowledge bases for the current user (read-only).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `user_id` | No | Overrides env default |

Returns: `knowledge_bases[]` with `id`, `name`, `description`, `is_default`, `file_count`.

---

## `list_documents`

List documents in a knowledge base (read-only).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `kb_id` | No | Omit to use default KB |
| `status` | No | Filter: `pending` / `success` / `failed` |
| `filename` | No | Fuzzy search by filename |
| `limit` | No | Default 50, max 100 |
| `offset` | No | Pagination offset |

---

Do not use `search_memories` or `create_memory` for knowledge base operations — they are separate systems.
