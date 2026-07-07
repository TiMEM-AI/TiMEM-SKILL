## TiMEM coding memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-coding-memory** skill (install from [timem-skill](https://github.com/TiMEM-AI/timem-skill)).

`session_id` = stable repo name (e.g. `timem-platform-backend`)

### Per-turn workflow (atomic MCP tools)

1. Search Tier → if not S-skip, `search_memories` **before** codebase grep/read (S3 includes module/architecture questions)
2. Verify hits vs code and AGENTS.md
3. Codebase work
4. **WRITE EVAL** before reply → `create_memory` when required rubric passes; skip with reason if not
5. Closure: `create_memory` with 4–8 turns when segment ends (≥3 substantive turns OK)

### Rules

- Use `search_memories` / `create_memory` / `delete_memory` only
- Do **not** use `should_*`, `begin_coding_turn`, or `end_coding_turn`
- Do **not** treat project overview questions as S-skip
- Static conventions → AGENTS.md; dynamic decisions → TiMEM (`domain=coding`)

Canonical skill: timem-skill `skills/timem-coding-memory/`
