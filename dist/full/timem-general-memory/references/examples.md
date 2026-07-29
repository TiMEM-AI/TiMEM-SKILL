# General memory examples

## Example 1 — Preference recall (search)

**User:** "你记得我喜欢什么样的回答风格吗？"

**Actions:**

1. `search_memories(query_text="回答风格 偏好", domain="general", session_id="personal", limit=5)`
2. Verify results; answer using confirmed preferences.

## Example 2 — Save preference (create gate)

**User:** "请记住：以后解释技术问题用中文，尽量简洁。"

**Actions:**

1. Gate hits (remember) → `create_memory(domain="general", session_id="personal", messages=[user turn, assistant confirmation])`
2. Confirm what was stored.

## Example 3 — Trivia (no TiMEM)

**User:** "今天星期几？"

**Actions:** No search, no create.

## Example 4 — Scoped topic (search)

**User:** "关于 TiMEM 产品，我们之前定的目标用户是谁？"

**Actions:**

1. `search_memories(query_text="TiMEM 目标用户", domain="general", session_id="timem-product", limit=5)`
2. Answer from verified hits or say no memory found.

## Example 5 — Proactive preference search (no create)

**User:** "帮我写一段自我介绍，语气按我平时的习惯来。"

**Actions:**

1. Prefer search → `search_memories(query_text="回答风格 语气 偏好", domain="general", session_id="personal", limit=5)`
2. Answer using verified prefs; **no create** (no remember / new stable fact gate)

## Example 6 — Gate miss (no create)

**User:** "今天有点累，随便聊聊吧。"

**Actions:** Skip search (disposable mood chit-chat). No create. No skip monologue.
