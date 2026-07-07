## TiMEM coding memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-coding-memory** skill (install from [timem-skill](https://github.com/TiMEM-AI/timem-skill)).

`session_id` = stable repo name (e.g. `timem-platform-backend`)

### Per-turn workflow (atomic MCP tools)

1. Classify Search Tier → if not S-skip, `search_memories` **before** codebase grep/read
2. Verify hits vs code and AGENTS.md
3. Codebase work
4. Write rubric check → `create_memory` when pass
5. Closure: `create_memory` with 4–8 turns when task ends

### Rules

- Use `search_memories` / `create_memory` / `delete_memory` only
- Do **not** use `should_*`, `begin_coding_turn`, or `end_coding_turn`
- Static conventions → AGENTS.md; dynamic decisions → TiMEM (`domain=coding`)

Canonical skill: timem-skill `skills/timem-coding-memory/`
