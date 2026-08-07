# General scene workflow

## What belongs

- Personal preferences, role/background
- **Durable office/topic facts** — decisions, owners, deadlines, meeting conclusions, product/project facts that will matter again across sessions
- Life/work context that is not coding- or writing-specific

**Not:** a daily work log, process-only narration, or transient in-progress state.

Static rules → **AGENTS.md** / **CLAUDE.md**.

## Search

**Default: search on every turn.** Call `search_memories` BEFORE answering — even if the user did not say remember/记得. Retrieval is cheap; missed context is expensive.

1. `search_memories(query_text=<3–12 words>, domain="general", session_id="personal"|<topic>, limit=5)`
2. Verify hits against the current conversation; abstain if stale or contradictory.

**Skip search** only for: pure trivia (e.g. "今天星期几"); user explicitly said "别搜"; a previous call this turn already returned what you need.

**Do not under-call** — "I can answer directly" or "this is work not about the person" is not a skip reason.

## Create

**Default: create after answering.** The server extracts facts and dedups against history, so passing the raw turns is enough.

- `create_memory(domain="general", session_id="personal"|<topic>, messages=[2–4 recent turns])`

**Skip create** only for: pure mood / disposable chit-chat with no durable content ("今天有点累"); process-only narration with no conclusion; nothing new vs. what you just searched; user said not to store.

More search ≠ more create judgment for you — the gate is only the narrow list above.

## session_id

**Always required** on both search and create.

| Use case | `session_id` |
|----------|--------------|
| Global preference / identity | `personal` |
| Topic / project / office thread | Stable name e.g. `timem-product`, `acme-q3` |

Never omit; never use a random UUID per turn.
