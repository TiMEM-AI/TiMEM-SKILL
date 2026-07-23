# Coding write rubric

**Gated WRITE EVAL** — run the create/skip judgment only when a gate below hits. Pass 2–4 relevant turns in `messages[]` when creating.

**Default bias (when gated):** project-bound + likely reuse + not in noise floor → **CREATE**.

When **no gate** hits: do **not** create; do **not** require a skip reason.

## When to run WRITE EVAL (gates)

Run CREATE/SKIP evaluation if **any** applies:

| Gate | Example |
|------|---------|
| User says remember / save | "请记住：统一用 FastAPI + DI" |
| Technical decision closed or user confirms approach | "We will use gRPC + Kong, settled" / "就这样" "改好了" |
| User correction / reusable pitfall | "We use JWT, not cookie sessions" / port mismatch → 502 |
| `project_discovery` | Code-verified module/arch/orientation answer (see below) |
| Closure triggers | Done / sub-task complete / topic shift / ≥3 substantive turns **with a retellable conclusion** and no durable write yet |

## `project_discovery` (default create when gated)

When answering **Must/`S3` project technical questions** (modules, architecture, layers, data flow, conventions):

1. Verify answer from codebase (not guesswork)
2. `search_memories` returned **count=0** or existing memories are **incomplete**
3. Agent produces a retellable summary → **default `create_memory`**, `memory_hint=convention`

Includes subsystem maps, entry points, and call-chain orientation (paths + responsibilities; ≤10 bullets OK).

If search already has a **highly similar** complete entry → skip duplicate (noise floor).

## `memory_hint` checklist

| Type | `memory_hint` | Signal | Example |
|------|---------------|--------|---------|
| convention | `convention` | Module/arch map, data flow, project habit | "记忆模块在 app/memory_management" |
| decision | `decision` | Choice closed, impl done | "改好了" "先这样用 FastAPI" |
| constraint | `constraint` | User forbids approach | "别用全局单例" |
| correction | `correction` | Fixes recurring agent mistake | "我们用的是 JWT 不是 cookie" |
| lesson | `lesson` | Debug closed | "502 是端口没对齐" |
| preference | `preference` | Repeated habit | "解释用中文" |
| skip | — | Noise floor only | typo, unverified guess |

`memory_hint` is an **agent typing hint** for coding creates; MCP may not persist it to the Engine today.

## Rubric — required (all must pass to create)

- [ ] **project_bound** — knowledge for this `session_id` / repo; not generic syntax or unrelated trivia
- [ ] **likely_reuse** — any of:
  - User may ask again (module list, data flow, entry points)
  - Guides future implementation or debugging (including path navigation)
  - **30-day test:** still useful next week on same `session_id`

## Rubric — advisory (prefer, does not alone block)

- [ ] **bounded_content** — structured summary; bullet lists of modules + paths + roles OK; no full files or raw logs
- [ ] **freshness_ok** — prefer paths and responsibilities over volatile implementation details; update or delete if structure changes
- [ ] **non_duplicate** — search first; skip if highly similar entry exists; **no similar hit → prefer create**

## WRITE EVAL (when gated)

```
project_bound + likely_reuse + not in noise floor → CREATE
else → SKIP with one-line reason from noise floor only
```

- **If create:** `create_memory` with `memory_hint` + 2–4 turns
- **If skip (gated):** one-line reason citing noise floor
- **If not gated:** no create; no skip monologue

## Noise floor — Do NOT create (only valid skip reasons when gated)

- Typo / single-line format / pure one-off patch
- **Unverified guess** (summarized without reading code)
- Unclosed debate
- **Transient debug state** ("breakpoint currently at L42")
- Verbatim paste: full files, long logs, large stack traces
- Search hit with **highly similar** existing memory (true duplicate)

## NOT valid skip reasons (when gated)

- "AGENTS.md might cover this"
- "Just introducing project structure"
- "User did not say 请记住"

## Priority (when choosing memory_hint)

1. constraint
2. decision
3. convention (includes subsystem map / orientation)
4. preference
5. lesson

## Recommended call

```
create_memory(
  domain="coding",
  session_id="<repo-name>",
  memory_hint="convention",
  messages=[
    {"role": "user", "content": "<project technical question>"},
    {"role": "assistant", "content": "<verified summary: modules, paths, roles>"},
  ],
)
```

## Task budget

At most **0–8** memories per task: decision≤2, lesson≤2, convention≤3, other≤1.

## Closure

When a coding segment ends, summarize 4–8 substantive turns into `create_memory` for anything not yet written (closure is a WRITE gate).

Closure triggers:

- User signals done ("好了/先这样/thanks")
- Sub-task complete or topic shift
- **≥3 substantive turns with a retellable technical conclusion** and no durable write yet — even if user did not say "好了"
