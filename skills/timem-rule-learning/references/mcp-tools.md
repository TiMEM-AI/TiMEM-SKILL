# TiMEM MCP rule-learning tools

Full parameter reference for the 8 public rule-learning tools exposed by
[timem-mcp](https://github.com/TiMEM-AI/timem-mcp). This file is **self-contained**
— unlike the memory skills, `timem-rule-learning` does not depend on `skills/shared`.

All tools scope by **`user_id` + `agent_id`**: omit `user_id` (resolved from `TiMEM_USER_ID`);
pass one stable `agent_id` per agent role (default `"default"`). Backend: `/api/v1/rules/*`.

Core loop tools (`learn_rule`, `recall_rules`, `record_rule_outcome`, `update_rule`) may take
up to ~120 s — they invoke backend LLM paths.

---

## `recall_rules`

Recall rules from one caller-owned retrieval query. Empty result is normal.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query_text` | **Yes** | One concise retrieval query (1–4000 chars) |
| `judge_scene_text` | No | Decision scene for `judged` / `auto` (max 4000 chars) |
| `judge_context_text` | No | Evidence or longer context for `judged` / `auto` (max 30000 chars) |
| `agent_id` | Recommended | Stable role id |
| `mode` | No | `similarity` (default, retrieval only) / `judged` (complete filtered pool) / `auto` (retrieve `top_k`, then judge with fallback) |
| `top_k` | No | Default 5 (1–50) |
| `tags_hint` | No | Up to 32 tags; biases retrieval without hard-filtering |
| `filters` | No | Exact-match scalar attributes; max 16 keys / 8 KiB |
| `include_missing_filter_keys` | No | Up to 32 filter keys that should NOT exclude rules lacking that attribute |

```
recall_rules(
  query_text="linear history rules for merging a PR into main",
  judge_scene_text="merge PR into main branch",
  judge_context_text="repo timem-mcp, PR #92",
  agent_id="coder",
  mode="judged",
  top_k=5,
)
```

Results include each rule's `rule_id` — keep it for `record_rule_outcome`. The aggregate
retrieval field is `retrieval_score`; route/rank, fallback, applicability, evidence, and
`judgement` fields may also be present.

---

## `learn_rule`

Create a reusable rule from a situation and its verified outcome.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `situation_text` | **Yes** | Observable trigger **before** the decision; 1–4000 chars |
| `outcome_text` | **Yes** | Verified result + the reusable lesson; 1–4000 chars |
| `agent_id` | Recommended | Stable role id |
| `suggested_tags` | No | Up to 32 short topical tags; not hyper-specific |
| `attributes` | No | Stable keys (`project`, `domain`, `stage`) for recall-time filtering; max 32 top-level keys / 16 KiB |

Ordinary calls return `action="created"` and `merged_into=null`. When overlap is likely,
recall/list first and prefer `update_rule`.

---

## `record_rule_outcome`

Grade a rule after it actually influenced an action and the result is known.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `rule_id` | **Yes** | From `recall_rules` results |
| `helpful` | **Yes** | `false` if the rule misled, did not apply, or needed an exception |
| `note` | Recommended | 1–2 sentences of evidence; for `helpful=false` describe the exception |
| `triggered_refine` | No | Default `true` — allow the backend to revise the rule |

---

## `update_rule`

Patch rule metadata or manually revise its text. At least one update field is required.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `rule_id` | **Yes** | Rule to update |
| `manual_situation` | No | Revised trigger; **re-embedded** — changes future recall matching |
| `manual_lesson` | No | Revised lesson text only |
| `attributes` | No | **Merged** key-by-key by default |
| `replace_attributes` | No | `true` overwrites the whole attributes mapping |
| `trigger_tags` | No | **Replaces** the whole tag set |
| `name` / `is_enabled` / `status` | No | Metadata curation; status: `active`, `archived`, `disabled`, `pending_review`, `deprecated`, `superseded` |

---

## `list_rules`

List rules in a `user_id` + `agent_id` scope.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `page` / `page_size` | No | Defaults 1 / 20 (max 100) |
| `status` / `is_enabled` | No | Lifecycle filters |
| `tags` | No | Tag filter |
| `attr_key` + `attr_value` | No | Single attribute filter |
| `min_helpful_rate` | No | 0.0–1.0 |
| `sort` | No | `last_used_at_desc` (default), `created_at_desc`, `usage_count_desc`, `helpful_rate_desc` |

---

## `get_rule` / `delete_rule`

`get_rule(rule_id)` — fetch one rule. `delete_rule(rule_id)` — **archive** (soft delete), on
explicit user intent only; locate the id via `list_rules` / `recall_rules` first.

---

## `get_rule_usage_report`

Read-only usage for the authenticated user. The tool does not accept `user_id`.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `breakdown` | No | `summary` (default) or `daily` |
| `start_date` / `end_date` | No | Inclusive `YYYY-MM-DD` range |
| `agent_id` | No | Stable role filter; omit for all of the user's agents |
| `operation` | No | `learn` or `recall` |

`recall_billable_tokens` equals embedding tokens plus judge-model total tokens.

---

## Server-side companions

| Type | Name | Use |
|------|------|-----|
| Resource | `timem://guides/rule-learning` | Server-side loop guide |
| Prompt | `rule_task_start` | Recall applicable rules at task start |
| Prompt | `rule_session_wrap_up` | Grade applied rules + learn 0–3 new rules at task end |
