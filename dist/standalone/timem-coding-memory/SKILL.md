---
name: timem-coding-memory
description: 代码场景的个人记忆检索和保存。每次写入前确认本次会话与目标项目。
---

# 太忆代码记忆

## 本次会话的保存确认

每次处理完用户的新请求，询问是否保存本次会话内容和目标项目：「这次会话要保存到太忆空间吗？如果保存，请指定个人项目，也可以选『未归类』。」
用户已明确说「把这段保存到 X」时，这句话同时给出了本次授权和目标，无需重复询问。
只说「保存」就只追问目标；只提到项目名称、读取记忆、绑定目录或讨论 Skill 行为，都不构成写入授权。
同一轮中多个 Skill 只由一个入口询问一次。用户已拒绝本次保存时不要再问。
用户拒绝、没有答复或项目尚不明确时，继续原任务，写入调用为零；不要排队补写。
只提交用户这次同意的内容。授权在本次保存后用尽，后续新增内容或新会话重新询问；不要把确认消息本身作为新待存内容。

用户确认保存后，使用个人 MCP 核对服务、账号及目标。对指定项目按名称查询候选、核对 UUID 并解析上下文；同名时请用户选择。已有绑定只能作为候选，不能代替本次选择或自动改写目录绑定。
选定项目或明确选择「未归类」时，使用服务端支持的 personal-project-v1 上下文调用 `create_project_memory`，核对回执后再报告结果。项目工具不可用时停止，不能退回普通记忆或团队连接。
仅当用户明确选择未归类、个人服务只提供旧版通用记忆工具且当前不在项目绑定模式时，才可按实际工具定义使用 `create_memory`。

项目读写按 timem-project-memory 的上下文校验流程执行。当前个人范围内沿用只读检索；没有已确定的项目读取范围时，不混用个人与团队连接。

代码检索默认 S3，明确召回用 S0，删除前定位用 S6。

## Parameters

| Field | Value |
|---|---|
| `domain` | `coding` |
| `query_text` | 3–12 task-oriented words (required for search) |
| `search_tier` | `S3` by default; see table above |
| `messages` | 2–4 recent `{role, content}` turns; never paste full files or long logs |
| `memory_hint` | Optional — `decision` / `constraint` / `lesson` / `convention` / `preference` / `correction` |

**AGENTS.md / CLAUDE.md** — team-reviewed, long-stable conventions. **TiMEM** — agent-retrievable project knowledge: decisions, lessons, preferences, code-verified module/architecture orientation.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

## Scene boundary

| Turn looks like | Use |
|-----------------|-----|
| Prefs / office durable facts / topic context | `timem-general-memory` (`domain=general`) |
| Copy, tone, audience, draft style | `timem-writing-memory` (`domain=writing`) |
| Repo, debug, architecture, module questions | this skill (`domain=coding`) |

Ambiguous: `classify_memory_scene(messages=[...])`.

## Forget

User asks to forget → `search_memories(search_tier="S6")` to get `memory_id` → confirm if ambiguous → `delete_memory(memory_id="...")`.


# 会话保存示例

| 用户的回复 | 下一步 | 写入次数 |
| --- | --- | --- |
| “不存”或未回复 | 继续当前任务 | 0 |
| “帮我记一下” | 追问存到哪个项目，等待回复 | 0 |
| “查询项目 A 的记忆” | 只读项目 A | 0 |
| “把这段存到项目 A” | 在个人连接解析唯一的 A，核对范围后提交本次内容 | 1 |
| “存到项目 A”，但有两个同名项目 | 展示候选并等待选择 | 0 |
| “存到未归类” | 核对个人未归类作用域，按该范围保存 | 1 |
| 上次同意过，或目录里已绑定 A | 重新询问本次意愿和目标 | 0 |

<!-- Generated from skills/shared/mcp-tools.md; do not edit by hand. Run: python scripts/sync-shared-mcp-tools.py -->

# MCP tools (coding scene)

Use **`domain=coding`** on search and create. Use stable **`session_id`** = repo name.

Coding-specific: optional `memory_hint` on `create_memory` (`decision`, `constraint`, `lesson`, `convention`, `preference`, `correction`).

Atomic MCP memory tools only. Full parameter reference follows.

---

# TiMEM MCP atomic tools (shared reference)

Skills orchestrate **when** to call these tools. Requires [timem-mcp](https://pypi.org/project/timem-mcp/) connected in your MCP client.

Use atomic MCP memory tools only: `search_memories`, `create_memory`, `delete_memory` (and `classify_memory_scene` when domain is unclear).

Always pass **`domain`** explicitly (`general` | `coding` | `writing`). Do not rely on `TIMEM_AUTO_SCENE` in skill workflows.

---

## `search_memories`

Semantic search over stored memories.

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query_text` | **Yes** | 3–12 task-oriented words; empty query causes API error |
| `domain` | Recommended | `general` / `coding` / `writing` → filters expert space |
| `session_id` | **No** | Server schema has no such field. Do not pass — scope is resolved from API key. |
| `search_tier` | Coding: recommended | `S3` by default; `S0` for explicit recall, `S6` before delete; enables empty-search `elevate_create` |
| `limit` | No | Default 10; use 5 for task-start, 10 for explicit recall |

Example:

```
search_memories(
  query_text="auth JWT decision",
  domain="coding",
  search_tier="S3",
  limit=5,
)
```

### Empty coding search (`domain=coding`, `count=0`)

Response may include (does **not** auto-create):

| Field | Meaning |
|-------|---------|
| `memory_gap` | No hits for this query in coding space |
| `guidance` | Short next-step hint from MCP |
| `elevate_create` | Soft signal to consider create after verify (needs `search_tier`) |
| `suggested_next` | Often includes `create_memory` |

Work from codebase; apply the coding skill write rubric before `create_memory`.

---

## `create_memory`

Create memories from conversation turns (async on backend; waits by default).

| Parameter | Required | Notes |
|-----------|----------|-------|
| `messages` | **Yes** | 2–4 decision-relevant turns; `{role, content}` |
| `session_id` | **No** | Server schema has no such field. Do not pass — scope is resolved from API key. |
| `domain` | Recommended | `general` / `coding` / `writing` |
| `memory_hint` | No | Coding only: `decision` \| `constraint` \| `lesson` \| `convention` \| `preference` \| `correction`. Agent typing hint; MCP may not persist it to Engine today. |

Example:

```
create_memory(
  domain="general",
  messages=[
    {"role": "user", "content": "Remember I prefer concise answers."},
    {"role": "assistant", "content": "Stored: prefer concise answers."},
  ],
)
```

---

## `delete_memory`

Soft-delete one memory by ID. Requires user intent.

1. `search_memories` to find `memory_id` (coding: tier S6).
2. Confirm with user if ambiguous.
3. `delete_memory(memory_id="...")`

---

## `ready`

Health check after install or when other tools fail with auth/network errors.

---

## `classify_memory_scene` (optional)

When unsure which `domain` to use, classify recent messages:

```
classify_memory_scene(messages=[...])
```

Returns `scene`, `expert_id`, `confidence`. If confidence is low, default to `general` or ask the user.

---

## Scene → domain mapping

| domain | expert_id (backend) |
|--------|---------------------|
| `general` | `default` |
| `coding` | `coder` |
| `writing` | `writer` |
