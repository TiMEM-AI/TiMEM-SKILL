# Knowledge Base Workflow

## What belongs in the knowledge base

- Reference documents (PDFs, reports, specs, manuals)
- Notes, meeting minutes, research summaries
- Reusable content snippets (templates, boilerplate)
- Domain-specific documents the user wants to retrieve later

**Not** for knowledge base:

- Conversation history → memory
- Code-level decisions → `domain=coding` memory
- Style preferences → `domain=writing` memory

## Knowledge vs Memory decision tree

```
User asks a question
  → Is the answer likely in an uploaded document?
    → Yes → search_knowledge(query=...)
    → No  → Is it a personal preference, past decision, or lesson?
      → Yes → search_memories(domain=..., query_text=...)
      → No  → Answer from model knowledge (no TiMEM call)
```

When ambiguous, search **both** in parallel and merge results.

## Search workflow

1. **Trigger** — user asks about content from uploaded documents, or explicitly requests KB search.
2. **Build query** — concise natural language question (required).
3. **Call**:
   ```
   search_knowledge(
     query="<user's question>",
     # kb_id omitted → auto-resolves to default KB
   )
   ```
4. **Verify** — results are document fragments, not ground truth. Cross-check if possible.
5. **Answer** — cite which document the info came from if available.

## Upload workflow

1. **Trigger** — user sends a file and wants it in the KB, or pastes content to archive.
2. **Prepare** — file content must be Base64-encoded. The agent reads the file and encodes it.
3. **Call**:
   ```
   upload_document(
     file_content="<base64-encoded-bytes>",
     filename="report.pdf",
     # kb_id omitted → uploads to default KB
   )
   ```
4. **Confirm** — returns `file_id` + `file_status: "pending"`. Processing is async.
5. **Optional follow-up** — call `list_documents(status="pending")` to check when done.

## List workflow

### List knowledge bases

When user asks "what KBs do I have?" or before first use:

```
list_knowledge_bases()
```

Returns `knowledge_bases[]` with `id`, `name`, `description`, `is_default`, `file_count`.

### List documents

When user asks what's in a KB, or to check upload status:

```
list_documents(
  # kb_id omitted → default KB
  status="success",   # optional filter
  filename="report",  # optional fuzzy search
)
```

## kb_id resolution

- Omit `kb_id` in most cases — the MCP auto-resolves to the user's default KB.
- Only pass explicit `kb_id` when user names a non-default KB.
- Get `kb_id` values from `list_knowledge_bases()` result.

## Error handling

| Error | Cause | Action |
|-------|-------|--------|
| `NO_KNOWLEDGE_BASE` | User has no KB | Tell user to create one on the platform |
| Empty search results | No matching docs | Suggest uploading relevant documents |
| Upload `pending` forever | Processing stuck | Suggest checking via `list_documents` later |

## Upload limits

- File content is Base64-encoded; practical limit ~20MB after encoding.
- Supported formats depend on backend (typically PDF, TXT, MD, DOCX).
- Processing is asynchronous — tool returns immediately with `pending` status.
