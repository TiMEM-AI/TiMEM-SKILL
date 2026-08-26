# Cursor、TRAE、腾讯 WorkBuddy：默认全局指令文件复核（后续）

调研日期：2026-08-26
范围：只判断厂商是否明确加载全局 AGENT.md / AGENTS.md 或等价文件，以及是否适合自动注入 TiMEM 指令。
证据：官方文档与本机安装的第一方产品源码；未修改安装器、安装目录或用户配置。

本报告补正 [前一轮调研](agent-instruction-research.md) 中 Cursor、TRAE 的过时结论。

## 直接结论

| 产品 | 是否存在默认且全局加载的 AGENT.md / AGENTS.md | 已验证的全局等价机制 | TiMEM 自动注入结论 |
| --- | --- | --- | --- |
| Cursor | **否。** 官方将 AGENTS.md 定义为项目根或项目子目录规则。 | User Rules 是全局机制；官方帮助页还列出本机 User Rule 文件目录 <code>~/.cursor/rules</code>（Windows 为 <code>%USERPROFILE%/.cursor/rules</code>）。 | **可以安全自动注入。** 不创建 <code>~/.cursor/AGENTS.md</code>；只维护独立的 Always Apply User Rule。 |
| TRAE | **否。** AGENTS.md、CLAUDE.md 等是项目级兼容规则。 | 官方定义全局 User Rules 目录为 <code>%USERPROFILE%/.trae/user_rules</code>；本机一方源码确认递归读取其中的 <code>.md</code> 文件，且支持 <code>alwaysApply: true</code>。 | **可以安全自动注入。** 新建独立规则文件，不改项目 AGENTS.md。 |
| 腾讯 WorkBuddy | **否。** 本机一方源码中的 AGENTS.md 仅从当前项目工作目录读取。 | **SOUL.md 是等价的全局身份/行为文件。** 当前安装包会创建、读取并注入其内容到提示词；普通与专家模板都使用 Soul。 | **当前已验证版本可以。** 追加到已解析的 SOUL.md，保留原有 front matter 和标题；升级后应复核版本。 |

## Cursor

