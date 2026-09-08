# 交接：一键安装脚本接入 timem-knowledge 技能（feat/shb/0908）

> 日期：2026-09-08 · 从 mac 端交接至 Windows（WSL）端继续
> 分支：`feat/shb/0908`（基于 dev）

## 任务目标

TiMEM-SKILL 仓库新增了知识库技能 `skills/timem-knowledge/`（含 `references/` 三个子文档，已在本分支重写完成，commit `d474b7f`）。
一键安装脚本（Mac/Linux 的 `install-all.sh`、Windows 的 `install-all.ps1` → `install-all.core.ps1`）需要把这个新技能纳入"skill 注入生成"步骤，使用户一键安装后能正常获得该技能。

## 已完成（本提交）

1. **`install-all.sh`**
   - `ALL_SKILLS` 数组新增 `"timem-knowledge:skills/timem-knowledge"`，注释从"3 个 TiMEM skills (TiMEM-SPACE MCP 仅支持记忆工具)"更新为"4 个 …（记忆 + 知识库工具）"。
   - 交互式选择的描述 `case` 新增 `timem-knowledge) desc="$(t "知识库" "Knowledge base")" ;;`。
   - `TIMEM_AGENT_INSTRUCTION`（注入到各 Agent 的 CLAUDE.md/AGENTS.md 等）从仅提记忆，更新为同时引导记忆与知识库：
     > 每次对话都要查看 timem-memory 与 timem-knowledge 的 skill，并调用 TiMEM-SPACE 中合适的接口：记忆传输走 search_memories/create_memory；资料性内容（文档/论文/方案）的存取走知识库 search_knowledge/write_knowledge
2. **`install-all.core.ps1`** — 对称的两处改动：`$ALL_SKILLS` 新增 `@{name="timem-knowledge"; path="skills/timem-knowledge"}`；`$TIMEM_AGENT_INSTRUCTION` 同上更新。
3. **测试同步** — `tests/install-all.sh.Tests.sh`（1 处）与 `tests/install-all.Integration.Tests.ps1`（9 处）中硬编码的旧指令文案已替换为新文案。

## 已验证（mac 端）

- `bash -n install-all.sh` 语法通过。
- `bash tests/install-all.sh.Tests.sh` 全部通过（ALL PASS）。
- `--dry-run` 确认 skill 安装循环现在遍历 4 个技能（原来 3 个），注入逻辑走通。
- 端到端真实安装**未验证**：安装器的 skill 来源是 `TIMEM_SKILL_REPO/archive/refs/heads/main.tar.gz`（GitHub main 分支），本分支合并进 main 之前 tarball 里没有 `skills/timem-knowledge/`；且 mac 沙箱拦了 GitHub 下载。

## 待办（Win/WSL 端）

1. **PowerShell 测试**：mac 无 `pwsh`，`install-all.core.ps1` 的改动只做了人工核对，未跑测试。
   - `pwsh` 下执行 `tests/install-all.Tests.ps1` 和 `tests/install-all.Integration.Tests.ps1`（Pester），确认指令文案替换后断言全过。
2. **Windows 端到端安装验证**：在本机（或干净 VM/临时用户）跑 `install-all.ps1`，确认：
   - `$ALL_SKILLS` 4 项全部复制成功（注意：同样受 tarball 只含 main 内容的限制——可先合并 main 后验证，或临时把下载地址指向本分支 tarball 验证）。
   - 各 Agent 注入的指令文件（CLAUDE.md / AGENTS.md / timem-memory.mdc 等）内容为新的记忆+知识库文案；已存在旧指令时去重逻辑（`$TIMEM_INSTRUCTION_MARKERS` 匹配 `TiMEM-SPACE|太忆空间|timem-memory`）仍能识别旧文案、不会重复追加。
3. **WSL 侧回归**：WSL 里跑 `install-all.sh` + `tests/install-all.sh.Tests.sh`，确认与 mac 行为一致。
4. **合并与发布**：两端验证通过后，`feat/shb/0908` → dev → main；合并后 tarball 才包含 `skills/timem-knowledge/`，真实一键安装才会带上知识库技能。

## 注意事项

- **不要推 main**：按约定只动特性分支，推送前与 shb 确认。
- **作用范围**：本次只加了 timem-knowledge。仓库里还有 `skills/timem-rule-learning/`（规则挖掘技能，README 已列出）但**未**纳入 `ALL_SKILLS`——是否需要一起进一键安装，待确认后再动。
- **下游依赖**：TiMEM-Space 仓库的 MCP 工具描述增强在其自己的 `feat/shb/0908` 分支（commit `f7eb0c0`），与本仓库独立，互不影响安装流程。
- 安装器 skill 拷贝逻辑是通用循环（`install_skills_for_agent` / `foreach ($skill in $ALL_SKILLS)`），新增条目不需要改循环本身；`SKILLS_FILTER` 按名字过滤也自动生效。
