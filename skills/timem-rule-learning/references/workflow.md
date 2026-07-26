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

1. **Mandatory per-turn recall** — on every user turn, call `recall_rules` once before the
   first substantive response or action. This includes greetings, clarification questions,
   read-only answers, and tiny one-off requests. Never silently skip the baseline call.
2. **Build inputs** — derive one concise, non-empty `query_text` from the current request and
   active task context.
   For `judged` / `auto`, add `judge_scene_text` (decision point) and
   `judge_context_text` (request, evidence, constraints, code or candidate details).
3. **Call**:
   ```
   recall_rules(
     query_text="<retrieval query>",
     agent_id="<role>",
     mode="similarity",   # default: retrieval only
     top_k=5,
   )
   ```
   - `tags_hint` biases retrieval without hard-filtering; `filters` hard-filter.
   - `judged` checks the complete filtered pool. `auto` retrieves `top_k` and judges those
     candidates; failed judging falls back to retrieval.
   - For either judging mode, pass only the decision evidence needed through
     `judge_scene_text` and `judge_context_text`.
4. **Verify** — recalled rules are evidence, not truth. Check each against the current user
   request, files, and higher-priority instructions; apply only what fits and call out
   conflicts. Track the `rule_id` of every rule that actually influences an action.
5. **Empty result is normal** — no applicable rules yet; proceed without inventing constraints.
6. **Avoid duplicate baseline calls** — the mandatory call also satisfies recall for the
   current decision when its query already covers that context. Recall again in the same turn
   only after materially new decision context appears.

## Grade workflow (`record_rule_outcome`)

- **When**: the real result of an applied rule is known — task finished, user reacted, or
  verification done. One call per applied rule; never for recalled-but-unused rules; never
  guess before the outcome is observable.
- `helpful=true` → `note` = 1–2 sentences of concrete evidence.
- `helpful=false` → `note` = the exception or missing condition. This is the feedback that
  lets the backend narrow or revise the rule (`triggered_refine=true` by default).

## Learn workflow (LEARN EVAL)

`LEARN EVAL` is a judgement step, not an automatic `learn_rule` call. At task end, ask:

> Did this conversation or situation reveal a reliable **"when X, do Y"** rule that will
> remain useful across future similar situations?

Also evaluate immediately after explicit "记住/以后都/always/never" wording, a user
correction, or a clearly proven success/failure. These are evaluation triggers, not automatic
approval to learn.

### Core decision

Learn only when all three are clearly true:

1. **Long-term reusable** — useful after the current item, turn, date, or temporary state.
2. **Generalizable** — applies to a class of future similar situations, not only this
   instance. Generality is within the current `user_id` + `agent_id` scope; it need not be
   universal for every user or project.
3. **Reliable and actionable** — supported by an explicit durable instruction/correction or
   a verified outcome, and expressible as an observable situation plus a concrete action.

If any point is false or uncertain, learn **0** rules. Do not force ordinary task details
into a reusable lesson.

### Route or skip

- Durable fact/preference without a situation→action lesson → matching memory skill.
- Static repository/team convention → `AGENTS.md` or project files.
- Current-only request, transient status, unverified inference, raw log, secret/private data,
  or vague advice → do not persist as a rule.
- One choice or user silence is not evidence of a long-term rule. An explicit future
  instruction is sufficient evidence; an inferred strategy needs a verified result.

### Writing quality

- `situation_text` — what was observable **before** the decision, phrased the way the
  situation will look next time (it is embedded for recall). No hindsight conclusions.
- `outcome_text` — verified result + the reusable lesson or action.
- One rule per judgement point; split unrelated lessons into separate calls.
- `suggested_tags` — short topical tags in the input's primary language; avoid tags so
  specific they never match again. When the input is mainly Chinese, use concise Simplified
  Chinese for ordinary concepts. Keep English only for established technical terms,
  product/framework/language names, acronyms, commands, or code identifiers (for example,
  `MCP`, `API`, `LangGraph`, `Python`, `git rebase`). Do not turn ordinary Chinese concepts
  such as “简历评估” into English tags such as `resume evaluation`.
- `attributes` — stable structured keys (`project`, `domain`, `stage`) for recall filtering.
- Budget: **0–3** rules per task; keep only distinct, high-value lessons. Zero is normal.

### Duplicate handling — temporarily disabled

Do not assess whether a proposed lesson overlaps an existing rule, and do not call
`recall_rules` or `list_rules` solely for a duplicate check before learning. The mandatory
per-turn recall remains, but it is for applying relevant rules and is not a learning gate.
With backend governance disabled by default, call `learn_rule` directly for each verified
lesson; ordinary calls create a rule with `action="created"` and `merged_into=null`.

Use `update_rule` only when a specific existing rule is already known and explicitly needs
manual revision, not as the result of a speculative overlap search.

## Update and delete

- `update_rule` requires at least one field. `attributes` **merge** key-by-key by default;
  `replace_attributes=true` overwrites the whole mapping. `manual_situation` is
  **re-embedded** (changes future recall matching); `manual_lesson` changes lesson text only;
  `trigger_tags` replaces the whole tag set.
- `delete_rule` archives (soft), on explicit user intent only. Find the `rule_id` via
  `list_rules` or `recall_rules` first; confirm if ambiguous.

## Usage statistics

Use `get_rule_usage_report(breakdown="summary"|"daily")` only when the user asks for their
own learn/recall usage. Optional filters are `start_date`, `end_date`, `agent_id`, and
`operation`. `recall_billable_tokens` equals embedding tokens plus judge-model total tokens.

## Latency and errors

`learn_rule` / `recall_rules` / `record_rule_outcome` / `update_rule` may take up to ~120 s
(backend LLM paths). Errors return `{"status": "error", ...}` — surface the message; do not
retry blindly.

## Boundary with memory skills

This skill runs **alongside** the three memory skills: one turn can yield both a memory
(fact/preference, via the scene skill) and a rule (lesson, via `learn_rule`) — evaluate each
separately. A rule must answer: "when situation X occurs, do Y".
