---
name: timem-rule-learning
description: >-
  Orchestrates the TiMEM rule-learning loop (recall, apply, grade, learn) via MCP atomic tools.
  Use when TiMEM MCP is connected and the user corrects the agent's judgement, plan, or output,
  states an always/never rule, asks to apply or manage learned rules, or a strategy is proven
  to work or fail (规则, 记住以后都, 不要再, 复盘, always, never, don't do that again).
---

# TiMEM Rule Learning

Orchestrate the **rule loop** — recall → apply → grade → learn — using MCP atomic tools only.
Rules are reusable **"in situation X, do Y"** lessons: they change what the agent *does* next
time. Facts, preferences, and context without a situation→action lesson belong to the memory
skills (`create_memory`), not here.

## Prerequisites

- [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) ≥ 0.4.0 connected (rule tools)
- MCP tools: [references/mcp-tools.md](references/mcp-tools.md) — **self-contained**; this skill does not require `skills/shared`

## Parameters

| Field | Value |
|-------|-------|
| `agent_id` | **One stable id per agent role** (e.g. `coder`, `reviewer`); default `default`. Never random per turn or session |
| `user_id` | Omit — resolved from `TiMEM_USER_ID` |
| Project scope | Not `session_id`: learn with `attributes={"project": "<repo>"}`, recall with `filters` (+ `include_missing_filter_keys`) — see [workflow.md](references/workflow.md) |

## Task lifecycle checklist

```
- [ ] 1. Task start / key decision → RECALL EVAL: could prior rules change what I do?
- [ ] 2. If yes → recall_rules BEFORE acting (empty result is normal — proceed)
- [ ] 3. Verify each hit vs current request/files; apply only what fits; track applied rule_ids
- [ ] 4. Do the work
- [ ] 5. Result known → record_rule_outcome per APPLIED rule (helpful=true/false + note)
- [ ] 6. Task end → LEARN EVAL: verified reusable situation→action lesson? → learn_rule (0–3)
      - Overlap likely → recall/list first, prefer update_rule over a near-duplicate
```

## Recall (summary)

Recall when: new task start; risky, ambiguous, or repeated decisions; user asks to use or
check rules. Skip for tiny one-off actions history cannot change.

| `mode` | Use |
|--------|-----|
| `similarity` (default) | Fast lookup |
| `judged` | Backend LLM checks applicability per rule — risky or ambiguous decisions |
| `auto` | Backend picks a strategy — long or uncertain contexts |

**Required:** non-empty `situation_text` (the decision point, concise and specific).

Details: [references/workflow.md](references/workflow.md)

## Grade (mandatory after applying)

Once the result of an applied rule is known: `record_rule_outcome(rule_id, helpful, note)` —
one call per rule that actually influenced an action. `helpful=false` with an exception note
is what lets the backend refine the rule. Never grade unapplied rules or guess before the
outcome is observable.

## Learn (summary)

**LEARN EVAL at task end** — and immediately on explicit "记住/always/never" or a user
correction. See [workflow.md](references/workflow.md) for triggers and the noise floor.

- `situation_text` = observable trigger **before** the decision (embedded for future recall)
- `outcome_text` = verified result + the reusable lesson
- One rule per judgement point; max **0–3** rules per task
- Backend merge (`action=created|merged_into_existing`) is still maturing — when overlap is
  likely, recall/list first and prefer `update_rule`

## Revise vs re-learn vs archive

| Situation | Tool |
|-----------|------|
| Rule roughly right but too broad / narrow / outdated | `update_rule` (`manual_situation` is re-embedded) |
| Genuinely new lesson | `learn_rule` |
| Applied rule, result now known | `record_rule_outcome` |
| User explicitly asks to remove a rule | `delete_rule` (archives, not hard delete) |

## Governance and usage stats (on request only)

User asks to audit the rulebase → `list_rule_governance_proposals` /
`resolve_rule_governance_proposal`. Usage or billing questions → `get_rule_usage_*` /
`list_rule_usage_events`. Not part of the per-task loop.

## Anti-patterns

- Do **not** learn facts or preferences without a situation→action lesson — that is `create_memory` (memory skills)
- Do **not** learn before the outcome is verified; no hindsight-only conclusions in `situation_text`
- Do **not** treat recalled rules as authoritative — verify vs current request and files; empty recall ≠ invent constraints
- Do **not** call `record_rule_outcome` for recalled-but-unapplied rules
- Do **not** learn a near-duplicate when overlap is likely — recall/list first, prefer `update_rule`
- Do **not** put secrets or private data into rules
- Do **not** use a random `agent_id` per turn or session

## References

- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [mcp-tools.md](references/mcp-tools.md)

## Server-side companions

MCP prompts `rule_task_start` / `rule_session_wrap_up` wrap steps 1–2 and 5–6 of the loop;
MCP resource `timem://guides/rule-learning` is the server-side guide. Keep this skill and
that guide consistent when either changes.
