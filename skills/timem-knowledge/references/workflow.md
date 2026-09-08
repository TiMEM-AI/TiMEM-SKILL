# Knowledge Base Workflow

## 什么该进知识库

- 参考资料：PDF、报告、规范、手册
- 会议纪要、研究综述、笔记
- 可复用的内容片段（模板、样板）
- 用户希望日后可检索的领域文档

**不该进知识库**：

- 对话历史、个人偏好 → 记忆（`create_memory`）
- 代码级决策 → `domain=coding` 记忆
- 写作风格偏好 → `domain=writing` 记忆

## 知识库 vs 记忆 决策树

```text
用户提问
  → 答案可能藏在已上传的文档里吗？
    → 是 → search_knowledge(query_text=...)
    → 否 → 是个人偏好、过往决定、经验教训吗？
      → 是 → search_memories(query_text=..., domain=...)
      → 否 → 直接用模型知识回答（不调 TiMEM）
```

拿不准时**并行查两边**，合并结果。记忆给"用户背景"，知识库给"资料依据"。

## 检索流程

1. **触发** —— 用户问及已上传文档的内容，或明确要求查知识库。
2. **构造 query** —— 3–12 个词的任务导向查询（`query_text`，必填）。
3. **调用**：
   ```text
   search_knowledge(
     query_text="<用户的问题>",
     # 省略 kb_id → 默认知识库；目标库未知时先 list_knowledge_bases
   )
   ```
4. **核验** —— 结果是文档片段而非标准答案，注意 `score` 与 `filename`；召回为空要如实说明，不编造引用。
5. **回答** —— 注明信息来自哪个文件。

## 写入流程（文本）

1. **触发** —— 用户给出资料性文本并要求保存到知识库。
2. **保持原文结构**，不要摘要压缩（知识库价值在完整可检索）。
3. **调用**：
   ```text
   write_knowledge(
     content="<原文>",
     title="可选标题",
     tags=["可选标签"],
     # 省略 kb_id → 默认知识库
   )
   ```
4. **确认** —— 返回文件记录，`sync_status: pending` 表示云端向量化进行中（异步，正常）。
5. **话术** —— 告知"已进入向量化队列，稍后支持语义搜索"，不要立即轮询。

## 文件上传流程（二进制，MCP 暂不支持）

1. 确认/创建 KB 拿 `kb_id`（`list_knowledge_bases` / `create_knowledge_base`）。
2. 引导用户走控制台 / 前端 / REST：
   ```bash
   curl -X POST "https://api.space.timem.cloud/api/v1/knowledge/files/upload" \
     -H "X-API-Key: <agent-api-key>" \
     -F "kb_id=<kb_id>" -F "file=@doc.pdf"
   ```
3. 若文件可由 Agent 读取并提取文本（md/txt/代码），可提取后经 `write_knowledge` 入库，并说明这是文本化入库。

## 建库流程

- 用户想新建分类库时：`create_knowledge_base(name=..., description=..., is_default=false)`。
- `is_default=true` 会取消该用户其他库的默认标记，后续省略 `kb_id` 的操作落在它上面。
- 建库只是建容器，内容仍需 `write_knowledge` 或文件上传写入。

## kb_id 决策

- 大多数情况下省略 `kb_id` —— 服务端自动落到用户默认 KB。
- 用户点名某个非默认库时，从 `list_knowledge_bases()` 结果中取 `id` 传入。

## 错误处理

| 情况 | 原因 | 动作 |
|-------|------|------|
| 写入/搜索报知识库不存在 | 用户无 KB 或 kb_id 错误 | 先 `list_knowledge_bases` 核对，必要时 `create_knowledge_base` |
| 搜索召回为空 | 无匹配文档 / 云端降级 | 如实说明；可建议补充资料；也可并行查 `search_memories` 兜底用户背景 |
| 写入后立刻搜不到 | 云端向量化异步 | 告知稍后生效，不要轮询 |
| 工具调用失败（网络/鉴权） | MCP 连接或 key 问题 | 先 `ready` 排查；不反复重试，降级为无知识库模式回答 |

## 限制

- `write_knowledge` 只接受**文本**；二进制文件走 REST/控制台。
- `top_k` 上限 10。
- 云端检索失败时后端会静默降级本地关键词匹配，召回质量会下降——结果异常时可提醒用户稍后重试。
