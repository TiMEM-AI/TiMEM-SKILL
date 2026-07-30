## TiMEM coding memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-coding-memory** skill (prefer [timem-skill](https://github.com/TiMEM-AI/timem-skill) `dist/standalone/`; `dist/full/` also fine).

`session_id` = stable repo name (e.g. `timem-platform-backend`)

### Per-turn workflow (atomic MCP tools)

1. Coding turn → **default `search_memories` first**; Must / Should / Skip; if not Skip, pass `search_tier=S*` **before** grep/read (unsure → Should/`S3`)
2. Do **not** skip MCP because the repo or context might answer
3. Verify hits vs code and AGENTS.md; if `count=0` read `memory_gap` / `elevate_create`
4. Codebase work
5. **Gated WRITE EVAL** → create only on remember / decision closed / correction / project orientation / closure
6. Closure: `create_memory` with 4–8 turns when segment ends (≥3 substantive turns **with a retellable conclusion**)

### Rules

- Default: call `search_memories` on programming turns; more search ≠ more create
- Use `search_memories` / `create_memory` / `delete_memory` only; always pass `search_tier` when searching
- Skip only for typo/format/trivia
- Do **not** treat project overview questions as Skip
- AGENTS.md = team conventions; TiMEM = decisions + **code-verified project orientation** (`domain=coding`)

Canonical packages: `dist/standalone/timem-coding-memory/` (recommended) or `dist/full/timem-coding-memory/` (source: `skills/timem-coding-memory/`)
