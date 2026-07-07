# General memory examples

## Example 1 — Preference recall (search)

**User:** "你记得我喜欢什么样的回答风格吗？"

**Actions:**

1. `search_memories(query_text="回答风格 偏好", domain="general", limit=5)`
2. Verify results; answer using confirmed preferences.

## Example 2 — Save preference (create)

**User:** "请记住：以后解释技术问题用中文，尽量简洁。"

**Actions:**

1. `create_memory(domain="general", session_id="personal", messages=[user turn, assistant confirmation])`
2. Confirm what was stored.

## Example 3 — No search (trivia)

**User:** "今天星期几？"

**Actions:** No TiMEM call needed unless user asks to recall something from memory.

## Example 4 — Scoped topic

**User:** "关于 TiMEM 产品，我们之前定的目标用户是谁？"

**Actions:**

1. `search_memories(query_text="TiMEM 目标用户", domain="general", session_id="timem-product", limit=5)`
2. Answer from verified hits or say no memory found.
