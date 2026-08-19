# Memory examples

## Coding examples

### Example 1 — Explicit remember (search + create)

**User:** "请记住：这个仓库 MCP 配置用 uvx，不要 pip install -e"

**Actions:**

1. `search_memories(query_text="MCP 配置 uvx", domain="coding", session_id="timem-mcp", search_tier="S3", limit=5)`
2. Answer → `create_memory(domain="coding", session_id="timem-mcp", memory_hint="constraint", messages=[...])`

### Example 2 — Module overview (search first, then code, then create)

**User:** "给我说一下记忆相关的模块"

**Actions:**

1. `search_memories(query_text="记忆模块 架构", domain="coding", session_id="timem-platform-backend", search_tier="S3", limit=5)`
2. If `count=0`: read `memory_gap` / `elevate_create`; verify from code (`app/memory_management`, `core/timem_core`)
3. Answer combining verified memories + codebase
4. `create_memory(memory_hint="convention", messages=[the Q + your verified summary])`

### Example 3 — Explicit recall (S0)

**User:** "你记得之前 auth 怎么定的吗？"

**Actions:**

1. `search_memories(query_text="auth 架构 决策", domain="coding", session_id="timem-mcp", search_tier="S0", limit=10)`
2. Answer from verified memories only → `create_memory` with this exchange

### Example 4 — Typo fix (skip both)

**User:** "这个变量名拼错了，改一下" → No search, no create.

### Example 5 — Task with a conclusion (search + create)

**Context:** 6 turns on auth refactor; JWT chosen and implemented; user says "好了就这样"

**Actions:** `create_memory(domain="coding", session_id="timem-mcp", memory_hint="decision", messages=[4–6 relevant turns covering the JWT choice])` — no special closure step needed, this is just the normal "create after answering".

## General examples

### Example 1 — Preference recall (search + create)

**User:** "你记得我喜欢什么样的回答风格吗？"

**Actions:** `search_memories(query_text="回答风格 偏好", domain="general", session_id="personal", limit=5)` → verify → answer → `create_memory(session_id="personal", messages=[this exchange])`.

### Example 2 — Save preference (explicit remember)

**User:** "请记住：以后解释技术问题用中文，尽量简洁。"

**Actions:** search (optional dedup) → answer → `create_memory(domain="general", session_id="personal", messages=[...])`.

### Example 3 — Trivia (skip both)

**User:** "今天星期几？" → No search, no create.

### Example 4 — Scoped topic

**User:** "关于 TiMEM 产品，我们之前定的目标用户是谁？"

**Actions:** `search_memories(query_text="TiMEM 目标用户", session_id="timem-product", limit=5)` → answer → create.

### Example 5 — Personalized task without recall wording (search + create)

**User:** "帮我写一段自我介绍。"

**Actions:** Search `自我介绍 偏好 背景` (`session_id=personal`) → answer → create (the exchange may hold durable background).

### Example 6 — Pure mood (skip create)

**User:** "今天有点累，随便聊聊吧。" → Skip search. Skip create.

## Writing examples

### Example 1 — Recall tone (search)

**User:** "帮我写产品介绍，用我们之前定的那种专业但友好的语气。"

**Actions:**

1. `search_memories(query_text="产品介绍 语气 专业 友好", domain="writing", session_id="product-copy", limit=5)`
2. Draft using verified tone constraints.

### Example 2 — Save style rule (create)

**User:** "请记住：对外文案不用感叹号，受众是开发者。"

**Actions:**

1. Gate hits → `create_memory(domain="writing", session_id="product-copy", messages=[user turn, assistant confirmation])`

### Example 3 — Series continuity

**User:** "继续写 blog-2026 系列的下一篇，风格和上一篇一致。"

**Actions:**

1. `search_memories(query_text="blog 风格 系列", domain="writing", session_id="blog-2026", limit=5)`
2. Write draft; create only if new durable style rule emerges.

### Example 4 — Draft without recall wording (search, no create)

**User:** "写一段产品介绍。"

**Actions:**

1. Default search → `search_memories(query_text="产品介绍 风格 受众", domain="writing", session_id="product-copy", limit=5)`
2. Draft using verified constraints if any; **no create** unless a new durable rule is confirmed

### Example 5 — No memory needed

**User:** "把这段改成被动语态。" (one-off edit, no new style rule)

**Actions:** Edit text; skip search/create unless user asks to remember a rule.