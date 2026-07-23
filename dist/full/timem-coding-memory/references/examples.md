# Coding memory examples

## Example 1 — Should/S3 task start (search then work)

**User:** "继续 timem-mcp 的 MCP 挂载配置"

**Bucket:** Should · **search_tier:** S3

**Actions:**

1. `search_memories(query_text="MCP 挂载 配置", domain="coding", session_id="timem-mcp", search_tier="S3", limit=5)`
2. Verify hits vs repo code and AGENTS.md
3. Read/edit codebase
4. Gated WRITE EVAL → create only if a gate hits (decision closed / orientation / closure)

## Example 2 — Explicit remember (create gate)

**User:** "请记住：这个仓库 MCP 配置用 uvx，不要 pip install -e"

**Actions:**

1. Optional `search_memories(..., search_tier="S3")` to avoid duplicate
2. Gate hits (remember) → `create_memory(domain="coding", session_id="timem-mcp", memory_hint="constraint", messages=[...])`

## Example 3 — Closure

**Context:** 6 turns on auth refactor; JWT chosen and implemented; user says "好了就这样"

**Actions:**

1. Closure gate → `create_memory(domain="coding", session_id="timem-mcp", memory_hint="decision", messages=[4–8 relevant turns])`
2. Summarize: JWT over cookies, rationale in assistant confirmation

## Example 4 — Must/S0 explicit recall

**User:** "你记得之前 auth 怎么定的吗？"

**Bucket:** Must · **search_tier:** S0

**Actions:**

1. `search_memories(query_text="auth 架构 决策", domain="coding", session_id="timem-mcp", search_tier="S0", limit=10)`
2. Answer from verified memories only

## Example 5 — Must/S3 project overview + empty gap (default create)

**User:** "给我说一下记忆相关的模块"

**Bucket:** Must · **search_tier:** S3 (project technical — **not** Skip)

**Actions:**

1. `search_memories(query_text="记忆模块 架构 L1 L5", domain="coding", session_id="timem-platform-backend", search_tier="S3", limit=5)`
2. If `count=0`: read `memory_gap` / `guidance` / `elevate_create`; work from code (`app/memory_management`, `core/timem_core`)
3. Answer combining verified memories + codebase
4. `project_discovery` gate → **default `create_memory`** (`memory_hint=convention`): modules, paths, roles (≤10 bullets)
5. If highly similar complete entry exists → skip duplicate only

## Example 6 — Gate miss (no create, no skip monologue)

**User:** "把这行缩进改成 4 空格"

**Bucket:** Skip · **search_tier:** S-skip

**Actions:**

1. Do **not** call `search_memories`
2. Fix indent; no WRITE gate → no `create_memory`, no skip reason

## Example 7 — Data flow orientation (S3, default create)

**User:** "记忆创建 API 的调用链是怎样的？"

**Bucket:** Must · **search_tier:** S3

**Actions:**

1. `search_memories(query_text="记忆创建 API 调用链", domain="coding", session_id="timem-platform-backend", search_tier="S3", limit=5)`
2. Trace code (router → service → core)
3. Answer with call chain
4. `project_discovery` gate → **default `create_memory`** (`memory_hint=convention`) unless highly similar memory exists