Cursor 没有默认、全局加载的 AGENT.md 或 AGENTS.md。官方规则参考将 AGENTS.md 明确定位为项目根或子目录中的规则；User Rules 才是跨项目全局偏好。[Cursor Rules Reference](https://prod.cursor.com/docs/rules)

官方帮助页现在明确列出本机 User Rule 文件目录 <code>~/.cursor/rules</code>，这说明此前“没有任何本地路径”的判断已过时。[Cursor Rules Help](https://prod.cursor.com/help/customization/rules)

Cursor Rules Reference 已公开 `.mdc` YAML front matter 与 <code>alwaysApply: true</code> 格式；配合已公开的本机 User Rules 目录，安装器可维护其自有规则文件：

    ~/.cursor/rules/timem-memory.mdc

新文件使用 Always Apply front matter，已有同名文件仅在缺少 TiMEM 标记时追加目标文本。因此：

- 不写入 <code>~/.cursor/AGENTS.md</code>；
- 只创建或维护安装器拥有的 <code>timem-memory.mdc</code>；
- 用隔离回归测试覆盖重复安装与规则文件内容，避免改动用户已有的其他规则。

## TRAE

TRAE 没有默认的全局 AGENT.md / AGENTS.md。官方 Rules 文档将 AGENTS.md、CLAUDE.md、CLAUDE.local.md 定义为项目根目录的兼容规则；它们不是用户全局文件。[TRAE Rules](https://docs.trae.ai/ide/rules)

TRAE 的官方全局等价机制是 User Rules：文档明确给出 Windows 目录 <code>%USERPROFILE%/.trae/user_rules</code>，并说明全局规则会在所有项目生效。[TRAE Rules](https://docs.trae.ai/ide/rules)

本机 TRAE 3.5.91 的第一方运行时代码进一步验证了该契约：

- 维护旧的 <code>user_rules.md</code> 兼容入口与新的 <code>user_rules</code> 目录；
- 扫描目录及其子目录中的 <code>.md</code> 文件；
- 解析 YAML front matter 中的 <code>alwaysApply</code>；
- <code>alwaysApply: true</code> 会被判定为 Always Apply。

因此可安全使用一个独立文件，例如：

    %USERPROFILE%/.trae/user_rules/timem-memory.md

    ---
    alwaysApply: true
    ---

    每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程

这是全局规则文件，不是项目文件；写入时应继续采用 TiMEM 标记检测和幂等追加策略。

本机源码佐证： [TRAE workbench runtime](/E:/Trae/resources/app/out/vs/workbench/workbench.desktop.main.js)，SHA-256：<code>038FA065D2CFADC0A117566511851181BBF66F51191DB4A01C5A376F82E12B1C</code>。

## 腾讯 WorkBuddy

WorkBuddy 同样没有默认的全局 AGENT.md / AGENTS.md。当前安装包中对 AGENTS.md 的读取位于 ProjectContextSection，路径基于当前项目工作目录；不能把 <code>~/.workbuddy/AGENTS.md</code> 当作全局注入入口。

但 WorkBuddy 的等价文件 SOUL.md 有明确的本机第一方加载证据。腾讯 WorkBuddy 5.3.14 的打包源码中：

- IdentityCollector 先解析 <code>WORKBUDDY_CONFIG_DIR</code>，其次 <code>CODEBUDDY_CONFIG_DIR</code>，最后回退到 <code>~/.workbuddy</code>；
- 首次运行会确保 SOUL.md、IDENTITY.md、USER.md 存在；
- Collector 读取 SOUL.md 并写入 <code>SoulContent</code> 提示词变量；
- PromptRenderer 在普通和专家模板中都会调用 IdentityCollector。专家模板不读取 Identity 与 Bootstrap，但仍读取 Soul 与 User。

这证明当前版本的 SOUL.md 不是仅存在于安装目录的模板，而是每个相关会话提示词的全局输入。官方更新日志也佐证 WorkBuddy 会精细管理身份文件的系统提示词注入：4.8.1 专门记录了专家场景不再注入 IDENTITY.md。[WorkBuddy Changelog](https://www.codebuddy.cn/docs/workbuddy/Changelog) 官方 Memory 文档也确认产品会把记忆作为系统提示词上下文注入。[WorkBuddy Memory](https://www.codebuddy.cn/docs/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/Memory)

因此，对当前已验证版本可以安全地将 TiMEM 指令追加到已解析的 SOUL.md：

    <resolved WORKBUDDY_CONFIG_DIR or CODEBUDDY_CONFIG_DIR or ~/.workbuddy>/SOUL.md

约束如下：

- 不写入 <code>~/.workbuddy/AGENTS.md</code>；
- 保留 SOUL.md 的现有 front matter、一级标题及用户人格内容；
- 仅在缺少 TiMEM 标记时新增独立小节；
- 因 SOUL.md 的公开、版本化文件契约尚未在官方文档中单独发布，安装器若要默认启用，应保留产品检测与版本回归测试。

本机源码佐证： [WorkBuddy app.asar](/E:/Workbuddy/resources/app.asar)，产品版本 5.3.14，SHA-256：<code>466C8A91A5FF2665D94F0506E66015BFA31A40996DC6780BAC5D1F00BBC1D640</code>。关键嵌入源码模块为 <code>packages/workbuddy-server/src/mode/collectors/identity-collector.ts</code> 与 <code>packages/workbuddy-server/src/mode/prompt-renderer.ts</code>。

## 结论供后续实现使用

1. Cursor：没有全局 AGENT(S).md；使用已公开的 User Rules 目录维护独立的 Always Apply `.mdc` 文件。
2. TRAE：没有全局 AGENT(S).md；应使用官方的 <code>.trae/user_rules</code> 全局规则目录，支持独立 Always Apply Markdown 文件。
3. WorkBuddy：没有全局 AGENT(S).md；当前一方源码确认全局 SOUL.md 被加载并注入提示词，可作为等价目标，但应尊重配置目录覆盖并做版本回归验证。
