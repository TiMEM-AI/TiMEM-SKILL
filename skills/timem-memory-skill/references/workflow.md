# 综合记忆工作流

## 本会话的逐条保存开关

1. 收到新会话首条用户消息时，先问一次：「从现在开始，要把本次会话的每条交流都保存到太忆空间吗？」此时不问项目、不写入。若用户首条已明确要求开始保存，直接进入下一步。
2. 用户同意后，再问：「要归入哪个个人项目？没有项目可以说『未归类』。」用户说「没有项目」「没有」或「未归类」即选择未归类。用户已明确指定目标时跳过已回答的问题。沉默不代表未归类。
3. 确认目标并校验成功后进入持续保存。首次同意覆盖首条请求起的业务交流；若此前拒绝或停止，则只从后来明确要求开始保存的那条消息起算。每轮将本轮新增的用户消息和可见助手答复按顺序提交给个人 MCP，不挑选“重要”内容，不重发整段历史。纯授权问答、工具输出及密钥不作为会话内容提交。
4. 用户拒绝或尚未答复时，照常处理任务，写入调用为零，后续普通消息不再追问。用户后来明确说「从这条开始存」即可开启；缺少目标只追问归属。若明确限定「只存这一条」，仅保存指定内容，之后维持原开关状态。
5. 用户说「停止保存」立即关闭。切换项目时先核对新目标，再保存后续内容。新会话重新询问；同一会话内所有个人记忆 Skill 共用一个开关、目标和写入进度。恢复时从本会话明确指令和已有回执判断；不得从目录绑定、上一次会话或本文示例推断授权。工具调用失败时按原操作键恢复。

用户确认保存后，使用个人 MCP 核对服务、账号及目标。对指定项目按名称查询候选、核对 UUID 并解析上下文；同名时请用户选择。已有绑定只能作为候选，不能代替本次选择或自动改写目录绑定。
选定项目或明确选择「未归类」时，使用服务端支持的 personal-project-v1 上下文调用 `create_project_memory`，核对回执后再报告结果。项目工具不可用时停止，不能退回普通记忆或团队连接。
仅当用户明确选择未归类、个人服务只提供旧版通用记忆工具且当前不在项目绑定模式时，才可按实际工具定义使用 `create_memory`。

### 检索


**Default: search** when prior style/audience may help. When unsure → search.

1. **Trigger** — need prior style, tone, audience, or series conventions? OR drafting where those may apply without explicit recall wording? → **search**
2. **Query** — 3–12 words: style, audience, tone keywords (required).
3. **Call**:
   ```
   search_memories(
     query_text="<style or audience keywords>",
     limit=5,
   )
   ```
4. **Apply** — use verified constraints in the draft; abstain if hits are stale.

**Do not under-call** — "I can draft without tools" is not a skip reason when style/audience may matter.
