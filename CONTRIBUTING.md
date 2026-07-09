# Contributing to timem-skill

Thank you for contributing TiMEM Agent Skills.

## Repository layout

```
skills/
├── shared/mcp-tools.md       # Shared MCP tool reference (not a skill)
├── timem-general-memory/
├── timem-writing-memory/
├── timem-coding-memory/
└── timem-rule-learning/      # Self-contained (own references/mcp-tools.md)
```

Each skill folder must contain `SKILL.md` with valid YAML frontmatter (`name`, `description`). Keep `SKILL.md` under 500 lines; put detail in `references/`.

## Development

1. Edit skill content under `skills/<skill-name>/`.
2. Keep `name` in frontmatter matching the folder name.
3. Write `description` in third person with clear trigger terms (WHAT + WHEN).
4. Link references one level deep from `SKILL.md`.
5. Do not duplicate full MCP policy logic — skills orchestrate; timem-mcp executes.

## Commits

Use conventional prefixes:

- `feat(skill):` — new or updated skill content
- `docs:` — README, installation, architecture
- `chore:` — repo scaffolding

## Branches

- `main` — stable
- `feat/<name>`, `docs/<name>` — changes

## Version tags

Skill package versions (`v0.1.0`, …) are independent of timem-mcp releases.

## Pull requests

- One scene per skill; avoid merging unrelated scenes into one SKILL.md.
- Update `docs/installation.md` if install paths change.
- Phase-2 timem-mcp doc links may be updated in the timem-mcp repo separately.
