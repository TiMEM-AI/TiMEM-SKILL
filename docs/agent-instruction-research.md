# Agent 全局指令文件调研

调研日期：2026-08-26
范围：Cursor、OpenClaw、Hermes、TRAE、腾讯 WorkBuddy、Qoder。
证据限制：仅使用官方文档、第一方仓库或本机安装的第一方产品源码/模板；未找到官方稳定文件路径时，不将第三方教程当作结论。

## 结论总览

| Agent | 已验证的全局机制 | 与项目级机制的边界 | 是否应自动注入 TiMEM 指令 | 推荐目标 |
| --- | --- | --- | --- | --- |
| Cursor | 有全局 **User Rules**；官方 Help 已明确本机 User Rule 文件目录为 `~/.cursor/rules`（Windows：`%USERPROFILE%\.cursor\rules`）。 | `.cursor/rules/*.mdc`、`.cursorrules` 与 `AGENTS.md` 是项目/目录上下文；`~/.cursor/rules` 是用户级本机规则目录。 | **可以**：创建安装器维护的 `timem-memory.mdc`，使用 Always Apply `.mdc` 格式。 | `~/.cursor/rules/timem-memory.mdc` |
| OpenClaw | `AGENTS.md` 在**每个 Agent 的 workspace** 中，且每次会话开始加载。 | `~/.openclaw` 是状态目录；workspace 才放 `AGENTS.md`。多 Agent 各有 workspace。 | **有条件地可以**：必须解析并只写入所选 Agent 的实际 workspace，不能硬编码状态目录根部。 | `<resolved-agent-workspace>/AGENTS.md` |
| Hermes | `SOUL.md` 是 Hermes 实例的全局人格/行为文件，位于 `$HERMES_HOME/SOUL.md`，默认 `~/.hermes/SOUL.md`，每会话加载。 | `AGENTS.md`、`.hermes.md`、`CLAUDE.md` 是项目工作目录上下文。 | **有条件地可以**：仅追加已有的 `SOUL.md`，不创建文件以保留默认 fallback。 | `${HERMES_HOME:-~/.hermes}/SOUL.md` |
| TRAE | 有全局 **User Rules**，官方将其定义为应用于所有项目，并公布 Markdown 文件目录 `~/.trae/user_rules`。 | Project Rules 和仓库内的 `AGENTS.md`/嵌套规则只作用于项目。 | **可以**：仅创建安装器自有的独立规则文件。 | `~/.trae/user_rules/timem-memory.md` |
| 腾讯 WorkBuddy | 本机 5.3.14 的真实会话 trace 将 `~/.workbuddy/SOUL.md` 标记为 “Injected workspace identity files”，并把完整内容注入上下文。 | 未验证到官方支持的 `AGENTS.md` / `CLAUDE.md` 机制；全局等价文件是 `SOUL.md`。 | **可以，但仅对已有文件追加**。 | `~/.workbuddy/SOUL.md` |
| Qoder | **Qoder CLI** 支持用户级静态记忆：`~/.qoder/AGENTS.md` 与 `~/.qoder/rules/**/*.md`，用于所有项目；配置根可由 `QODER_CONFIG_DIR` 改写。 | Qoder IDE 的 `.qoder/rules` 与项目根 `AGENTS.md` 是项目级。 | **可以，但仅限 Qoder CLI**，且必须先确认目标是 CLI 并解析 `QODER_CONFIG_DIR`。 | `${QODER_CONFIG_DIR:-~/.qoder}/AGENTS.md` |

以下“可以”均指：安装器采用追加式、幂等写入；先检查 TiMEM 标记；不覆盖用户内容；并在用户设置了环境变量或 Agent 专用 workspace 时遵从其解析结果。

## TiMEM 写入内容与通用安全规则

目标文本：

```text
每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程
```

建议继续沿用以下幂等判定：文件已包含 `TiMEM-SPACE`、`太忆空间` 或 `timem-memory` 任一标记时不写入；否则在文件末尾另起一行追加目标文本。

不要把“存在某个配置目录”当成“该目录中的任意 `AGENTS.md` 都会被 Agent 读取”。能自动写入的前提是厂商明确把该文件定义为用户级或目标 Agent 的会话上下文。

## 逐项证据与路径

### Cursor — 自动写入本机 User Rule 文件

