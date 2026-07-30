## TiMEM general memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-general-memory** skill (prefer [timem-skill](https://github.com/TiMEM-AI/timem-skill) `dist/standalone/`; `dist/full/` also fine).

### Per-turn workflow

1. **Default: `search_memories` first** when prefs **or** durable office/topic facts could help — including without 记得/习惯; unsure → search
2. Skip search only for trivia / disposable mood / process-only narration with no durable conclusion
3. Do **not** skip search because the turn is “about work not about the person”
4. Verify hits vs current conversation
5. **Gated create** only on remember / stable pref·role / confirmed durable work·topic fact (decision, owner, deadline, meeting conclusion). More search ≠ more create. **Not** a daily work log; no auto-create on every finished task
6. Coding/writing tasks → use those skills (`domain=coding` / `domain=writing`)

Canonical packages: `dist/standalone/timem-general-memory/` (recommended) or `dist/full/timem-general-memory/`
