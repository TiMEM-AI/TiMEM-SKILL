# General scene workflow

## What belongs

Personal preferences, user role/background, life/work context that is not coding- or writing-specific. Static rules → **AGENTS.md** / **CLAUDE.md**.

## Search

**Default bias: prefer search.** Prefer calling `search_memories` when prior prefs or facts might help. When unsure → search. Skip only trivia or disposable chit-chat.

1. **Trigger** — explicit recall; OR prefs/habits/role/topic facts might matter; OR ongoing personal/topic follow-up; OR unsure → **search**
2. **Query** — 3–12 words (required).
3. **Call** `search_memories(query_text=..., domain="general", session_id="personal"|<topic>, limit=5)`
4. **Verify** — skip stale or contradictory hits.

**Skip search** only for: pure trivia (e.g. "今天星期几"); one-off mood / disposable chit-chat with no durable context.

## Create (gated)

Gate hits only:

| Gate | Example |
|------|---------|
| User says remember / save | "请记住：解释用中文" |
| Stable preference confirmed | "以后尽量简洁" |
| Stable role / background / cross-session fact | "我是后端，主要写 Python" |

Then: `create_memory(domain="general", session_id="personal"|<topic>, messages=2–4 turns)`.

Max **0–5** per task. No gate → no create, no skip monologue.

More search ≠ more create.

## Noise floor

One-off chit-chat, temporary mood, unverified guesses, long dumps, coding/writing content.

## session_id

**Always required** on both search and create.

| Use case | `session_id` |
|----------|--------------|
| Global preference | `personal` |
| Topic-bound | Stable name e.g. `timem-product` |

Never omit; never use a random UUID per turn.
