---
name: timem-knowledge
description: >-
  Orchestrates TiMEM knowledge base search, upload, and document management via MCP atomic tools.
  Use when TiMEM MCP is connected and the user wants to search uploaded documents, upload files
  to a knowledge base, list knowledge bases, or check document status (知识库, 文档, 上传, 搜索文档,
  knowledge base, upload document).
---

# TiMEM Knowledge Base

Orchestrate **knowledge base** operations — search, upload, list — using MCP atomic tools only.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) connected
- MCP tools: see [references/mcp-tools.md](references/mcp-tools.md)

## Per-turn checklist

```
- [ ] 1. Is this a knowledge base task? (see references/workflow.md)
- [ ] 2. If search → search_knowledge(query=...)
- [ ] 3. If upload → upload_document(file_content=..., filename=...)
- [ ] 4. If list/inspect → list_knowledge_bases() or list_documents()
- [ ] 5. Verify results against user's question
- [ ] 6. Answer the user
```

## When to search knowledge

Search `search_knowledge` **only when**:

- User asks a question that might be answered by **uploaded documents** (PDFs, docs, notes)
- User explicitly asks to look up something from their knowledge base
- Answer depends on content from previously uploaded files

Do **not** use `search_knowledge` for:

- Personal preferences or conversation history → use `search_memories`
- General knowledge the model already knows
- Code repository questions → use `search_memories(domain=coding)`

## When to upload

Upload `upload_document` when:

- User sends a file and says "add to knowledge base", "归档", "上传到知识库"
- User wants to store a document for future retrieval
- User pastes content and explicitly wants it in the KB

Do **not** upload:

- Conversation snippets → use `create_memory` instead
- Temporary content with no reuse value

## When to list

- `list_knowledge_bases()` — user asks "what KBs do I have?" or before first search when unsure
- `list_documents()` — check if an upload finished processing, or browse KB contents

## kb_id guidance

| Scenario | kb_id |
|----------|-------|
| Default / user doesn't specify | Omit — auto-resolves to default KB |
| User names a specific KB | Pass the `kb_id` from `list_knowledge_bases` result |

## Knowledge vs Memory

| Aspect | Knowledge Base | Memory |
|--------|---------------|--------|
| Source | Uploaded files (PDF, MD, TXT…) | Conversation turns |
| Content | Documents, references, notes | Preferences, decisions, lessons |
| Tool | `search_knowledge` / `upload_document` | `search_memories` / `create_memory` |
| Scope | Per-knowledge-base | Per-domain + session |

When a question could be answered by either, prefer **knowledge** for factual/document content and **memory** for personal/historical context.

## Anti-patterns

- Do not use `search_knowledge` as a substitute for `search_memories`
- Do not upload conversation transcripts — use `create_memory`
- Do not call `should_*`, `begin_coding_turn`, or `end_coding_turn`
- Do not pass `file_content` without Base64 encoding

## References

- [workflow.md](references/workflow.md) — detailed search/upload/list rules
- [examples.md](references/examples.md) — examples
- [mcp-tools.md](references/mcp-tools.md) — MCP tool reference
