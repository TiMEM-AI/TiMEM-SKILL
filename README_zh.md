# TiMEM Skills

面向 [TiMEM](https://timem.cloud) 记忆工作流的 Agent Skills。Skill 负责**编排**何时、如何调用 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) 的原子工具——记忆（`search_memories`、`create_memory`、`delete_memory`）与规则（`recall_rules`、`learn_rule`、`record_rule_outcome`）。

**语言：** [English](README.md) | 简体中文

遵循 [Agent Skills](https://agentskills.io/specification) 开放标准，可在 Cursor、Claude Code、Codex 等兼容客户端使用。

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
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | 优先用 **`dist/full/` 或 `dist/standalone/`** |
| [timem-general-memory](skills/timem-general-memory/) | `general` | 优先用 **`dist/full/` 或 `dist/standalone/`** |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | `skills/timem-writing-memory/`（自包含） |
| [timem-rule-learning](skills/timem-rule-learning/) | 规则（跨场景） | `skills/timem-rule-learning/`（自包含） |
| [timem-knowledge](skills/timem-knowledge/) | 知识库 | `skills/timem-knowledge/` |

开发源码在 `skills/`；面向用户的 coding / general 发行包由 `python scripts/build-all.py` 生成到 `dist/`。

## 前置条件

1. 在 MCP 客户端配置 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp)（`TiMEM_API_KEY`、`TiMEM_USER_ID`）。
2. 安装所需 Skill 包（见上与 [docs/installation.md](docs/installation.md)）。

## 架构

Skill = 编排；MCP = 原子 API。详见 [docs/architecture.md](docs/architecture.md)。

## 许可证

MIT — 见 [LICENSE](LICENSE)。
