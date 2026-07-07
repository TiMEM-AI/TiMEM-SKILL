# Verification checklist (v0.1.0)

Structural checks (automated / repo review):

- [x] Three skills under `skills/timem-*` with valid `SKILL.md` frontmatter
- [x] Each `SKILL.md` under 500 lines (general: 75, writing: 71, coding: 96)
- [x] Skills document atomic MCP tools only; no primary use of `should_*` / `begin/end`
- [x] `skills/shared/mcp-tools.md` present
- [x] Git: 4 commits on `main`, tag `v0.1.0`

Manual checks in Cursor (requires timem-mcp connected):

## General

1. User: "请记住：回答尽量简洁"
2. Expect: `create_memory(domain=general, ...)`
3. User: "你记得我的回答偏好吗？"
4. Expect: `search_memories(domain=general, ...)`

## Writing

1. User: "按我们之前定的专业语气写一段产品介绍"
2. Expect: `search_memories(domain=writing, ...)`
3. After confirming style: `create_memory(domain=writing, ...)`

## Coding

1. User: "继续 timem-mcp 配置" (S3)
2. Expect: `search_memories(domain=coding, session_id=timem-mcp, ...)` before grep/read
3. User: "把这行缩进改一下" (S-skip)
4. Expect: no search; no legacy `begin_coding_turn`

## Install smoke test

Skills copied to timem-mcp `.cursor/skills/` for local testing. Reload Cursor and confirm `/timem-coding-memory` or auto-discovery.
