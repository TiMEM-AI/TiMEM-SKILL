# Rule learning examples

## Example 1 — Task start recall, apply, grade

**User:** "把这个 PR 合进 main"

**Actions:**

1. RECALL EVAL → repeated risky decision → `recall_rules(query_text="linear history rules for merging a PR into main", judge_scene_text="merge PR into main branch", judge_context_text="repo timem-mcp, PR #92", agent_id="coder", mode="judged", top_k=5)`
2. Hit: "PR to main → rebase only, never merge commit" — verify it still matches repo policy
3. Rebase and merge; track the applied `rule_id`
4. Result verified (linear history kept) → `record_rule_outcome(rule_id="...", helpful=true, note="rebase kept linear history on PR #92")`

## Example 2 — Explicit never → learn immediately

**User:** "不要用 merge commit，以后都 rebase"

**Actions:**

1. Explicit always/never trigger → LEARN EVAL now, not at task end
2. `recall_rules`/`list_rules` quick check for an overlapping rule (none found)
3. `learn_rule(situation_text="merging a PR into main in this team's repos", outcome_text="use rebase; merge commits break the linear-history convention", agent_id="coder", suggested_tags=["git", "pr"], attributes={"project": "timem-mcp"})`

## Example 3 — Rule misled → helpful=false with exception

**Context:** Recalled rule "always run full test suite before push" was applied; the task was
a docs-only change and the 20-minute suite added no value.

**Actions:**

1. `record_rule_outcome(rule_id="...", helpful=false, note="exception: docs-only changes — full suite adds no signal; rule needs a code-change condition")`
2. `triggered_refine=true` (default) lets the backend narrow the rule

## Example 4 — Near-duplicate → update instead of learn

**Context:** Task taught "502 from MCP mount = port mismatch in TiMEM_API_HOST"; recall shows
an existing rule "502 errors → check TiMEM_API_HOST port".

**Actions:**

1. Overlap likely → do **not** `learn_rule`
2. `update_rule(rule_id="...", manual_lesson="502 from MCP mount or SDK → check TiMEM_API_HOST port mapping in docker-compose first")`

## Example 5 — Empty recall is normal

**User:** "帮我评审这个候选人简历"（该领域的第一个任务）

**Actions:**

1. `recall_rules(query_text="backend candidate resume review rules", agent_id="hr-reviewer")` → 0 rules
2. Proceed with the review normally — no invented constraints, no forced learn

## Example 6 — Fact, not rule → memory skill

**User:** "记住我们后端端口是 8000"

**Actions:**

1. LEARN EVAL → no situation→action lesson (a plain fact)
2. Do **not** `learn_rule`; follow the matching memory skill → `create_memory(domain="coding", ...)`

Counter-example that **is** a rule: "记住：改端口前先查 docker-compose 的映射" →
`learn_rule` (trigger: about to change a port; action: check the compose mapping first).

## Example 7 — Delete on explicit request

**User:** "把那条『必须跑全量测试』的规则删掉吧"

**Actions:**

1. `list_rules(agent_id="coder")` or `recall_rules` to locate the `rule_id`; confirm with the user if ambiguous
2. `delete_rule(rule_id="...")` — archives the rule (not a hard delete)

## Example 8 — User usage report

**User:** "看下我这个月用了多少次规则召回"

**Actions:**

1. `get_rule_usage_report(breakdown="summary", start_date="2026-07-01", end_date="2026-07-31", operation="recall")`
2. Summarize only the authenticated user's returned totals, including
   `recall_billable_tokens` when present
