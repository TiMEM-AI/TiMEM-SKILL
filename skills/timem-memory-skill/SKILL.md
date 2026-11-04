---
name: 记忆管理·太忆空间TiMEM SPACE
description: 处理个人记忆的检索与会话保存。首条消息询问是否持续逐条保存，同意后再确认项目或未归类。
version: "1.0.4"
display_name: 记忆管理·太忆空间TiMEM SPACE
display_name_en: TiMEM SPACE Memory Skill
description_zh: '请访问：https://space.timem.cloud/ 你的所有 AI 助手， 终于共用同一个大脑 说一次"记住"，换多少个 Agent 都记得你。 太忆空间让你的记忆随你走。'
description_en: 'Please visit: https://space.timem.cloud/. All your AI assistants finally share one single brain. Say "remember" once, and no matter how many Agents you switch to, they will remember you. TiMEM-Space lets your memories travel with you.'
---

# 太忆空间个人记忆

## 本会话的逐条保存开关

1. 收到新会话首条用户消息时，先问一次：「从现在开始，要把本次会话的每条交流都保存到太忆空间吗？」此时不问项目、不写入。若用户首条已明确要求开始保存，直接进入下一步。
2. 用户同意后，再问：「要归入哪个个人项目？没有项目可以说『未归类』。」用户说「没有项目」「没有」或「未归类」即选择未归类。用户已明确指定目标时跳过已回答的问题。沉默不代表未归类。
3. 确认目标并校验成功后进入持续保存。首次同意覆盖首条请求起的业务交流；若此前拒绝或停止，则只从后来明确要求开始保存的那条消息起算。每轮将本轮新增的用户消息和可见助手答复按顺序提交给个人 MCP，不挑选“重要”内容，不重发整段历史。纯授权问答、工具输出及密钥不作为会话内容提交。
4. 用户拒绝或尚未答复时，照常处理任务，写入调用为零，后续普通消息不再追问。用户后来明确说「从这条开始存」即可开启；缺少目标只追问归属。若明确限定「只存这一条」，仅保存指定内容，之后维持原开关状态。
5. 用户说「停止保存」立即关闭。切换项目时先核对新目标，再保存后续内容。新会话重新询问；同一会话内所有个人记忆 Skill 共用一个开关、目标和写入进度。恢复时从本会话明确指令和已有回执判断；不得从目录绑定、上一次会话或本文示例推断授权。工具调用失败时按原操作键恢复。

用户确认保存后，使用个人 MCP 核对服务、账号及目标。对指定项目按名称查询候选、核对 UUID 并解析上下文；同名时请用户选择。已有绑定只能作为候选，不能代替本次选择或自动改写目录绑定。
选定项目或明确选择「未归类」时，使用服务端支持的 personal-project-v1 上下文调用 `create_project_memory`，核对回执后再报告结果。项目工具不可用时停止，不能退回普通记忆或团队连接。
仅当用户明确选择未归类、个人服务只提供旧版通用记忆工具且当前不在项目绑定模式时，才可按实际工具定义使用 `create_memory`。

## 读取与归属

个人项目读写细节见[个人项目记忆流程](../timem-project-memory/SKILL.md)。明确绑定项目时只在该上下文检索；未绑定的普通读取沿用原个人检索流程。检索无需保存授权，亦不授权写入。

## Parameters

| Field | Rule |
|-------|------|
| `query_text` | required, 3–12 task-oriented words |
| `messages` | required for create, 2–4 recent `{role, content}` turns |
| `search_tier` | coding only: `S3` default; `S0` recall; `S6` before delete |
| `memory_hint` | coding only, optional: `decision` / `constraint` / `lesson` / `convention` / `preference` / `correction` |

`domain` is optional (defaults to `general`); it is used only as a memory tag and does not affect retrieval or storage.

Never paste full files or long logs into `messages`. Never use random UUIDs per turn.

**Memory vs rule:** facts / preferences / orientation → `create_memory`; reusable "in situation X, do Y" → `learn_rule` (rule-learning skill).

**Memory vs knowledge base:** memory stores cognition *about the user* distilled from conversations (preferences, decisions, lessons); the knowledge base stores *reference material the user provides* (papers, docs, specs, plans) via `write_knowledge` / `search_knowledge` (timem-knowledge skill). Rule of thumb: does the info stand on its own outside this conversation as external material? → knowledge base. Did it grow out of interactions as cognition about the user? → memory. When unsure which holds the answer, query both.

## Forget

User asks to forget → `search_memories` (coding: `search_tier="S6"`) to get `memory_id` → confirm if ambiguous → `delete_memory(memory_id="...")`.

## References

- [mcp-tools.md](references/mcp-tools.md)
- [workflow.md](references/workflow.md)
- [examples.md](references/examples.md)
- [search-tier.md](references/search-tier.md)
- [write-rubric.md](references/write-rubric.md)

## AGENTS.md snippet

For business repos: [assets/agents-snippet.md](assets/agents-snippet.md)

## Changelog

- 1.0.4 (2026-09-08): Add memory-vs-knowledge-base boundary note and pointer to timem-knowledge skill.
- 1.0.3 (2026-09-04): Remove three-domain teaching and all `session_id` notes; domain is an optional tag only. Name → 跨Agent记忆-太忆 TiMEM.
- 1.0.2 (2026-09-01): Adjust metadata frontmatter layout.
- 0.3.1 (2026-08-26): Remove all `session_id` requirements — server schema has no such field.
- 1.0.1 (2026-08-30): Add metadata block (author/version/display_name/descriptions); unify versioning; clean legacy merge references.
- 0.2.0 (2026-08-19): Introduce three-domain selection (coding / general / writing) within the single memory skill.
- 0.1.0 (2026-08-18): Initial version of the memory skill.
