# Coding memory examples

## Example 1 — S3 task start (search then work)

**User:** "继续 timem-mcp 的 MCP 挂载配置"

**Tier:** S3

**Actions:**

1. `search_memories(query_text="MCP 挂载 配置", domain="coding", session_id="timem-mcp", limit=5)`
2. Verify hits vs repo code and AGENTS.md
3. Read/edit codebase
4. Rubric check → create if durable decision made

## Example 2 — S-skip (no search)

**User:** "把这行缩进改成 4 空格"

**Tier:** S-skip

**Actions:**

1. Do **not** call `search_memories`
2. Fix indent; skip create (one-off patch)

## Example 3 — Explicit remember (create)

**User:** "请记住：这个仓库 MCP 配置用 uvx，不要 pip install -e"

**Actions:**

1. Optional search to avoid duplicate
2. `create_memory(domain="coding", session_id="timem-mcp", memory_hint="constraint", messages=[...])`

## Example 4 — Closure

**Context:** 6 turns on auth refactor; JWT chosen and implemented; user says "好了就这样"

**Actions:**

1. `create_memory(domain="coding", session_id="timem-mcp", memory_hint="decision", messages=[4–8 relevant turns])`
2. Summarize: JWT over cookies, rationale in assistant confirmation

## Example 5 — S0 explicit recall

**User:** "你记得之前 auth 怎么定的吗？"

**Tier:** S0

**Actions:**

1. `search_memories(query_text="auth 架构 决策", domain="coding", session_id="timem-mcp", limit=10)`
2. Answer from verified memories only
