# Verification checklist

Structural checks (automated / repo review):

- [x] Three skills under `skills/timem-*` with valid `SKILL.md` frontmatter
- [x] Each `SKILL.md` under 500 lines
- [x] Skills document atomic MCP tools only; no primary use of `should_*` / `begin/end`
- [x] `skills/shared/mcp-tools.md` present

Manual checks in Cursor (requires timem-mcp connected, `timem-platform-backend` workspace):

## Coding (v0.1.1 loosened triggers)

| # | Input | Expect |
|---|-------|--------|
| 1 | 「记忆模块有哪些」 | **search** (S3); then read code |
| 2 | 「改这行缩进」 | **no search** (S-skip) |
| 3 | 「你记得 auth 怎么定的」 | **search** (S0), `limit=10` |
| 4 | 讨论后「就先用 FastAPI 这样」 | **create** (decision) or WRITE EVAL with reason |
| 5 | 多轮 debug 结束无「好了」 | consider **closure create** or WRITE EVAL skip reason |

## General / Writing

See prior examples in git history for `timem-general-memory` and `timem-writing-memory`.

## Install smoke test

Copy skills to `.cursor/skills/`, reload Cursor, confirm `/timem-coding-memory` or auto-discovery.
