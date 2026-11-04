---
name: 记忆管理·太忆空间TiMEM SPACE
description: 处理个人记忆的检索与会话保存。每次写入前确认用户意愿和项目归属。
version: "1.0.4"
display_name: 记忆管理·太忆空间TiMEM SPACE
display_name_en: TiMEM SPACE Memory Skill
description_zh: '请访问：https://space.timem.cloud/ 你的所有 AI 助手， 终于共用同一个大脑 说一次"记住"，换多少个 Agent 都记得你。 太忆空间让你的记忆随你走。'
description_en: 'Please visit: https://space.timem.cloud/. All your AI assistants finally share one single brain. Say "remember" once, and no matter how many Agents you switch to, they will remember you. TiMEM-Space lets your memories travel with you.'
---

# 太忆空间个人记忆

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

## 读取与归属

个人项目读写细节见[个人项目记忆流程](references/project-memory.md)。明确绑定项目时只在该上下文检索；未绑定的普通读取沿用原个人检索流程。检索无需保存授权，亦不授权写入。

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
