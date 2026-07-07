# Writing scene workflow

## Search workflow

1. **Trigger** — need prior style, tone, audience, or series conventions?
2. **Query** — 3–12 words: style, audience, tone keywords (required).
3. **Call**:
   ```
   search_memories(
     query_text="<style or audience keywords>",
     domain="writing",
     session_id="<optional series name>",
     limit=5,
   )
   ```
4. **Apply** — use verified constraints in the draft; abstain if hits are stale.

## Create workflow

1. **Trigger** — user locks in reusable writing rules or preferences?
2. **Summarize** — style/audience/tone in 1–3 sentences.
3. **Call**:
   ```
   create_memory(
     domain="writing",
     session_id="<series name if applicable>",
     messages=[
       {"role": "user", "content": "<constraint in user's words>"},
       {"role": "assistant", "content": "<confirmation of stored style rule>"},
     ],
   )
   ```

## session_id guidance

| Use case | session_id |
|----------|------------|
| Global writing habit | Omit or `writing-default` |
| Blog series / campaign | Stable name e.g. `blog-2026` |
| Single doc project | e.g. `product-launch-copy` |

## Scene boundary

Technical implementation questions → `timem-coding-memory` (`domain=coding`).

Personal non-writing prefs → `timem-general-memory` (`domain=general`).

Optional: `classify_memory_scene(messages)` when ambiguous.

## Task end

At most **0–3** writing memories per task; prefer durable style rules over one-off phrasing.
