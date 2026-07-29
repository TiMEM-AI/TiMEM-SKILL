# Verification checklist

Structural checks (automated / repo review):

- [x] Memory/rule/knowledge skills under `skills/timem-*` with valid `SKILL.md` frontmatter
- [x] Authoring `SKILL.md` files under 500 lines; coding standalone ≤350 (warn >400); general standalone ≤220 (warn >250)
- [x] Memory skills self-contained: `references/mcp-tools.md` has no `../../shared` links
- [x] `skills/shared/mcp-tools.md` present (source of truth for sync)
- [x] `dist/full/` + `dist/standalone/` for **coding** and **general** after `python scripts/build-all.py`
- [x] Standalone frontmatter includes matching `name:`; no relative `*.md` dead links; no inlined AGENTS snippet section
- [x] Full packages ship `assets/agents-snippet.md`

Manual checks (requires timem-mcp connected):

## Coding (gated WRITE + Must/Should/Skip)

| # | Input | Expect |
|---|-------|--------|
| 1 | 「记忆模块有哪些」 | **Must/S3 search** (`search_tier`) → read code → **create** (convention / `project_discovery`) |
| 2 | 「改这行缩进」 | **Skip**: no search, no create (no WRITE monologue) |
| 3 | 「你记得 auth 怎么定的」 | **Must/S0 search**, `limit=10`, pass `search_tier` |
| 4 | 「给这个 API 加一个校验」 / mid-task follow-up | **Should/S3 search** before grep/edit (default bias) |
| 5 | 讨论后「就先用 FastAPI 这样」 | **gated create** (decision) |
| 6 | 多轮 debug 结束无「好了」但已有可复述结论 | **closure create** |
| 7 | 第二次问「记忆模块有哪些」 | search hits prior convention → answer, **no duplicate create** |
| 8 | 空搜模块概览 | read `memory_gap` / `elevate_create`; verify from code; then gated create |

## General (proactive search + gated create)

| # | Input | Expect |
|---|-------|--------|
| 1 | 「你记得我喜欢什么回答风格」 | **search** `domain=general` → answer from verified prefs |
| 2 | 「帮我写自我介绍，按我平时习惯」 | **prefer search** (prefs may help); **no create** unless gate |
| 3 | 「请记住：解释用中文」 | **gated create** |
| 4 | 「今天星期几」 | no search, no create |
| 5 | 「今天有点累随便聊聊」 | skip search; no create (noise floor) |

## Writing

See examples under `skills/timem-writing-memory/references/examples.md`.

## Rule learning (timem-rule-learning)

Structural:

- [x] `skills/timem-rule-learning/SKILL.md` valid frontmatter; folder name matches `name`
- [x] Self-contained: full tool reference in own `references/mcp-tools.md`; no `skills/shared` dependency
- [x] Tool names/parameters match timem-mcp `timem_mcp/rule_learning.py` (≥ 0.8.0)

Manual checks (requires timem-mcp connected):

| # | Input | Expect |
|---|-------|--------|
| 1 | 「不要用 merge commit，以后都 rebase」 | mandatory per-turn recall (not dedupe) → direct **learn_rule** |
| 2 | Any user turn 「把这个 PR 合进 main」 | **recall_rules** before acting → apply → **record_rule_outcome** after result known |
| 3 | Recall returns 0 rules | Proceed normally; no invented constraints, no forced learn |
| 4 | 「记住我们后端端口是 8000」 | **create_memory** (fact, no situation→action lesson), **no** learn_rule |
| 5 | Lesson may overlap an existing rule | no duplicate judgement or extra recall/list → direct **learn_rule** while governance is off |
| 6 | Recalled rule misled on this task | record_rule_outcome(**helpful=false**, note=exception) |
| 7 | 「把那条规则删了」 | list/recall to find rule_id → confirm → **delete_rule** |
| 8 | 「看下我本月 recall 用量」 | **get_rule_usage_report** summary/daily; explain `recall_billable_tokens` |
| 9 | Agent prepares `learn_rule` with attributes/tags | native object/array arguments; never JSON-stringified values |

## Install smoke test

```bash
python scripts/build-all.py
python scripts/install.py --skill coding-standalone --target agents --force
```

Confirm `/timem-coding-memory` (and `/timem-rule-learning` when installed) or auto-discovery in your client.
