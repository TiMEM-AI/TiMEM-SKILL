# General memory examples

## Example 1 — Preference recall (search)

**User:** "你记得我喜欢什么样的回答风格吗？"

**Actions:** `search_memories(query_text="回答风格 偏好", domain="general", session_id="personal", limit=5)` → verify → answer.

## Example 2 — Save preference (create gate)

**User:** "请记住：以后解释技术问题用中文，尽量简洁。"

**Actions:** Gate (remember) → `create_memory(domain="general", session_id="personal", messages=[...])`.

## Example 3 — Trivia (no TiMEM)

**User:** "今天星期几？" → No search, no create.

## Example 4 — Scoped topic (search)

**User:** "关于 TiMEM 产品，我们之前定的目标用户是谁？"

**Actions:** `search_memories(query_text="TiMEM 目标用户", domain="general", session_id="timem-product", limit=5)`.

## Example 5 — Personalized task without recall wording (search, no create)

**User:** "帮我写一段自我介绍。"

**Actions:** Search `自我介绍 偏好 背景` (`session_id=personal`); **no create**.

## Example 6 — Stable background (create gate)

**User:** "我是后端，主要写 Python。"

**Actions:** Optional search → gate (role/background) → `create_memory(..., session_id="personal", ...)`.

## Example 7 — Gate miss (no create)

**User:** "今天有点累，随便聊聊吧。" → Skip search. No create.

## Example 8 — Office durable fact (create gate)

**User:** "就这样定了：Q3 方案走 A，对接人小王，周五前交评审。"

**Actions:** Optional search → gate (durable work/topic fact) → `create_memory(..., session_id="acme-q3", ...)`. Store the reusable conclusion only — not a meeting diary.

## Example 9 — Office follow-up (search, no create)

**User:** "帮我按上次定的写一封催评审的邮件。"

**Actions:** Search `评审 截止 对接人` (`session_id=acme-q3`); draft from hits; **no create** unless a new durable fact is confirmed.

## Example 10 — Episodic work log (no create)

**User:** "今天改了三页 PPT，开完会挺累。" → Skip search (process/mood, no durable conclusion). **No create**.
