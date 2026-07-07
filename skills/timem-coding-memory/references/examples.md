# Coding memory examples

## Example 1 — S3 task start (search then work)

**User:** "继续 timem-mcp 的 MCP 挂载配置"

**Tier:** S3

**Actions:**

1. `search_memories(query_text="MCP 挂载 配置", domain="coding", session_id="timem-mcp", limit=5)`
2. Verify hits vs repo code and AGENTS.md
3. Read/edit codebase
4. WRITE EVAL → create if durable decision or verified orientation emerges

## Example 2 — S-skip (no search)

**User:** "把这行缩进改成 4 空格"

**Tier:** S-skip

**Actions:**

1. Do **not** call `search_memories`
2. Fix indent; WRITE EVAL → skip create (noise floor: one-off patch)

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

## Example 6 — Project module overview (S3, default create)

**User:** "给我说一下记忆相关的模块"

**Tier:** S3 (project technical question — **not** S-skip)

**Actions:**

1. `search_memories(query_text="记忆模块 架构 L1 L5", domain="coding", session_id="timem-platform-backend", limit=5)`
2. Verify hits vs code; if count=0 or incomplete, read `app/memory_management` and `core/timem_core`
3. Answer combining verified memories + codebase
4. WRITE EVAL → **default `create_memory`** (`memory_hint=convention`): module names, paths, roles (≤10 bullets OK)
5. If search already has highly similar complete entry → skip duplicate only

## Example 7 — Noise floor (skip)

**User:** "把这行缩进改一下"

**Tier:** S-skip

**Actions:**

1. Fix indent; WRITE EVAL → skip (noise floor: one-off patch)

**User:** "我猜记忆都存在 redis 里" (agent has not read code)

**Actions:**

1. WRITE EVAL → skip create until verified from codebase (noise floor: unverified guess)

## Example 8 — Data flow orientation (S3, default create)

**User:** "记忆创建 API 的调用链是怎样的？"

**Tier:** S3

**Actions:**

1. `search_memories(query_text="记忆创建 API 调用链", domain="coding", session_id="timem-platform-backend", limit=5)`
2. Trace code (router → service → core)
3. Answer with call chain
4. WRITE EVAL → **default `create_memory`** (`memory_hint=convention`) unless highly similar memory exists
