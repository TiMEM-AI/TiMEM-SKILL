---
name: timem-rule-learning
description: >-
  Orchestrates the TiMEM rule-learning loop (recall, apply, grade, learn) via MCP atomic tools.
  Use on every user turn whenever TiMEM MCP is connected: call recall_rules once before the
  first substantive response or action, including simple or one-off requests. Then verify and
  apply relevant hits, grade applied rules, and learn or revise reusable lessons when warranted.
---

# TiMEM Rule Learning

Orchestrate the **rule loop** — recall → apply → grade → learn — using MCP atomic tools only.
Rules are reusable **"in situation X, do Y"** lessons: they change what the agent *does* next
time. Facts, preferences, and context without a situation→action lesson belong to the memory
skills (`create_memory`), not here.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) with all 8 public Rule tools connected (`full` or optional `rule` Tool Profile)
- MCP tools: [references/mcp-tools.md](references/mcp-tools.md) — **self-contained**; this skill does not require `skills/shared`

## Parameters

| Field | Value |
|-------|-------|
| `agent_id` | **One stable id per agent role** (e.g. `coder`, `reviewer`); default `default`. Never random per turn or session |
| `user_id` | Omit — resolved from API Key |
| Project scope | Not `session_id`: learn with `attributes={"project": "<repo>"}`, recall with `filters` (+ `include_missing_filter_keys`) — see [workflow.md](references/workflow.md) |
| Structured arguments | Pass `attributes` / `filters` as native objects and tag collections as native arrays. Never JSON-stringify or double-encode them |

## Task lifecycle checklist

```
- [ ] 1. Every user turn → recall_rules once BEFORE the first substantive response or action
      (including simple/one-off requests; an empty result is normal — proceed)
- [ ] 2. Verify each hit vs current request/files; apply only what fits; track applied rule_ids
- [ ] 3. Do the work
- [ ] 4. Result known → record_rule_outcome per APPLIED rule (helpful=true/false + note)
- [ ] 5. Task end → LEARN EVAL: did this conversation or situation produce a reliable
      situation→action rule that will remain useful across future similar situations?
      - No → learn 0 rules
      - Yes → learn_rule directly; one rule per judgement point, max 3
      - Do not run recall/list solely to judge duplicates before learning
```

## Recall (summary)

Make one mandatory baseline `recall_rules` call on every user turn, before the first
substantive response or action. Never skip it for greetings, clarification questions,
read-only answers, or tiny one-off requests. Additional recalls are allowed only when
materially new decision context appears later in the same turn.

| `mode` | Use |
|--------|-----|
| `similarity` (default) | Tag/BM25/vector retrieval only; no applicability judging |
| `judged` | Judge the complete filtered rule pool |
| `auto` | Retrieve `top_k`, judge those candidates, and fall back to retrieval if judging fails |

**Required:** one non-empty `query_text` for retrieval. Pass optional `judge_scene_text` and
`judge_context_text` only when `judged` or `auto` needs decision evidence.

Details: [references/workflow.md](references/workflow.md)

## Grade (mandatory after applying)

Once the result of an applied rule is known: `record_rule_outcome(rule_id, helpful, note)` —
one call per rule that actually influenced an action. `helpful=false` with an exception note
is what lets the backend refine the rule. Never grade unapplied rules or guess before the
outcome is observable.

## Learn (summary)

At task end, ask one primary question:

> Did the current conversation or situation reveal a reliable **"when X, do Y"** lesson
> that is likely to remain useful across future similar situations?

Learn only when the answer is clearly yes on all three dimensions:

- **Long-term reusable:** useful beyond the current item, turn, date, or temporary state.
- **Generalizable:** applies to a class of future similar situations within the current
  user/agent scope—not merely this one instance.
- **Reliable and actionable:** supported by an explicit durable instruction/correction or
  a verified outcome, and names a concrete action.

Otherwise learn **0** rules. Explicit "记住/always/never" wording or a correction triggers
an immediate evaluation, not automatic learning. Plain facts/preferences belong in memory,
static repo conventions in project files, and secrets nowhere. See
[workflow.md](references/workflow.md) and [examples.md](references/examples.md).

- `situation_text` = observable trigger **before** the decision (embedded for future recall)
- `outcome_text` = verified result + the reusable lesson
- Structured arguments keep their native MCP JSON shapes: `attributes` is an object and
  `suggested_tags` is an array. Never pass JSON text inside a string
- `suggested_tags` follow the input's primary language. For Chinese input, use concise
  Simplified Chinese for ordinary concepts; keep English only for established technical
  terms, product/framework/language names, acronyms, commands, and code identifiers
- One rule per judgement point; max **0–3** rules per task
- Backend governance is disabled by default. Temporarily do not judge overlap or run a
  pre-learn recall/list duplicate check; call `learn_rule` directly for a verified lesson

## Revise vs re-learn vs archive

| Situation | Tool |
|-----------|------|
| Rule roughly right but too broad / narrow / outdated | `update_rule` (`manual_situation` is re-embedded) |
| Genuinely new lesson | `learn_rule` |
| Applied rule, result now known | `record_rule_outcome` |
| User explicitly asks to remove a rule | `delete_rule` (archives, not hard delete) |

## Usage (on request only)

User asks for their own rule usage → `get_rule_usage_report` (`summary` or `daily`).
For recall, `recall_billable_tokens` is embedding tokens plus judge-model total tokens.

## Anti-patterns

- Do **not** learn facts or preferences without a situation→action lesson — that is `create_memory` (memory skills)
- Do **not** learn before the outcome is verified; no hindsight-only conclusions in `situation_text`
- Do **not** skip the mandatory per-turn recall because the request seems simple or one-off
- Do **not** treat recalled rules as authoritative — verify vs current request and files; empty recall ≠ invent constraints
- Do **not** call `record_rule_outcome` for recalled-but-unapplied rules
- Do **not** use recall/list solely to judge duplicates before `learn_rule`; the mandatory
  per-turn recall is for applying rules, not for gating learning
- Do **not** stringify structured tool arguments. For example,
  pass `attributes={"project": "timem-mcp"}` directly. Compatibility parsing may
  recover `attributes="{\"project\":\"timem-mcp\"}"`, but agents must not rely on it
- Do **not** put secrets or private data into rules
- Do **not** use a random `agent_id` per turn or session

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## Server-side companions

MCP prompts `rule_task_start` / `rule_session_wrap_up` wrap steps 1–2 and 5–6 of the loop;
MCP resource `timem://guides/rule-learning` is the server-side loop guide. Keep this skill
and that guide consistent when either changes. If tools are missing, read
`timem://capabilities`; Tool Profile setup is documented by
`timem://guides/tool-profiles` and remains an explicit server configuration, not a Skill action.
