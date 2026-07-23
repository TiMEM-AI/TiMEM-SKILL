# General scene workflow

## What belongs

Personal preferences, user role/background, life/work context that is not coding- or writing-specific. Static rules → **AGENTS.md** / **CLAUDE.md**.

## Search

1. **Trigger** — explicit recall **or** answer needs prior prefs/facts?
2. **Query** — 3–12 words (required).
3. **Call** `search_memories(query_text=..., domain="general", session_id="personal"|<topic>, limit=5)`
4. **Verify** — skip stale or contradictory hits.

Do **not** search every turn or for pure trivia.

## Create (gated)

Gate hits only:

| Gate | Example |
|------|---------|
| User says remember / save | "请记住：解释用中文" |
| Stable preference confirmed | "以后尽量简洁" |
| Stable role / background / cross-session fact | "我是后端，主要写 Python" |

Then: `create_memory(domain="general", session_id="personal"|<topic>, messages=2–4 turns)`.

Max **0–5** per task. No gate → no create, no skip monologue.

## Noise floor

One-off chit-chat, temporary mood, unverified guesses, long dumps, coding/writing content.

## session_id

**Always required** on both search and create.

| Use case | `session_id` |
|----------|--------------|
| Global preference | `personal` |
| Topic-bound | Stable name e.g. `timem-product` |

Never omit; never use a random UUID per turn.
