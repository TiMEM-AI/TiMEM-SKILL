# General scene workflow

## What belongs in general memory

From TiMEM `general` scene:

- Personal preferences (communication style, language, habits)
- General facts about the user (role, background)
- Life/work context that is not coding- or writing-specific

Static project rules belong in **AGENTS.md** / **CLAUDE.md**, not TiMEM.

## Search workflow

1. **Trigger check** — recall requested OR answer needs prior prefs/facts?
2. **Build query** — 3–12 words from user intent (required for API).
3. **Call**:
   ```
   search_memories(
     query_text="<concise question>",
     domain="general",
     session_id="<optional stable topic>",
     limit=5,
   )
   ```
4. **Verify** — memories are hints, not truth. Skip stale or contradictory hits.

## Create workflow

1. **Trigger check** — explicit remember OR stable cross-session fact?
2. **Summarize** — 1–3 sentences worth keeping.
3. **Call**:
   ```
   create_memory(
     domain="general",
     session_id="<same as search if scoped, else short stable id>",
     messages=[
       {"role": "user", "content": "<user's preference or fact>"},
       {"role": "assistant", "content": "<what was stored>"},
     ],
   )
   ```
4. Pass 2–4 relevant turns only.

## session_id guidance

| Use case | session_id |
|----------|------------|
| Global preference ("回答用中文") | Omit or use `personal` |
| Topic-bound ("TiMEM 产品定位") | Stable name e.g. `timem-product` |

## Scene boundary

If the turn is clearly **coding** (repo, debug, architecture) or **writing** (copy, tone, draft), follow the matching skill instead — use the correct `domain` on MCP calls.

Optional: `classify_memory_scene(messages)` when ambiguous.
