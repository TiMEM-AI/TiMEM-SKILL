# Rule learning workflow

## Scope model

Rules are scoped by **`user_id` + `agent_id`** — not by scene `domain` or `session_id` like
the memory skills.

- `agent_id` = one stable id per agent **role** (e.g. `coder`, `reviewer`). Do not mint a new
  id per turn, session, or repo — proliferation fragments the rulebase.
- Project scoping goes through **attributes**, not `agent_id`:
  - Learn: `attributes={"project": "<repo>"}` plus other stable keys (`domain`, `stage`).
  - Recall: `filters={"project": "<repo>"}`. Filters are **strict exact-match** — rules
    missing a filtered key are excluded. Add `include_missing_filter_keys=["project"]` to
    keep general (cross-project) rules visible alongside project-scoped ones.

## Recall workflow

1. **RECALL EVAL** — new task start; key, risky, ambiguous, or repeated decision; recurring
   domain; user asks to use/check rules. Skip only when history cannot change the answer.
2. **Build inputs** — `situation_text`: the current decision point, concise and specific
   (required). `context_text`: user request, evidence, constraints, code or candidate details.
3. **Call**:
   ```
   recall_rules(
     situation_text="<decision point>",
     context_text="<request / evidence / constraints>",
     agent_id="<role>",
     mode="similarity",   # judged for risky/ambiguous; auto for long/uncertain context
     top_k=5,
   )
   ```
   - `tags_hint` biases retrieval without hard-filtering; `filters` hard-filter.
   - `use_llm_refine=true` (default) lets the backend re-rank candidates.
   - `judged` and `auto` invoke backend LLM judging — slower (up to ~2 min); do not spam.
4. **Verify** — recalled rules are evidence, not truth. Check each against the current user
   request, files, and higher-priority instructions; apply only what fits and call out
   conflicts. Track the `rule_id` of every rule that actually influences an action.
5. **Empty result is normal** — no applicable rules yet; proceed without inventing constraints.

## Grade workflow (`record_rule_outcome`)

- **When**: the real result of an applied rule is known — task finished, user reacted, or
  verification done. One call per applied rule; never for recalled-but-unused rules; never
  guess before the outcome is observable.
- `helpful=true` → `note` = 1–2 sentences of concrete evidence.
- `helpful=false` → `note` = the exception or missing condition. This is the feedback that
  lets the backend narrow or revise the rule (`triggered_refine=true` by default).

## Learn workflow (LEARN EVAL)

Run at task end, and immediately on explicit triggers:

| Trigger | Example |
|---------|---------|
| Explicit remember / always / never | "记住：以后 PR 一律 rebase，不要 merge commit" |
| User corrects agent judgement / plan / output | "不是这样，先查 docker-compose 端口映射" |
| Strategy proven to work or fail | Probing for production evidence exposed a demo-only claim |
| Repeated mistake that generalizes | Same 502 root cause hit twice across tasks |

### Noise floor — do NOT learn (only valid skip reasons)

- One-off fact, preference, or context with no situation→action shape → `create_memory`
  (matching memory skill) instead
- Unverified guess or unclosed debate; outcome not yet observed
- Transient status ("breakpoint at L42"), noisy transcripts, raw logs
- Secrets or private data
- Broad advice with no trigger ("be careful", "写代码要规范")
- Static team convention that belongs in AGENTS.md / project files
- Near-duplicate of an existing rule → `update_rule` instead

### Writing quality

- `situation_text` — what was observable **before** the decision, phrased the way the
  situation will look next time (it is embedded for recall). No hindsight conclusions.
- `outcome_text` — verified result + the reusable lesson or action.
- One rule per judgement point; split unrelated lessons into separate calls.
- `suggested_tags` — short topical tags; avoid tags so specific they never match again.
- `attributes` — stable structured keys (`project`, `domain`, `stage`) for recall filtering.
- Budget: **0–3** rules per task; skip when nothing generalizes.

### Near-duplicate policy

`learn_rule` returns `action="created"` or `"merged_into_existing"`, but backend merging is
**still maturing — do not rely on it**. When overlap is likely, `recall_rules` or
`list_rules` first and prefer `update_rule` over learning a near-duplicate.

## Update and delete

- `update_rule` requires at least one field. `attributes` **merge** key-by-key by default;
  `replace_attributes=true` overwrites the whole mapping. `manual_situation` is
  **re-embedded** (changes future recall matching); `manual_lesson` changes lesson text only;
  `trigger_tags` replaces the whole tag set.
- `delete_rule` archives (soft), on explicit user intent only. Find the `rule_id` via
  `list_rules` or `recall_rules` first; confirm if ambiguous.

## Governance (control plane)

`enable_governance=true` on `learn_rule` can route risky merges/conflicts into proposals
instead of auto-applying (`conflict_scope_keys` defines the conflict-detection scope).
Proposal listing and apply/reject are control-plane capabilities, not public MCP tools.
Direct governance requests to the TiMEM console or an authorized Admin integration; see
`timem://guides/rule-admin`.

## Latency and errors

`learn_rule` / `recall_rules` / `record_rule_outcome` / `update_rule` may take up to ~120 s
(backend LLM paths). Errors return `{"status": "error", ...}` — surface the message; do not
retry blindly.

## Boundary with memory skills

This skill runs **alongside** the three memory skills: one turn can yield both a memory
(fact/preference, via the scene skill) and a rule (lesson, via `learn_rule`) — evaluate each
separately. A rule must answer: "when situation X occurs, do Y".
