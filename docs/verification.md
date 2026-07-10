# Verification checklist

Structural checks (automated / repo review):

- [x] Four skills under `skills/timem-*` with valid `SKILL.md` frontmatter
- [x] Each `SKILL.md` under 500 lines
- [x] Skills document atomic MCP tools only; no primary use of `should_*` / `begin/end`
- [x] `skills/shared/mcp-tools.md` present

Manual checks in Cursor (requires timem-mcp connected, `timem-platform-backend` workspace):

## Coding (v0.1.2 write loosening — tier B)

| # | Input | Expect |
|---|-------|--------|
| 1 | 「记忆模块有哪些」 | **search** (S3) → read code → **create** (convention) |
| 2 | 「改这行缩进」 | **no search**, **no create** |
| 3 | 「你记得 auth 怎么定的」 | **search** (S0), `limit=10` |
| 4 | 讨论后「就先用 FastAPI 这样」 | **create** (decision) |
| 5 | 多轮 debug 结束无「好了」 | **closure create** or WRITE EVAL skip reason |
| 6 | 第二次问「记忆模块有哪些」 | search hits prior convention → answer, **no duplicate create** |

## General / Writing

See prior examples in git history for `timem-general-memory` and `timem-writing-memory`.

## Rule learning (timem-rule-learning)

Structural:

- [x] `skills/timem-rule-learning/SKILL.md` valid frontmatter; folder name matches `name`
- [x] Self-contained: full tool reference in own `references/mcp-tools.md`; no `skills/shared` dependency
- [x] Tool names/parameters match timem-mcp `timem_mcp/rule_learning.py` (≥ 0.4.0)

Manual checks in Cursor (requires timem-mcp connected):

| # | Input | Expect |
|---|-------|--------|
| 1 | 「不要用 merge commit，以后都 rebase」 | overlap check → **learn_rule** (explicit never; situation + lesson) |
| 2 | New task 「把这个 PR 合进 main」 | **recall_rules** before acting → apply → **record_rule_outcome** after result known |
| 3 | Recall returns 0 rules | Proceed normally; no invented constraints, no forced learn |
| 4 | 「记住我们后端端口是 8000」 | **create_memory** (fact, no situation→action lesson), **no** learn_rule |
| 5 | Lesson overlaps an existing rule | recall/list → **update_rule**, no near-duplicate learn |
| 6 | Recalled rule misled on this task | record_rule_outcome(**helpful=false**, note=exception) |
| 7 | 「把那条规则删了」 | list/recall to find rule_id → confirm → **delete_rule** |

## Install smoke test

Copy skills to `.cursor/skills/`, reload Cursor, confirm `/timem-coding-memory` and
`/timem-rule-learning` (when installed), or confirm auto-discovery.
