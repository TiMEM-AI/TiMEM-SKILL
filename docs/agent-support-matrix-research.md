# TiMEM-SPACE / TiMEM-SKILL Agent 支持矩阵调研

调研日期：2026-08-26
范围：只使用 TiMEM-AI 上游源码、厂商第一方文档，以及已安装产品的第一方运行时证据；不把“兼容 MCP / Agent Skills”自动等同于 TiMEM 官方支持。

## 口径与版本证据

TiMEM-AI 没有单独维护一份更广的公开客户端名录。因此本报告以其最新 `main` 一键安装器作为“官方已支持客户端”的可审计口径。2026-08-26 的远端 `main` 为 [`c9e4b0c`](https://github.com/TiMEM-AI/TiMEM-SKILL/commit/c9e4b0cd4544005b52a872ac9d43a9f66fb0885b)，提交时间为 2026-08-20 12:26 UTC；该版本的 [PowerShell 矩阵](https://github.com/TiMEM-AI/TiMEM-SKILL/blob/c9e4b0cd4544005b52a872ac9d43a9f66fb0885b/install-all.ps1#L30-L41) 列出 7 个 Skill+MCP 客户端，并单列 Claude Desktop 为 MCP-only。

TiMEM-SKILL README 仅承诺 Agent Skills 可移植到 Cursor、Claude Code、Codex 和其他兼容客户端；这不是额外客户端的安装/配置支持承诺。[README](https://github.com/TiMEM-AI/TiMEM-SKILL/blob/c9e4b0cd4544005b52a872ac9d43a9f66fb0885b/README.md#L1-L5)

## 结论总览

| 客户端 | TiMEM 上游 `main` | 当前本地安装器 | 厂商全局 / Agent-workspace 指令入口 | 自动化结论 |
| --- | --- | --- | --- | --- |
| Claude Code | 支持 Skill+MCP | 已覆盖 | `~/.claude/CLAUDE.md`；用户级 MCP 位于 `~/.claude.json` | 已正确覆盖 |
| Codex | 支持 Skill+MCP | 已覆盖 | `$CODEX_HOME/AGENTS.md`，默认 `~/.codex/AGENTS.md` | 已正确覆盖 |
| Cursor | 支持 Skill+MCP | 已覆盖 | `~/.cursor/rules/` 下的本机 User Rule | 已覆盖；维持独立 `.mdc` |
| OpenClaw | 支持 Skill+MCP | 已覆盖 | 每个解析后的 Agent workspace 的 `AGENTS.md` | 已正确覆盖；不能写状态目录根 |
| Hermes | 支持 Skill+MCP | 已覆盖 | `$HERMES_HOME/SOUL.md` | 已正确覆盖；保留仅追加既有文件策略 |
| TRAE | 支持 Skill+MCP | 已覆盖 | `%USERPROFILE%/.trae/user_rules/timem-memory.md` | 已创建独立全局规则；不触碰项目规则 |
| WorkBuddy | 支持 Skill+MCP | 已覆盖 | 已安装版本的 `SOUL.md` | 版本化运行时证据支持；保留谨慎策略 |
| Claude Desktop | MCP-only | MCP 已覆盖 | 账户级 Settings → Instructions for Claude；无公开本地规则文件契约 | 不注入本地指令 |
| Qoder CLI | **未列入 TiMEM 上游矩阵** | 本地额外支持 | `${QODER_CONFIG_DIR:-~/.qoder}/AGENTS.md` | 平台入口可靠，但 TiMEM 官方支持状态待上游确认 |

当前工作树的客户端矩阵位于 [install-all.ps1](../install-all.ps1#L57-L64)；它比上游多出 `qoder` 这一项本地扩展。TRAE 的 MCP 会优先解析当前 AppData 位置，指令则由安装器自有的全局规则文件维护。

## 逐项依据与安全自动化判断

### 已正确覆盖的上游客户端

- **Claude Code**：官方把 `~/.claude/CLAUDE.md` 定义为所有项目生效的用户指令，适合幂等追加。[Claude Code Memory](https://code.claude.com/docs/en/memory)
- **Codex**：OpenAI 官方规定全局优先从 `$CODEX_HOME/AGENTS.override.md` 或 `AGENTS.md` 读取，默认目录是 `~/.codex`；本地安装器目标正确。[OpenAI Docs: AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- **Cursor**：官方公开本机 User Rules 目录 `~/.cursor/rules`（Windows 为 `%USERPROFILE%/.cursor/rules`），规则参考定义 `.mdc` front matter 和 `alwaysApply: true`。现有独立 `timem-memory.mdc` 是恰当的自有文件目标。[Rules Help](https://prod.cursor.com/help/customization/rules) [Rules Reference](https://prod.cursor.com/docs/rules)
- **OpenClaw**：`AGENTS.md` 是每次会话加载的 Agent operating instructions，但必须放在实际 workspace；多 Agent 可有不同 workspace。现有 workspace 解析策略正确。[Agent workspace](https://docs.openclaw.ai/agent-workspace)
- **Hermes**：`SOUL.md` 仅从 `$HERMES_HOME/SOUL.md` 加载，并在会话开始注入系统提示词。现有“只追加已存在文件”比无条件创建更保守，继续保留。[Hermes: SOUL.md](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/which-file-does-what.md)

### 已补齐：TRAE

TRAE 官方 Rules 文档已明确：Global Rules 对所有项目生效，Windows 目录为 `%USERPROFILE%/.trae/user_rules`，规则是 Markdown 文件；项目规则则位于 `<project>/.trae/rules/`。[TRAE Rules](https://docs.trae.ai/ide/rules)

安装器现仅创建且维护一个独立文件：`%USERPROFILE%/.trae/user_rules/timem-memory.md`，新文件带 `alwaysApply: true`。全局规则本身已覆盖所有项目，不需要依赖项目级 `AGENTS.md`，也不编辑内部数据库；该路径已由 Windows 与 Bash 隔离回归测试覆盖。

本机 TRAE 3.5.91 的第一方运行时进一步验证了 `user_rules`、旧 `user_rules.md` 兼容入口及 `alwaysApply` 解析（运行时 SHA-256：`038FA065…E12B1C`）。这是对官方文档的实现佐证，而非替代公开契约。

### 需要维持边界的客户端

- **WorkBuddy**：上游 TiMEM 列名支持。已安装 WorkBuddy 5.3.14 的实际会话 trace 已记录 `Injected workspace identity files`，且 `~/.workbuddy/SOUL.md` 存在并被注入；产品 5.3.14 发布于 2026-08-17。[WorkBuddy Changelog](https://www.codebuddy.cn/docs/workbuddy/Changelog) 但厂商尚未公开版本化的 `SOUL.md` 文件/API 契约，故当前“检测产品 + 仅追加既有 SOUL.md”策略合适；不要扩展为 `~/.workbuddy/AGENTS.md`。
- **Claude Desktop**：TiMEM 上游明确为 `hasSkills=false` 的 MCP-only 目标。Claude 有账户级 UI 的 “Instructions for Claude”，会应用于所有会话，但未发布可安全写入的本地文件/API；而且该 App 目标没有 TiMEM Skill 安装路径，不应自动插入“查看 skill”的指令。[Claude personalization](https://support.claude.com/en/articles/10185728-understanding-claude-s-personalization-features) [Claude Desktop MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)

### 本地额外项：Qoder CLI

当前工作树额外含有 `qoder`，但 TiMEM-AI 最新上游矩阵尚未列出它，因而不能在文档中称为 TiMEM 官方已支持客户端。Qoder CLI 官方明确将 `~/.qoder/AGENTS.md` 定义为用户级跨项目 memory/instructions，且 `QODER_CONFIG_DIR` 可改写用户配置根。[Qoder Run Tasks](https://docs.qoder.com/cli/run-tasks) [Qoder Settings](https://docs.qoder.com/cli/settings) 将覆盖目录与 `AGENTS.md` 组合为 `${QODER_CONFIG_DIR}/AGENTS.md` 是合理实现推断，仍应由 CLI 隔离测试验证。

结论：保留为本地扩展可以，但需要 TiMEM-AI 在上游 installer/README 中列名后，才应升级为“官方支持”。不要将 Qoder IDE 的项目级 `.qoder/rules` 与 Qoder CLI 的用户级 `AGENTS.md` 混为一谈。

## 未纳入的客户端

未在 TiMEM-AI 当前公开安装器中找到 CodeBuddy Code、Cline、Windsurf、GitHub Copilot、Gemini CLI 等客户端。它们可能支持 MCP 或 Agent Skills，但没有 TiMEM-AI 的一键安装矩阵、Skill 路径和 MCP 配置作为第一方证据；在上游列名之前，不应自动扩展本安装器。

## 已实施的后续动作

1. **Claude Code MCP**：已改为官方用户级配置 `~/.claude.json`，并在 Windows PowerShell 5.1 使用大小写敏感 JSON 解析，避免丢失路径大小写不同的已有键。
2. **TRAE**：已新增独立 `%USERPROFILE%/.trae/user_rules/timem-memory.md` 的幂等写入与隔离测试；Windows MCP 优先使用 `%APPDATA%\Trae\User\mcp.json`，兼容 TRAE Solo 变体及旧版 `~/.trae/mcp.json`。
3. **WorkBuddy**：保留现状；如要增强，应先把 `WORKBUDDY_CONFIG_DIR` / `CODEBUDDY_CONFIG_DIR` 覆盖行为做成版本回归测试。
4. **Qoder CLI**：保留为本地扩展，等待 TiMEM-AI 上游正式列名后再升级为“官方支持”。