Cursor 官方 Help 现明确列出本机 User Rule 文件目录：`~/.cursor/rules`，Windows 为 `%USERPROFILE%\.cursor\rules`；它们留在当前机器、不随账号同步。User Rules 本身对所有项目生效。[Cursor Rules Help](https://prod.cursor.com/help/customization/rules)

规则参考文档规定规则文件使用带 YAML front matter 的 `.mdc` 格式，`alwaysApply: true` 表示每次 Agent Chat 都包含该规则。[Cursor Rules Reference](https://prod.cursor.com/docs/rules) 安装器据此只创建自己拥有的文件：

```text
~/.cursor/rules/timem-memory.mdc
```

其内容为：

```md
---
description: "TiMEM memory workflow"
alwaysApply: true
---

每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程
```

文件已出现 `TiMEM-SPACE`、`太忆空间` 或 `timem-memory` 时，安装器不再改写；没有标记的已有文件只追加目标文本，避免覆盖用户内容。不要写入 `~/.cursor/AGENTS.md`，它不是用户级规则目标。Cursor Rules 只影响 Agent Chat，不影响 Tab、Inline Edit 或 Bugbot。[Cursor Rules Help](https://prod.cursor.com/help/customization/rules)

### OpenClaw — 仅写入解析后的 Agent workspace

OpenClaw 官方将 `AGENTS.md` 定义为 Agent 的 operating instructions，并说明它在每次会话开始时加载。它属于 workspace，而不是状态目录 `~/.openclaw`。[Agent workspace](https://docs.openclaw.ai/agent-workspace)

默认主 Agent 的路径是：

```text
~/.openclaw/workspace/AGENTS.md
```

但这只是默认值。官方路径优先级和多 Agent 行为如下：

1. `OPENCLAW_WORKSPACE_DIR` 可覆盖默认 workspace；
2. 非 `default` 的 `OPENCLAW_PROFILE` 会把默认改为 `~/.openclaw/workspace-<profile>`；
3. `~/.openclaw/openclaw.json` 中的 `agents.defaults.workspace` 可覆盖默认；
4. `agents.list[].workspace` 可为单个 Agent 再覆盖一次；
5. 没有显式 workspace 的非默认 Agent 使用 `<state-dir>/workspace-<agentId>`。

官方还说明多 Agent 各自拥有 `SOUL.md`、`AGENTS.md` 等 workspace 文件。因此不存在一个可替代所有 Agent workspace 的“全局 `~/.openclaw/AGENTS.md`”。[Agent workspace](https://docs.openclaw.ai/agent-workspace) [Multi-agent routing](https://docs.openclaw.ai/multi-agent)

**实现结论：** 可安全自动注入，但应先选择/枚举实际 Agent，再将内容追加到其解析后的 `<workspace>/AGENTS.md`。若安装器只针对 `main` Agent，必须在输出中明确“仅对 main 生效”；若要覆盖全部 Agent，必须逐个 workspace 处理并单独汇报。

### Hermes — 写入全局 `SOUL.md`

Hermes 的第一方文档把 `SOUL.md` 定义为该 Hermes 实例的全局人格、语气和行为定制文件：只从 `HERMES_HOME/SOUL.md` 加载，默认路径为 `~/.hermes/SOUL.md`，并在会话开始进入系统提示词。现有文件不会被种子流程覆盖。[Which File Does What?](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/which-file-does-what.md) [Context Files](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/context-files.md)

全局目标应为：

```text
${HERMES_HOME:-~/.hermes}/SOUL.md
```

不要把 TiMEM 全局指令写到 `~/.hermes/AGENTS.md`。Hermes 官方将 `AGENTS.md`、`.hermes.md`/`HERMES.md` 和 `CLAUDE.md` 定义为项目工作目录的上下文文件；其中 `.hermes.md` 优先级最高。它们随工作目录和子目录发现，不能承担跨项目全局指令职责。[Context Files](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/context-files.md)

**实现结论：** 可安全追加到解析后的既有 `SOUL.md`。为避免干扰用户的人格内容和 Hermes 缺少 `SOUL.md` 时的默认 fallback，安装器仅在文件存在且缺少 TiMEM 标记时追加；不创建文件，也不覆盖现有 front matter。

### TRAE — 写入已公开的 Global Rules 目录

TRAE 官方变更日志明确区分：User Rules 依据个人偏好、对所有项目生效；Project Rules 只对单个项目生效。官方也已记录 Agent 会识别仓库及子仓库目录中的 `AGENTS.md` 规则文件。[TRAE Changelog](https://www.trae.ai/changelog)

TRAE Rules 文档现公开 Global Rules 的 Windows 用户目录 `%USERPROFILE%\.trae\user_rules`，规则文件为 Markdown；项目规则仍位于 `<project>/.trae/rules/`。[TRAE Rules](https://docs.trae.ai/ide/rules)

**实现结论：** 安装器可以只维护自有的 `~/.trae/user_rules/timem-memory.md`，按 TiMEM 标记进行幂等追加或创建。不要写入项目级 `.trae/rules`、应用缓存或数据库；这些目标不能替代全局规则。

### 腾讯 WorkBuddy — 本机运行时已验证 `SOUL.md`

本机安装的 WorkBuddy 5.3.14 在 `~/.workbuddy/` 中创建 `SOUL.md`、`IDENTITY.md`、`USER.md` 与 `BOOTSTRAP.md`。`BOOTSTRAP.md` 将前三者称为 future runs 的 source of truth。

更关键的是，真实会话 trace 的系统上下文含有 “Injected workspace identity files” 段落，逐个列出并嵌入 `~/.workbuddy/SOUL.md`、`IDENTITY.md` 与 `USER.md` 的内容。因此这不是“看起来像模板”的推测，而是本机运行时对 `SOUL.md` 会话加载的第一方证据。

WorkBuddy 没有被验证为加载全局 `AGENTS.md` 或 `CLAUDE.md`；正确的等价全局目标是：

```text
~/.workbuddy/SOUL.md
```

**实现结论：** 可以对已存在的 `SOUL.md` 进行幂等追加；不创建缺失文件，不覆盖人格内容或 front matter。这样既使用已验证的会话入口，也不会改变首次启动/默认身份行为。

### Qoder — 仅 Qoder CLI 可安全写入

Qoder 需要严格区分 IDE 与 CLI：

- **Qoder IDE：** 官方文档称 `.qoder/rules` 位于当前项目目录，仅作用于该项目；项目根 `AGENTS.md` 也由 IDE 识别。这不是跨项目全局文件。[Qoder IDE Rules](https://docs.qoder.com/user-guide/rules)
- **Qoder CLI：** 官方 Memory 文档明确列出用户级静态记忆，`~/.qoder/AGENTS.md` 用于当前用户的跨项目通用偏好和工作习惯；`~/.qoder/rules/**/*.md` 是作用于每个项目的用户级规则。用户级 `AGENTS.md` 会在启动/刷新记忆时加载。[Qoder CLI Memory](https://docs.qoder.com/cli/memory)

Qoder CLI 的默认用户配置根为 `~/.qoder`，但 `QODER_CONFIG_DIR` 可以更改它。因此准确目标应是：

```text
${QODER_CONFIG_DIR:-~/.qoder}/AGENTS.md
```

Windows 默认展开为：

```text
C:\Users\<user>\.qoder\AGENTS.md
```

官方还支持用户级 `rules/**/*.md`，且没有 loading front matter 的规则默认始终生效；但单一 TiMEM 全局指令放在 `AGENTS.md` 更直接，也与 CLI 的“overall instructions”定义一致。[Qoder CLI Memory](https://docs.qoder.com/cli/memory) [Qoder CLI settings reference](https://docs.qoder.com/cli/settings-reference)

**实现结论：** 仅在检测到 Qoder CLI 且解析完 `QODER_CONFIG_DIR` 后，才可安全追加到 `AGENTS.md`。不要将这个结论扩展到仅安装了 Qoder IDE 的机器；IDE 的已验证规则文件仍是项目级。

## 推荐的后续实现顺序

1. 先扩展 **Hermes**：解析 `HERMES_HOME`，更新 `SOUL.md`。
2. 再扩展 **Qoder CLI**：解析 `QODER_CONFIG_DIR`，更新 `AGENTS.md`，并明确排除仅 IDE 安装的情况。
3. 最后扩展 **OpenClaw**：实现 workspace 解析和多 Agent 选择/枚举，避免错误写入 `~/.openclaw/AGENTS.md`。
4. 使用 **Cursor** 的本机 User Rule 目录创建安装器自有的 Always Apply 规则；使用 **TRAE** 已公开的 `~/.trae/user_rules` 创建独立全局规则；对 **WorkBuddy** 仅追加已验证的既有 `SOUL.md`。

本报告记录机制和安全边界；安装器与测试据此独立实现，且不会修改项目级指令文件或真实用户配置以外的目标。
