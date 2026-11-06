---
name: timem-coding-memory
description: 代码场景的个人记忆检索和保存。首条消息询问是否持续逐条保存，同意后再确认项目或未归类。
---

# 太忆代码记忆

## 本会话的逐条保存开关

1. 收到新会话首条用户消息时，先问一次：「从现在开始，要把本次会话的每条交流都保存到太忆空间吗？」此时不问项目、不写入。若用户首条已明确要求开始保存，直接进入下一步。
2. 用户同意后，再问：「要归入哪个个人项目？没有项目可以说『未归类』。」用户说「没有项目」「没有」或「未归类」即选择未归类。用户已明确指定目标时跳过已回答的问题。沉默不代表未归类。
3. 确认目标并校验成功后进入持续保存。首次同意覆盖首条请求起的业务交流；若此前拒绝或停止，则只从后来明确要求开始保存的那条消息起算。每轮将本轮新增的用户消息和可见助手答复按顺序提交给个人 MCP，不挑选“重要”内容，不重发整段历史。纯授权问答、工具输出及密钥不作为会话内容提交。
4. 用户拒绝或尚未答复时，照常处理任务，写入调用为零，后续普通消息不再追问。用户后来明确说「从这条开始存」即可开启；缺少目标只追问归属。若明确限定「只存这一条」，仅保存指定内容，之后维持原开关状态。
5. 用户说「停止保存」立即关闭。切换项目时先核对新目标，再保存后续内容。新会话重新询问；同一会话内所有个人记忆 Skill 共用一个开关、目标和写入进度。恢复时从本会话明确指令和已有回执判断；不得从目录绑定、上一次会话或本文示例推断授权。工具调用失败时按原操作键恢复。

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

| 会话中的事件 | 应有行为 |
| --- | --- |
| 新会话第一条业务消息 | 只问是否从现在起逐条保存；不写入 |
| 回答「是」 | 只问目标；不写入 |
| 随后回答「没有项目」 | 核对未归类；从首条业务消息开始保存 |
| 已启用后继续交流 | 沿用目标，每轮只提交新增交流，不再询问 |
| 首次回答「否」，接着讨论其他事情 | 持续不写入，不再询问 |
| 之后说「从这条开始存到 A」 | 核对 A，从这一条起保存；以前的交流不补写 |
| 已关闭时说「只把这条存到 A」 | 仅保存指定的一条，下一轮仍关闭 |
| 新会话或仅检测到项目绑定 | 重新询问是否开启；不继承之前的同意 |

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
