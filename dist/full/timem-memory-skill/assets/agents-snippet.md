## TiMEM memory skill (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-memory-skill** skill (prefer [timem-skill](https://github.com/TiMEM-AI/timem-skill) `dist/standalone/`; `dist/full/` also fine).

One skill covers three domains: `coding`, `general`, `writing`. Pick domain by scene:

| 场景 | domain | session_id |
|------|--------|------------|
| 代码/调试/架构 | `coding` | repo 名（必填）|
| 个人/办公/通用 | `general` | `personal` 或 topic（必填）|
| 文案/写作/风格 | `writing` | series 名（可选）|

### Per-turn workflow (atomic MCP tools)

1. **Select domain** by scene (ambiguous → `classify_memory_scene`)
2. **Search**: `search_memories` BEFORE reply — every turn, no exceptions (coding: pass `search_tier=S3`)
3. **Reply**: use recalled context + fresh context
4. **Create**: `create_memory` AFTER reply — every turn, no exceptions
5. **"记"字规则**: If user message contains "记", MUST call `create_memory`

### Rules

- Default: call `search_memories` on every turn; more search ≠ more create
- Use `search_memories` / `create_memory` / `delete_memory` only; always pass `domain` explicitly
- Search: skip only for typo/format/trivia; Create: no skip, every turn
- AGENTS.md = team conventions; TiMEM = decisions + preferences + orientation

Canonical packages: `dist/standalone/timem-memory-skill/` (recommended) or `dist/full/timem-memory-skill/` (source: `skills/timem-memory-skill/`)