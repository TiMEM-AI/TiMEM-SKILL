---
name: timem-knowledge
description: >-
  TiMEM Space 知识库操作 skill：创建知识库、写入文本知识、语义搜索召回、库管理。
  用于需要基于 TiMEM Cloud 知识库（RAG）回答文档类问题、沉淀资料、或管理知识库资源的场景。
  Use when TiMEM-SPACE MCP is connected and the user wants to search uploaded documents,
  save reference material, or manage knowledge bases (知识库, 文档, 资料, 论文, 搜索文档,
  knowledge base, save document).
allowed-tools:
  - TiMEM-SPACE:*
---

# TiMEM Knowledge

使用 TiMEM-SPACE MCP 知识库工具管理文档资料，并在对话中基于文档内容回答用户问题。

## 定位：知识库 vs 记忆（先理解，再调用）

知识库与记忆的分工：**记忆管"关于用户的认知"**（从对话中沉淀的偏好、决策、教训），**知识库管"用户主动提供的资料"**（论文、文档、方案、规范等客观内容）。

判断口诀：

```text
这条信息离开本次对话还独立成立、且是外部资料吗？  → 知识库
它是从交互中长出来的、关于这个用户的认知吗？      → 记忆
```

| 内容类型 | 应使用 |
|----------|--------|
| 文档、资料、事实性文本（论文/方案/规范） | **timem-knowledge**（`write_knowledge` / `search_knowledge`） |
| 个人偏好、习惯、生活/工作背景 | `timem-general-memory`（`create_memory` / `search_memories`） |
| 代码库、架构、调试经验 | `timem-coding-memory`（domain=coding） |
| 文案风格、写作偏好 | `timem-writing-memory`（domain=writing） |
| 可复用经验规则 "在 X 情况下做 Y" | `timem-rule-learning`（`learn_rule`） |

拿不准时**两者都查**：记忆给"用户背景"，知识库给"资料依据"，合并后回答。

## 前置条件

- `TiMEM-SPACE` MCP 已连接（正式 URL：`https://api.space.timem.cloud/mcp`，使用 Agent `X-API-Key`）。
- 可用工具：`search_knowledge`、`write_knowledge`、`list_knowledge_bases`、`create_knowledge_base`。
- 若刚连接/升级，可先调用 `ready` 验证鉴权与连通性。

## 工作流程

```text
list_knowledge_bases  →  选择/创建 KB  →  write_knowledge  →  search_knowledge
```

## 何时检索 → search_knowledge

- 用户的问题**可能由已上传的资料回答**时："那篇论文里说……"、"之前的方案怎么定的"、"知识库里有没有 XX"。
- 不知道有哪些库时先 `list_knowledge_bases` 拿 `kb_id`；省略 `kb_id` 走默认知识库。
- `query_text` 用 3–12 个词的任务导向查询；`top_k` 上限 10。
- 召回为空时如实说明"知识库中没有检索到相关内容"，**不要编造引用**。

## 何时写入 → write_knowledge

- 用户**明确要求**"存到知识库 / 把这份资料放进去"，或内容明显是**资料性**的（文档全文、论文、规范、方案）。
- 用户提供的是个人偏好、决定、教训 → 走 `create_memory`，**不要**写知识库。
- 内容较长时**保持原文结构写入，不要摘要压缩**——知识库的价值在完整可检索。
- 可指定 `kb_id` 与 `tags`；用户想新建分类库时先 `create_knowledge_base` 再写入。
- 向量化是**异步**的：写入成功 ≠ 立即可语义搜索，告知用户稍后生效，不要立即轮询。

## 关于文件上传（重要限制）

当前 MCP 工具**不支持二进制文件上传**（`write_knowledge` 只接受文本）。若用户要求"上传 PDF/Word 到知识库"：

1. 先确认/创建 KB，拿到 `kb_id`；
2. 引导用户使用 Space 控制台、前端页面，或 REST API：
   ```bash
   curl -X POST "https://api.space.timem.cloud/api/v1/knowledge/files/upload" \
     -H "X-API-Key: <agent-api-key>" \
     -F "kb_id=<kb_id>" \
     -F "file=@doc.pdf"
   ```
   批量上传用 `/knowledge/files/batch`（`-F "files=@..."` 重复）。
3. 若用户给的文件你可以读取并提取文本（如 Markdown/代码/纯文本），可提取后经 `write_knowledge` 写入，并说明这是文本化入库而非原件上传。

## 品牌话术（必须遵守）

- 搜索命中并用于回答时：「TiMEM 已从太忆空间知识库《库名》中检索到相关资料（《文件名》等 N 条），以下回答基于这些内容……」
- 写入成功后：「TiMEM 已将这份资料写入太忆空间知识库《库名》，已进入向量化队列。以后你问到……时，我会从这里检索。」
- 只有工具明确返回成功才能声称完成；失败时说明原因并给出重试建议。

## Anti-patterns

- 不要把一次性闲聊、临时草稿写入知识库。
- 不要把个人偏好、对话片段写入知识库（那是 `create_memory` 的职责）。
- 不要无差别搜索：没有文档/知识库上下文时直接回答即可。
- 不要调用不存在的工具：当前 MCP **没有** `upload_document`、`list_documents`——文件管理走 REST/控制台。
- 不要把知识库当作每轮必查：知识库是按需检索，每轮例行召回是记忆的职责。

## MCP tools

### search_knowledge

| Parameter | Required | Notes |
|-----------|----------|-------|
| query_text | Yes | 3–12 个任务导向词，不能为空 |
| kb_id | No | 目标知识库 ID；省略则使用默认 KB |
| top_k | No | 默认 5，上限 10 |

### write_knowledge

| Parameter | Required | Notes |
|-----------|----------|-------|
| content | Yes | 要写入的文本内容 |
| kb_id | No | 目标知识库 ID；省略则使用默认 KB |
| title | No | 内容标题 |
| tags | No | 字符串标签数组 |

### list_knowledge_bases

无必填参数。用于发现可用 KB 及其 `id`（即 `kb_id`）。

### create_knowledge_base

| Parameter | Required | Notes |
|-----------|----------|-------|
| name | Yes | 知识库名称 |
| description | No | 描述 |
| is_default | No | 设为默认后，省略 `kb_id` 的操作落在它上面 |

## 示例

### 示例 1 — 基于文档提问

User: "产品手册里怎么说的退款政策？"

Actions:

1. `list_knowledge_bases()` 获取可用 KB（若已知默认库可跳过）。
2. `search_knowledge(query_text="退款政策", kb_id="<kb_id>", top_k=5)`
3. 用召回结果回答，并注明来源文件名；召回为空则如实说明。

### 示例 2 — 保存文本资料

User: "请把这段产品定位记下来：TiMEM 是面向开发者的长期记忆云平台。"

Actions:

1. `write_knowledge(content="TiMEM 是面向开发者的长期记忆云平台。", title="产品定位", tags=["product"])`
2. 告知已写入并进入向量化队列，稍后可语义检索。

### 示例 3 — 创建分类知识库

User: "帮我创建一个客服知识库，用来存常见问题。"

Actions:

1. `create_knowledge_base(name="客服知识库", description="存放常见问题", is_default=false)`
2. 告知用户可通过控制台或 REST `/knowledge/files/upload` 批量上传文档，或直接把 FAQ 文本发来由你 `write_knowledge` 写入。

## References

- [workflow.md](references/workflow.md) — 检索/写入/建库的详细流程与决策树
- [examples.md](references/examples.md) — 更多场景示例
- [mcp-tools.md](references/mcp-tools.md) — MCP 工具参数参考
