## TiMEM coding memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-coding-memory** skill (install from [timem-skill](https://github.com/TiMEM-AI/timem-skill) `dist/full/` or `dist/standalone/`).

`session_id` = stable repo name (e.g. `timem-platform-backend`)

### Per-turn workflow (atomic MCP tools)

1. Must / Should / Skip → if not Skip, `search_memories(..., search_tier=S*)` **before** codebase grep/read
2. Verify hits vs code and AGENTS.md; if `count=0` read `memory_gap` / `elevate_create`
3. Codebase work
4. **Gated WRITE EVAL** → create only on remember / decision closed / correction / project orientation / closure
5. Closure: `create_memory` with 4–8 turns when segment ends (≥3 substantive turns **with a retellable conclusion**)

### Rules

- Use `search_memories` / `create_memory` / `delete_memory` only; always pass `search_tier` when searching
- Do **not** treat project overview questions as Skip
- AGENTS.md = team conventions; TiMEM = decisions + **code-verified project orientation** (`domain=coding`)

Canonical packages: `dist/full/timem-coding-memory/` or `dist/standalone/timem-coding-memory/` (source: `skills/timem-coding-memory/`)
