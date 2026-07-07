# Coding write rubric

Evaluate **before** `create_memory`. Pass 2–4 decision-relevant turns in `messages[]`.

## Explicit create triggers

| Trigger | Example |
|---------|---------|
| User says remember / save | "请记住：统一用 FastAPI + DI" |
| Technical decision closed | "We will use gRPC + Kong, settled" |
| Reusable pitfall | "TiMEM_API_HOST port mismatch causes MCP 502" |
| User correction | "We use JWT, not cookie sessions" |

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

## Rubric (all must pass for create)

- [ ] **cross_session_durable** — useful next week on same `session_id`
- [ ] **actionable** — guides implementation or debugging
- [ ] **non_noise** — summarizable in 1–3 sentences (no file dumps, raw logs)
- [ ] **non_redundant** — not already in AGENTS.md; search similar first if unsure

## Do NOT create

- Typo fixes, formatting-only changes
- Full file dumps, unclosed debates
- Rules already in AGENTS.md
- Duplicate same-session content

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

When task ends, summarize 4–8 substantive turns into one or more `create_memory` calls for anything not yet written this task.

Closure triggers: user done ("好了/先这样/thanks"); sub-task complete; topic shift; 3+ substantive turns without durable write.
