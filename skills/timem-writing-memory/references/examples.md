# Writing memory examples

## Example 1 — Recall tone (search)

**User:** "帮我写产品介绍，用我们之前定的那种专业但友好的语气。"

**Actions:**

1. `search_memories(query_text="产品介绍 语气 专业 友好", domain="writing", session_id="product-copy", limit=5)`
2. Draft using verified tone constraints.

## Example 2 — Save style rule (create)

**User:** "请记住：对外文案不用感叹号，受众是开发者。"

**Actions:**

1. `create_memory(domain="writing", session_id="product-copy", messages=[user turn, assistant confirmation])`

## Example 3 — Series continuity

**User:** "继续写 blog-2026 系列的下一篇，风格和上一篇一致。"

**Actions:**

1. `search_memories(query_text="blog 风格 系列", domain="writing", session_id="blog-2026", limit=5)`
2. Write draft; create only if new durable style rule emerges.

## Example 4 — No memory needed

**User:** "把这段改成被动语态。" (one-off edit, no new style rule)

**Actions:** Edit text; skip create unless user asks to remember a rule.
