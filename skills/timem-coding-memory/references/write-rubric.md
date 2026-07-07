# Coding write rubric

Evaluate **before every user-visible reply** (WRITE EVAL — required). Pass 2–4 decision-relevant turns in `messages[]` when creating.

## Explicit create triggers

| Trigger | Example |
|---------|---------|
| User says remember / save | "请记住：统一用 FastAPI + DI" |
| Technical decision closed | "We will use gRPC + Kong, settled" |
| Reusable pitfall | "TiMEM_API_HOST port mismatch causes MCP 502" |
| User correction | "We use JWT, not cookie sessions" |

## Implicit create triggers

Also consider create when **no** "请记住" was said, if:

- Implementation or design discussion produced a **repeatable technical conclusion**
- User confirms a approach ("就这样" "改好了" "先这样用 FastAPI") with decision, constraint, or lesson content

## Implicit create checklist

| Type | `memory_hint` | Signal | Example |
|------|---------------|--------|---------|
| decision | `decision` | Choice closed, impl done | "改好了" "先这样用 FastAPI" |
| constraint | `constraint` | User forbids approach | "别用全局单例" |
| correction | `correction` | Fixes recurring agent mistake | "我们用的是 JWT 不是 cookie" |
| lesson | `lesson` | Debug closed | "502 是端口没对齐" |
| convention | `convention` | Project habit | "测试放 tests/unit/" |
| preference | `preference` | Repeated habit | "解释用中文" |
| skip | — | One-off / noise | typo, single-line patch |

## Rubric — required (all must pass to create)

- [ ] **cross_session_durable** — useful next week on same `session_id`
- [ ] **actionable** — guides implementation or debugging
- [ ] **non_noise** — summarizable in 1–3 sentences (no file dumps, raw logs)

## Rubric — advisory (prefer, does not alone block)

- [ ] **non_redundant** — overlap with AGENTS.md is OK to skip; if search found nothing similar, allow create; delete duplicates later if needed

## WRITE EVAL (mandatory each turn)

Before sending the user-visible reply:

- **If create:** call `create_memory` with `memory_hint` + 2–4 turns
- **If skip:** note one-line reason internally (e.g. one-off patch, no durable conclusion, debate still open)

Do not silently skip evaluation.

## Do NOT create

- Typo fixes, formatting-only changes
- Full file dumps, unclosed debates
- Pure one-off patches with no lesson
- Duplicate same-session content (unless closure catch-up)

## Priority (when choosing memory_hint)

1. constraint
2. decision
3. convention
4. preference
5. lesson

## Recommended call

```
create_memory(
  domain="coding",
  session_id="<repo-name>",
  memory_hint="decision",
  messages=[
    {"role": "user", "content": "<decision or constraint>"},
    {"role": "assistant", "content": "<confirmation of what was stored>"},
  ],
)
```

## Task budget

At most **0–5** memories per task: decision≤2, lesson≤2, other≤1.

## Closure

When a coding segment ends, summarize 4–8 substantive turns into `create_memory` for anything not yet written.

Closure triggers:

- User signals done ("好了/先这样/thanks")
- Sub-task complete or topic shift
- **≥3 substantive turns** with technical conclusions and no durable write yet — even if user did not say "好了"
