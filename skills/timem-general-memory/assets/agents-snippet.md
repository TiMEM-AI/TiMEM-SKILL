## TiMEM general memory (Skill + MCP)

When [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) is connected, follow the **timem-general-memory** skill (install from [timem-skill](https://github.com/TiMEM-AI/timem-skill) `dist/full/` or `dist/standalone/`).

### Per-turn workflow

1. Search only on explicit recall or when the answer needs known prefs/facts
2. Verify hits vs current conversation
3. **Gated create** only on remember / stable cross-session preference or fact
4. Coding/writing tasks → use those skills (`domain=coding` / `domain=writing`)

Canonical packages: `dist/full/timem-general-memory/` or `dist/standalone/timem-general-memory/`
