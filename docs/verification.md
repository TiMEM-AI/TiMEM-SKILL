# Verification checklist

Structural checks (automated / repo review):

- [x] Three skills under `skills/timem-*` with valid `SKILL.md` frontmatter
- [x] Each `SKILL.md` under 500 lines
- [x] Skills document atomic MCP memory tools only
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

## Install smoke test

Copy skills to `.cursor/skills/`, reload Cursor, confirm `/timem-coding-memory` or auto-discovery.
