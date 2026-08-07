# Coding memory examples

## Example 1 — Explicit remember (search + create)

**User:** "请记住：这个仓库 MCP 配置用 uvx，不要 pip install -e"

**Actions:**

1. `search_memories(query_text="MCP 配置 uvx", domain="coding", session_id="timem-mcp", search_tier="S3", limit=5)`
2. Answer → `create_memory(domain="coding", session_id="timem-mcp", memory_hint="constraint", messages=[...])`

## Example 2 — Module overview (search first, then code, then create)

**User:** "给我说一下记忆相关的模块"

**Actions:**

1. `search_memories(query_text="记忆模块 架构", domain="coding", session_id="timem-platform-backend", search_tier="S3", limit=5)`
2. If `count=0`: read `memory_gap` / `elevate_create`; verify from code (`app/memory_management`, `core/timem_core`)
3. Answer combining verified memories + codebase
4. `create_memory(memory_hint="convention", messages=[the Q + your verified summary])`

## Example 3 — Explicit recall (S0)

**User:** "你记得之前 auth 怎么定的吗？"

**Actions:**

1. `search_memories(query_text="auth 架构 决策", domain="coding", session_id="timem-mcp", search_tier="S0", limit=10)`
2. Answer from verified memories only → `create_memory` with this exchange

## Example 4 — Typo fix (skip both)

**User:** "这个变量名拼错了，改一下" → No search, no create.

## Example 5 — Task with a conclusion (search + create)

**Context:** 6 turns on auth refactor; JWT chosen and implemented; user says "好了就这样"

**Actions:** `create_memory(domain="coding", session_id="timem-mcp", memory_hint="decision", messages=[4–6 relevant turns covering the JWT choice])` — no special closure step needed, this is just the normal "create after answering".
