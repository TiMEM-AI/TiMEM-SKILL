# Knowledge Base Examples

## 示例 1 — 语义搜索（search_knowledge）

**User:** "我们之前上传的 API 设计文档里，认证方案是怎么定的？"

**Actions:**

1. `search_knowledge(query_text="API 认证方案")`（已知目标库时带 `kb_id`）
2. 用召回到的文档片段回答，注明来源 `filename`。
3. 召回为空 → 如实说明"知识库中未检索到相关内容"；可建议确认文档是否已上传，或并行查 `search_memories(query_text="API 认证方案", domain="coding")` 看是否是历史上讨论过的决策。

## 示例 2 — 保存文本资料（write_knowledge）

**User:** "把这段竞品分析存到知识库：Mem0 的优势是生态成熟……"

**Actions:**

1. `write_knowledge(content="<原文，保持结构>", title="竞品分析-Mem0", tags=["竞品", "memory"])`
2. 确认："已写入知识库并进入向量化队列，稍后支持语义搜索。"

**反例：** 用户说"记住我下周出差"——这是个人事务，走 `create_memory`，不要 `write_knowledge`。

## 示例 3 — 上传文件（MCP 不支持，引导 REST/控制台）

**User:** "把这个 PRD.pdf 上传到知识库"

**Actions:**

1. `list_knowledge_bases()` 确认目标库 `kb_id`（不存在则 `create_knowledge_base`）。
2. 说明 MCP 暂不支持二进制上传，给出路径：
   - Space 控制台 / 前端页面直接上传；或
   - REST：`POST /api/v1/knowledge/files/upload`（`-F kb_id=... -F file=@PRD.pdf`）。
3. 若你能读取该文件并提取文本，可提议："我也可以先提取文本写入知识库（内容为纯文本形式），要吗？"

## 示例 4 — 列出知识库（list_knowledge_bases）

**User:** "我有哪些知识库？"

**Actions:**

1. `list_knowledge_bases()`
2. 逐个列出名称、描述、是否默认库。
3. 顺带提示：写入/搜索省略 `kb_id` 时会落在默认库上。

## 示例 5 — 创建知识库并写入（组合流程）

**User:** "建一个'论文库'，把这篇摘要放进去：……"

**Actions:**

1. `create_knowledge_base(name="论文库", description="科研论文与摘要")`
2. `write_knowledge(kb_id="<上一步返回的 id>", content="<摘要原文>", title="...", tags=["paper"])`
3. 确认两步结果，提醒向量化异步生效。
