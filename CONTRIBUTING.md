# Contributing to timem-skill

Thank you for contributing TiMEM Agent Skills.

## Repository layout

```
skills/
├── shared/mcp-tools.md              # MCP tool reference SOURCE (hand-edit only here)
├── timem-general-memory/            # authoring source (multi-file)
├── timem-writing-memory/
├── timem-coding-memory/             # authoring source (multi-file)
├── timem-rule-learning/             # self-contained (own mcp-tools.md)
└── timem-knowledge/
scripts/
├── sync-shared-mcp-tools.py         # shared → each memory skill references/mcp-tools.md
├── build-coding-standalone.py       # dist/full + dist/standalone (coding)
├── build-general-standalone.py      # dist/full + dist/standalone (general)
├── build-all.py
└── install.py
dist/
├── full/timem-coding-memory/        # user package (generated)
├── full/timem-general-memory/
├── standalone/timem-coding-memory/  # user package (generated, single SKILL.md)
└── standalone/timem-general-memory/
```

Each skill folder must contain `SKILL.md` with valid YAML frontmatter (`name`, `description`). Keep authoring `SKILL.md` under 500 lines; put detail in `references/`. Coding standalone targets **≤350** (warn >400); general standalone targets **≤220** (warn >250). After changing coding or general orchestration sources, run `python scripts/build-all.py` so `dist/` stays in sync. Standalone quality gates: no relative `*.md` dead links, examples renumbered 1..N, no inlined AGENTS snippet (use `dist/full/.../assets/agents-snippet.md`).

## Development

1. Edit skill content under `skills/<skill-name>/`.
2. Edit MCP parameter docs only in `skills/shared/mcp-tools.md` — **do not** hand-edit generated `skills/timem-*-memory/references/mcp-tools.md`.
3. After changing shared, coding, or general references, run:

   ```bash
   python scripts/build-all.py
   ```

   This syncs MCP docs into memory skills and refreshes coding + general `dist/`.
4. Keep `name` in frontmatter matching the folder name.
5. Write `description` in third person with clear trigger terms (WHAT + WHEN).
6. Link references one level deep from `SKILL.md`.
7. Do not duplicate full MCP policy logic — skills orchestrate; timem-mcp executes.

## Commits

Use conventional prefixes:

- `feat(skill):` — new or updated skill content
- `docs:` — README, installation, architecture
- `chore:` — repo scaffolding / build scripts

## Branches

- `main` — stable
- `feat/<name>/...`, `fix/<name>/...`, `docs/<name>` — changes

## Version tags

Skill package versions (`v0.1.0`, …) are independent of timem-mcp releases.

## Pull requests

- One scene per skill; avoid merging unrelated scenes into one authoring `SKILL.md`.
- Update `docs/installation.md` if install paths change.
- Include refreshed `dist/` when coding skill or shared MCP docs change.
- Phase-2 timem-mcp doc links may be updated in the timem-mcp repo separately.
