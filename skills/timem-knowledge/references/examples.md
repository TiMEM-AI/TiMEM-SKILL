# Knowledge Base Examples

## Example 1 — Search knowledge base (search)

**User:** "我们之前上传的 API 设计文档里，认证方案是怎么定的？"

**Actions:**

1. `search_knowledge(query="API 认证方案")`
2. Verify results; answer using confirmed document fragments.
3. If no results → suggest user check if the document was uploaded, or search memory: `search_memories(query_text="API 认证方案", domain="coding")`.

## Example 2 — Upload document (upload)

**User:** "把这个产品需求文档上传到知识库" (user attaches PRD.pdf)

**Actions:**

1. Read the file and Base64-encode it.
2. `upload_document(file_content="<base64>", filename="PRD.pdf")`
3. Confirm upload: "已上传 PRD.pdf，文件处理中，稍后可搜索使用。"

## Example 3 — Check upload status (list_documents)

**User:** "刚才上传的文档处理好了吗？"

**Actions:**

1. `list_documents(status="pending")` — check if still processing.
2. If `status="success"` → "已处理完成，可以搜索使用了。"
3. If still `pending` → "仍在处理中，请稍后再试。"

## Example 4 — List knowledge bases (list_bases)

**User:** "我有哪些知识库？"

**Actions:**

1. `list_knowledge_bases()`
2. List each KB with name, description, file count.
3. Highlight which one is the default.
