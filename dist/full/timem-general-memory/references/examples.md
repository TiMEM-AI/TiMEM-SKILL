# General memory examples

## Example 1 — Preference recall (search + create)

**User:** "你记得我喜欢什么样的回答风格吗？"

**Actions:** `search_memories(query_text="回答风格 偏好", domain="general", session_id="personal", limit=5)` → verify → answer → `create_memory(session_id="personal", messages=[this exchange])`.

## Example 2 — Save preference (explicit remember)

**User:** "请记住：以后解释技术问题用中文，尽量简洁。"

**Actions:** search (optional dedup) → answer → `create_memory(domain="general", session_id="personal", messages=[...])`.

## Example 3 — Trivia (skip both)

**User:** "今天星期几？" → No search, no create.

## Example 4 — Scoped topic

**User:** "关于 TiMEM 产品，我们之前定的目标用户是谁？"

**Actions:** `search_memories(query_text="TiMEM 目标用户", session_id="timem-product", limit=5)` → answer → create.

## Example 5 — Personalized task without recall wording (search + create)

**User:** "帮我写一段自我介绍。"

**Actions:** Search `自我介绍 偏好 背景` (`session_id=personal`) → answer → create (the exchange may hold durable background).

## Example 6 — Pure mood (skip create)

**User:** "今天有点累，随便聊聊吧。" → Skip search. Skip create.
