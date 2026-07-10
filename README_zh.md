# TiMEM Skills

面向 [TiMEM](https://timem.cloud) 记忆工作流的 Agent Skills。Skill 负责**编排**何时、如何调用 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp) 的原子工具（`search_memories`、`create_memory`、`delete_memory`）。

**语言：** [English](README.md) | 简体中文

## Skills 列表

| Skill | 场景 | 适用 |
|-------|------|------|
| [timem-general-memory](skills/timem-general-memory/) | `general` | 个人偏好、日常事实 |
| [timem-writing-memory](skills/timem-writing-memory/) | `writing` | 文案、风格、语气、内容创作 |
| [timem-coding-memory](skills/timem-coding-memory/) | `coding` | 软件开发、调试、架构决策 |

每个场景是**独立 Skill**（一场景一 Skill）。Cursor 通过各 Skill 的 `description` 自动路由，无需额外路由 Skill。

## 前置条件

1. 在 MCP 客户端配置 [timem-mcp](https://github.com/TiMEM-AI/timem-mcp)（`TiMEM_API_KEY`、`TiMEM_USER_ID`）。
2. 将需要的 Skill 复制到项目的 `.cursor/skills/`（见 [docs/installation.md](docs/installation.md)）。

## 快速安装

```bash
git clone <timem-skill 路径>
cd 你的项目
mkdir -p .cursor/skills
cp -r /path/to/timem-skill/skills/timem-coding-memory .cursor/skills/
cp -r /path/to/timem-skill/skills/shared .cursor/skills/timem-shared
```

全能力可安装三个 Skill。详见 [docs/installation.md](docs/installation.md)。

## 架构

Skill = 编排（搜/写规则）；MCP = 原子 API（`search_memories`、`create_memory`、`delete_memory`）。

详见 [docs/architecture.md](docs/architecture.md)。

## 许可证

MIT — 见 [LICENSE](LICENSE)。
