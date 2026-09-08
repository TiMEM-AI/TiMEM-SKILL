# MCP tools (knowledge base)

知识库是与记忆独立的系统，工具**没有** `domain` / `session_id` 参数，身份从 Agent `X-API-Key` 解析。

服务端：TiMEM-SPACE MCP（`https://api.space.timem.cloud/mcp`）。

---

## `search_knowledge`

在知识库中做语义搜索（云端 BM25 + 向量混合检索；云端异常时后端降级为本地关键词匹配）。

| Parameter | Required | Notes |
|-----------|----------|-------|
| `query_text` | **Yes** | 3–12 个任务导向词，不能为空 |
| `kb_id` | No | 省略则使用默认知识库 |
| `top_k` | No | 默认 5，上限 10 |

Example:

```text
search_knowledge(query_text="认证方案设计", top_k=5)
```

返回 `results[]`：`chunk_id` / `file_id` / `filename` / `text` / `score` / `metadata`。回答时按 `score` 排序引用并注明 `filename` 来源。

---

## `write_knowledge`

将一段文本写入知识库并触发云端向量化（异步）。

| Parameter | Required | Notes |
|-----------|----------|-------|
| `content` | **Yes** | 要写入的文本内容 |
| `kb_id` | No | 省略则使用默认知识库 |
| `title` | No | 内容标题（缺省自动生成文件名） |
| `tags` | No | 字符串标签数组 |

Example:

```text
write_knowledge(content="……", title="产品定位", tags=["product"])
```

返回文件记录（`id`、`chunk_count`、`sync_status: pending`）。`pending` 表示向量化进行中，属正常状态，不要轮询。

---

## `list_knowledge_bases`

列出当前用户可访问的知识库（只读），无必填参数。

返回 `list[]`：`id`（即后续调用的 `kb_id`）、`name`、`description`、`is_default`、`status`。

---

## `create_knowledge_base`

创建知识库（逻辑容器，本身不含内容；内容用 `write_knowledge` 写入）。

| Parameter | Required | Notes |
|-----------|----------|-------|
| `name` | **Yes** | 知识库名称（1–200 字符） |
| `description` | No | 描述（≤2000 字符） |
| `is_default` | No | 默认 false；设为 true 后成为省略 `kb_id` 时的落点 |

---

## 当前不存在的工具（勿调用）

- `upload_document` / `list_documents`：MCP 暂无二进制上传与文件列表工具。文件上传走 REST（`POST /api/v1/knowledge/files/upload`、`/files/batch`）或 Space 控制台。

---

知识库操作不要混用 `search_memories` / `create_memory` —— 那是记忆系统的工具，边界见 SKILL.md 的定位表。
