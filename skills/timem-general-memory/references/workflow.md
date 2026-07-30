# General scene workflow

## What belongs

- Personal preferences, role/background
- **Durable office/topic facts** — decisions, owners, deadlines, meeting conclusions, product/project facts that will matter again across sessions
- Life/work context that is not coding- or writing-specific

**Not:** a daily work log, process-only narration, or transient in-progress state.

Static rules → **AGENTS.md** / **CLAUDE.md**.

## Search

**Default: search.** Call `search_memories` when prior prefs or durable facts might help. When unsure → search.

1. **Trigger** — explicit recall; OR prefs/habits/role/topic/office facts might matter; OR personalized or office task (write/arrange/explain/纪要/汇报/排期) without recall wording; OR ongoing personal/project follow-up; OR unsure → **search**
2. **Query** — 3–12 words (required).
3. **Call** `search_memories(query_text=..., domain="general", session_id="personal"|<topic>, limit=5)`
4. **Verify** — skip stale or contradictory hits.

**Skip search** only for: pure trivia (e.g. "今天星期几"); one-off mood / disposable chit-chat; process-only narration with no durable conclusion.

**Do not under-call** — “I can answer directly” or “this is work not about the person” is not a skip reason.

## Create (gated)

Gate hits only:

| Gate | Example |
|------|---------|
| User says remember / save | "请记住：解释用中文" |
| Stable preference confirmed | "以后尽量简洁" |
| Stable role / background | "我是后端，主要写 Python" |
| **Durable work/topic fact confirmed** | "对接人固定小王" / "方案定了走 A" / "周五前交评审" |

Then: `create_memory(domain="general", session_id="personal"|<topic>, messages=2–4 turns)`.

Max **0–5** per task. No gate → no create, no skip monologue. **No** coding-style closure auto-create on every finished task.

More search ≠ more create.

## Noise floor

One-off chit-chat, temporary mood, unverified guesses, long dumps, episodic work log ("今天改了三页 PPT"), transient state ("正在改第 3 页"), coding/writing content.

## session_id

**Always required** on both search and create.

| Use case | `session_id` |
|----------|--------------|
| Global preference / identity | `personal` |
| Topic / project / office thread | Stable name e.g. `timem-product`, `acme-q3` |

Never omit; never use a random UUID per turn.
