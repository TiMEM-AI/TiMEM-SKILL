# TiMEM Skills

面向 [TiMEM](https://timem.cloud) 记忆工作流的 Agent Skills。Skill 负责**编排**何时、如何调用 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) 的原子工具——记忆（`search_memories`、`create_memory`、`delete_memory`）与规则（`recall_rules`、`learn_rule`、`record_rule_outcome`）。

**语言：** [English](README.md) | 简体中文

遵循 [Agent Skills](https://agentskills.io/specification) 开放标准，可在 Cursor、Claude Code、Codex 等兼容客户端使用。
## 快速安装（ZIP 包）

下载最新 release ZIP——无需 git clone：

| | |
|---|---|
| **下载** | [timem-skill-latest.zip](https://timem-skill-1300898765.cos.ap-guangzhou.myqcloud.com/releases/timem-skill-latest.zip) |
| **历史版本** | [releases/](https://timem-skill-1300898765.cos.ap-guangzhou.myqcloud.com/releases/) |

```bash
# 1. 下载
curl -fsSL 'https://timem-skill-1300898765.cos.ap-guangzhou.myqcloud.com/releases/timem-skill-latest.zip' -o timem-skill.zip

# 2. 解压
unzip timem-skill.zip

# 3. 安装（自动检测 Claude Code、Codex、Cursor、Hermes 等）
cd timem-skill && bash install-all.sh --api-key 你的_TIMEM_API_KEY
```

> **Windows (PowerShell)：** 在线一键安装运行 `$env:TIMEM_API_KEY='你的_TIMEM_API_KEY'; $env:TIMEM_AGENT='codex'; irm https://raw.githubusercontent.com/TiMEM-AI/TiMEM-SKILL/main/install-all.ps1 | iex`。使用 ZIP 包时运行 `.\install-all.ps1 -ApiKey 你的_TIMEM_API_KEY -Agent codex`；`-Agent` 支持逗号分隔多个 agent，也可用环境变量 `TIMEM_AGENT`。

安装器只会在已核验的用户级或 Agent workspace 指令目标中维护 TiMEM 工作流：

| 客户端 | 指令目标 | 写入策略 |
|---|---|---|
| Codex | `$CODEX_HOME/AGENTS.md`（默认 `~/.codex/AGENTS.md`） | 不存在则创建，否则追加 |
| Claude Code | `~/.claude/CLAUDE.md` | 不存在则创建，否则追加 |
| Cursor | `~/.cursor/rules/timem-memory.mdc` | 创建本机 Always Apply User Rule |
| TRAE | `~/.trae/user_rules/timem-memory.md` | 创建带 `alwaysApply` 的独立全局规则 |
| Qoder CLI | `${QODER_CONFIG_DIR:-~/.qoder}/AGENTS.md` | 本地 CLI 扩展；不存在则创建，否则追加 |
| OpenClaw | 每个解析出的 Agent workspace 内的 `AGENTS.md` | 遵从 workspace 覆盖与多 Agent 配置 |
| Hermes | `${HERMES_HOME:-~/.hermes}/SOUL.md` | 仅在文件已存在时追加 |
| WorkBuddy | `~/.workbuddy/SOUL.md` | 仅在文件已存在时追加 |

若文件中不存在 `TiMEM-SPACE`、`太忆空间` 或 `timem-memory` 标记，会只在末尾追加一次，不覆盖已有内容。Cursor 已公开本机 User Rule 目录，安装器会创建带 `alwaysApply: true` 的 `.mdc` 规则；它只影响 Agent Chat。TRAE 已公开 Global Rules 目录，安装器会创建带 `alwaysApply: true` 的独立 Markdown 规则，且绝不修改项目规则。Claude Code 的用户级 MCP 会写入 `~/.claude.json`。Windows 上，TRAE MCP 配置依次优先使用 `%APPDATA%\Trae\User\mcp.json`、TRAE Solo 变体和旧版 `~/.trae/mcp.json`。使用 Bash 的 `--skip-agent-instructions` 或 PowerShell 的 `-SkipAgentInstructions` 可跳过此操作。详细依据见[支持矩阵调研](docs/agent-support-matrix-research.md)。

**自行构建 ZIP：** `bash scripts/build-release.sh` → `bash scripts/upload-cos.sh`


## 推荐（写代码）

已配置 TiMEM MCP 时，安装 **一个** coding 包即可：

| 包 | 路径 | 适用 |
|----|------|------|
| **完整版**（渐进披露） | [`dist/full/timem-coding-memory/`](dist/full/timem-coding-memory/) | 默认，多文件 |
| **单文件版** | [`dist/standalone/timem-coding-memory/`](dist/standalone/timem-coding-memory/) | 最省事，目录内仅一个 `SKILL.md` |

将文件夹拷到客户端的 skills 目录（目录名保持 `timem-coding-memory`）：

| 客户端 | 项目级 | 用户级（全局） |
|--------|--------|----------------|
| Agents / Codex 系 | `.agents/skills/` | `~/.agents/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |

```bash
git clone https://github.com/TiMEM-AI/timem-skill.git
cd 你的项目

mkdir -p .agents/skills   # 或 .claude/skills / .cursor/skills
cp -r /path/to/timem-skill/dist/full/timem-coding-memory .agents/skills/
# 或单文件版：
# cp -r /path/to/timem-skill/dist/standalone/timem-coding-memory .agents/skills/
```

脚本安装：

```bash
python /path/to/timem-skill/scripts/install.py --skill coding --target agents
```

**安装时不再需要单独拷贝 `shared`。**

## 全部 Skills

| Skill | 场景 | 安装来源 |
|-------|------|----------|
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | **优先 `dist/standalone/`**（或 `dist/full/`） |
| [timem-general-memory](skills/timem-general-memory/) | `general` | **优先 `dist/standalone/`**（或 `dist/full/`） |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | `skills/timem-writing-memory/`（自包含） |
| [timem-rule-learning](skills/timem-rule-learning/) | 规则（跨场景） | `skills/timem-rule-learning/`（自包含） |
| [timem-knowledge](skills/timem-knowledge/) | 知识库 | `skills/timem-knowledge/` |

开发源码在 `skills/`；面向用户的 coding / general 发行包由 `python scripts/build-all.py` 生成到 `dist/`。

## 前置条件

1. 在 MCP 客户端配置 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp)（`TiMEM_API_KEY`）。
2. 安装所需 Skill 包（见上与 [docs/installation.md](docs/installation.md)）。

## 架构

Skill = 编排；MCP = 原子 API。详见 [docs/architecture.md](docs/architecture.md)。

## 许可证

MIT — 见 [LICENSE](LICENSE)。
