#!/bin/bash
#
# TiMEM Skill - 一键安装到所有已检测的 AI Agent 工具
#
# 功能:
#   - 自动检测已安装的 Agent 工具 (Claude Code, Codex, Cursor, OpenClaw, Hermes,
#     Trae, WorkBuddy, Qoder, Claude Desktop)
#   - 为每个 agent 安装 TiMEM Skills (5 个) + 合并 TiMEM MCP 配置 + 注入全局指令
#   - 幂等: 重复安装安全，已有配置不覆盖，同名 skill 先 .bak 备份
#   - 部分 agent 失败不影响其他，最后汇总
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/TiMEM-AI/TiMEM-SKILL/main/install-all.sh | bash
#   bash install-all.sh [OPTIONS]
#
# 参数:
#   --api-key KEY       TiMEM API Key (默认读 $TIMEM_API_KEY 环境变量)
#   --skills LIST       只安装指定 skill (逗号分隔，默认全部 5 个)
#   --skip-mcp          跳过 MCP 配置，只装 skills
#   --skip-skills       跳过 skills，只配 MCP
#   --skip-agent-instructions  跳过已支持 Agent 的指令注入
#   --force             强制覆盖已有配置 (不用 .bak)
#   --quiet             静默模式，只输出错误和最终摘要
#   --dry-run           只检测和打印，不实际安装
#   --agent NAME        只安装指定 agent (逗号分隔)
#   --help              显示帮助
#
# MCP 配置方式:
#   默认 (Cloud HTTP):  "url": "https://api.timem.cloud/mcp" + headers (零安装)

set -uo pipefail

# ============================================================================
# 常量
# ============================================================================

TIMEM_SKILL_REPO="https://github.com/TiMEM-AI/TiMEM-SKILL"
TIMEM_MCP_REPO="https://github.com/TiMEM-AI/timem-mcp"
TIMEM_CLOUD_URL="https://api.space.timem.cloud/mcp/"
TIMEM_SERVER_NAME="TiMEM-SPACE"
TIMEM_API_HOST_DEFAULT="https://api.space.timem.cloud"
TIMEM_AGENT_INSTRUCTION="每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程"
TIMEM_INSTRUCTION_MARKER_REGEX='TiMEM-SPACE|太忆空间|timem-memory'
CODEX_CONFIG_PATH="${CODEX_HOME:-}"
if [ -z "$CODEX_CONFIG_PATH" ]; then
  CODEX_CONFIG_PATH="$HOME/.codex"
fi
QODER_CONFIG_PATH="${QODER_CONFIG_DIR:-}"
if [ -z "$QODER_CONFIG_PATH" ]; then
  QODER_CONFIG_PATH="$HOME/.qoder"
fi
HERMES_CONFIG_PATH="${HERMES_HOME:-}"
if [ -z "$HERMES_CONFIG_PATH" ]; then
  HERMES_CONFIG_PATH="$HOME/.hermes"
fi

resolve_trae_mcp_config() {
  local candidate platform
  local -a candidates=()

  if [ -n "${TRAE_MCP_CONFIG:-}" ]; then
    printf '%s\n' "$TRAE_MCP_CONFIG"
    return 0
  fi

  if [ -n "${APPDATA:-}" ]; then
    candidates+=(
      "$APPDATA/Trae/User/mcp.json"
      "$APPDATA/TRAE SOLO CN/User/mcp.json"
      "$APPDATA/TRAE SOLO/User/mcp.json"
    )
  fi

  platform="$(uname -s 2>/dev/null || true)"
  case "$platform" in
    Darwin*) candidates+=(
      "$HOME/Library/Application Support/Trae/User/mcp.json"
      "$HOME/Library/Application Support/TRAE SOLO CN/User/mcp.json"
    ) ;;
    MINGW*|MSYS*|CYGWIN*) candidates+=(
      "$HOME/AppData/Roaming/Trae/User/mcp.json"
      "$HOME/AppData/Roaming/TRAE SOLO CN/User/mcp.json"
    ) ;;
    *) candidates+=(
      "$HOME/.config/Trae/User/mcp.json"
      "$HOME/.config/TRAE SOLO CN/User/mcp.json"
    ) ;;
  esac
  candidates+=("$HOME/.trae/mcp.json")

  for candidate in "${candidates[@]}"; do
    if [ -e "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf '%s\n' "${candidates[0]}"
}

TRAE_MCP_CONFIG_PATH="$(resolve_trae_mcp_config)"
TRAE_CONFIG_PATH="$(dirname "$TRAE_MCP_CONFIG_PATH")"

# 3 个 TiMEM skills (TiMEM-SPACE MCP 仅支持记忆工具): name:repo_relative_path
ALL_SKILLS=(
  "timem-coding-memory:dist/standalone/timem-coding-memory"
  "timem-general-memory:dist/standalone/timem-general-memory"
  "timem-writing-memory:skills/timem-writing-memory"
)

# Agent 矩阵: name|detect_cmd|config_dir|skills_dir|mcp_config|format|root_key|has_skills|instruction_file|instruction_scope|instruction_create_if_missing|additional_detect_dir
AGENTS=(
  "claude-code|claude|$HOME/.claude|$HOME/.claude/skills|$HOME/.claude.json|json|mcpServers|yes|CLAUDE.md"
  "codex|codex|$CODEX_CONFIG_PATH|$CODEX_CONFIG_PATH/skills|$CODEX_CONFIG_PATH/config.toml|toml|mcp_servers|yes|AGENTS.md"
  "cursor|cursor|$HOME/.cursor|$HOME/.cursor/skills|$HOME/.cursor/mcp.json|json|mcpServers|yes|timem-memory.mdc|cursor-user-rules"
  "openclaw|openclaw|$HOME/.openclaw|$HOME/.openclaw/skills|$HOME/.openclaw/openclaw.json|json|mcp.servers|yes|AGENTS.md|openclaw-workspaces"
  "hermes|hermes|$HERMES_CONFIG_PATH|$HERMES_CONFIG_PATH/skills|$HERMES_CONFIG_PATH/config.yaml|yaml|mcp_servers|yes|SOUL.md||no"
  "trae|trae|$TRAE_CONFIG_PATH|$HOME/.trae/skills|$TRAE_MCP_CONFIG_PATH|json|mcpServers|yes|timem-memory.md|trae-user-rules||$HOME/.trae"
  "workbuddy|workbuddy|$HOME/.workbuddy|$HOME/.workbuddy/skills|$HOME/.workbuddy/.mcp.json|json|mcpServers|yes|SOUL.md||no"
  "qoder|qoder|$QODER_CONFIG_PATH|$QODER_CONFIG_PATH/skills|$QODER_CONFIG_PATH/settings.json|json|mcpServers|yes|AGENTS.md"
)

# Claude Desktop configs per platform (no skills, MCP only)
CLAUDE_DESKTOP_CONFIGS=(
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  "$HOME/AppData/Roaming/Claude/claude_desktop_config.json"
  "$HOME/.config/Claude/claude_desktop_config.json"
)

# ============================================================================
# 参数解析
# ============================================================================

API_KEY="${TIMEM_API_KEY:-}"
SKILLS_FILTER=""
SKIP_MCP=false
SKIP_SKILLS=false
SKIP_AGENT_INSTRUCTIONS=false
FORCE=false
QUIET=false
DRY_RUN=false
AGENT_FILTER=""
SILENT_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)     API_KEY="$2"; shift 2 ;;
    --skills)      SKILLS_FILTER="$2"; shift 2 ;;
    --skip-mcp)    SKIP_MCP=true; shift ;;
    --skip-skills) SKIP_SKILLS=true; shift ;;
    --skip-agent-instructions) SKIP_AGENT_INSTRUCTIONS=true; shift ;;
    --force)       FORCE=true; shift ;;
    --quiet)       QUIET=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --agent)       AGENT_FILTER="$2"; shift 2 ;;
    --help|-h)     sed -n '2,30p' "$0" 2>/dev/null; exit 0 ;;
    *)             echo "未知参数: $1 (用 --help 查看帮助)" >&2; exit 1 ;;
  esac
done

# ============================================================================
# 交互模式检测
# ============================================================================

# 判断是否在交互式终端中运行
IS_TTY=false
if [ -t 0 ] && [ -t 1 ]; then
  IS_TTY=true
fi

# 判断是否需要交互式引导:
#   - --quiet 或 --dry-run → 非交互
#   - --api-key 给了 → 非交互
#   - --agent 给了 → 跳过 agent 选择交互
#   - --skills 给了 → 跳过 skill 选择交互
#   - 非 TTY → 非交互 (提示下载后执行)
INTERACTIVE=false
if [ "$QUIET" = false ] && [ "$DRY_RUN" = false ] && [ "$IS_TTY" = true ]; then
  INTERACTIVE=true
fi

# 如果非 TTY 且非 quiet 且非 dry-run，提示用户下载后执行
if [ "$IS_TTY" = false ] && [ "$QUIET" = false ] && [ "$DRY_RUN" = false ]; then
  # 检查是否通过管道运行 (stdin 不是终端)
  if [ ! -t 0 ]; then
    echo "检测到非交互环境 (管道/重定向)。"
    echo ""
    echo "本脚本支持交互式引导安装，但在管道中无法交互。"
    echo "建议先下载到本地再执行:"
    echo ""
    echo "  curl -fsSL https://raw.githubusercontent.com/TiMEM-AI/TiMEM-SKILL/main/install-all.sh -o install-all.sh"
    echo "  bash install-all.sh"
    echo ""
    echo "或使用非交互参数直接安装:"
    echo "  curl -fsSL .../install-all.sh | bash -s -- --api-key YOUR_KEY"
    echo ""
    # 自动下载到临时文件并执行
    echo "是否自动下载到临时文件并以交互模式执行? (y/n)"
    read -r _auto_dl 2>/dev/null || _auto_dl="n"
    if [ "$_auto_dl" = "y" ] || [ "$_auto_dl" = "Y" ]; then
      _tmp_script="$(mktemp /tmp/timem-install-all.XXXXXX.sh)"
      # 从管道读取剩余内容写入临时文件
      cat > "$_tmp_script"
      if [ -s "$_tmp_script" ]; then
        exec bash "$_tmp_script" "$@"
      fi
    fi
    echo "继续以非交互模式安装..."
    INTERACTIVE=false
  fi
fi

# 语言: zh / en
LANG_SEL="zh"

# i18n 文本函数
# 用法: t "中文" "English"
t() {
  if [ "$LANG_SEL" = "zh" ]; then
    echo "$1"
  else
    echo "$2"
  fi
}

# ============================================================================
# 日志函数
# ============================================================================

info()    { [ "$QUIET" = false ] && echo "  [INFO] $1" || true; }
success() { [ "$QUIET" = false ] && echo "  [OK] $1" || true; }
warn()    { [ "$QUIET" = false ] && echo "  [WARN] $1" || true; }
error()   { echo "  [FAIL] $1" >&2; }
dryrun()  { [ "$QUIET" = false ] && echo "  [DRY] $1" || true; }

# 结果追踪
declare -a RESULTS_NAME RESULTS_STATUS RESULTS_DETAIL
RESULT_OK=0
RESULT_FAIL=0
RESULT_SKIP=0

record_result() {
  RESULTS_NAME+=("$1")
  RESULTS_STATUS+=("$2")
  RESULTS_DETAIL+=("${3:-}")
  case "$2" in
    OK)   RESULT_OK=$((RESULT_OK + 1)) ;;
    FAIL) RESULT_FAIL=$((RESULT_FAIL + 1)) ;;
    SKIP) RESULT_SKIP=$((RESULT_SKIP + 1)) ;;
  esac
}

# ============================================================================
# 临时目录
# ============================================================================

TMPDIR_WORK="$(mktemp -d /tmp/timem-install-all.XXXXXX)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# ============================================================================
# Agent 检测
# ============================================================================

detect_agent() {
  local detect_cmd="$1" config_dir="$2" candidate
  shift 2
  command -v "$detect_cmd" &>/dev/null && return 0
  [ -d "$config_dir" ] && return 0
  for candidate in "$@"; do
    [ -n "$candidate" ] && [ -d "$candidate" ] && return 0
  done
  return 1
}

detect_claude_desktop() {
  for cfg in "${CLAUDE_DESKTOP_CONFIGS[@]}"; do
    if [ -f "$cfg" ] || [ -d "$(dirname "$cfg")" ]; then
      echo "$cfg"
      return 0
    fi
  done
  return 1
}

agent_in_filter() {
  [ -z "$AGENT_FILTER" ] && return 0
  echo ",$AGENT_FILTER," | grep -q ",$1,"
}

# ============================================================================
# 下载 TiMEM-SKILL
# ============================================================================

download_skills() {
  local dest="$TMPDIR_WORK/timem-skill"
  local tarball="$TMPDIR_WORK/timem-skill.tar.gz"

  if [ "$DRY_RUN" = true ]; then
    dryrun "会从 $TIMEM_SKILL_REPO 下载 tarball"
    return 0
  fi

  info "下载 TiMEM-SKILL 仓库..."
  if curl -fsSL "$TIMEM_SKILL_REPO/archive/refs/heads/main.tar.gz" -o "$tarball" 2>/dev/null; then
    mkdir -p "$dest"
    tar xzf "$tarball" -C "$dest" --strip-components=1 2>/dev/null
    if [ -d "$dest/dist/standalone" ] || [ -d "$dest/skills" ]; then
      success "TiMEM-SKILL 已下载"
      return 0
    else
      error "tarball 解压后未找到预期目录结构"
      return 1
    fi
  else
    error "下载 TiMEM-SKILL 失败 (网络问题？)"
    return 1
  fi
}

# ============================================================================
# Skill 安装
# ============================================================================

install_one_skill() {
  local skill_name="$1" src_rel="$2" dest_dir="$3"
  local src="$TMPDIR_WORK/timem-skill/$src_rel"
  local dst="$dest_dir/$skill_name"

  if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
    warn "skill 源不存在或缺少 SKILL.md: $src_rel"
    return 1
  fi

  if [ "$DRY_RUN" = true ]; then
    dryrun "skill: $skill_name -> $dst"
    return 0
  fi

  mkdir -p "$dest_dir"

  if [ -e "$dst" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$dst"
    elif diff -r "$src" "$dst" >/dev/null 2>&1; then
      info "skill '$skill_name' 已存在且相同，跳过"
      return 0
    else
      [ -e "$dst.bak" ] && rm -rf "$dst.bak"
      cp -r "$dst" "$dst.bak"
      warn "skill '$skill_name' 已存在且不同，已备份 .bak"
      rm -rf "$dst"
    fi
  fi

  cp -r "$src" "$dst"
  success "skill '$skill_name' 已安装"
  return 0
}

install_skills_for_agent() {
  local agent_name="$1" skills_dir="$2"
  local installed=0 failed=0

  for skill_entry in "${ALL_SKILLS[@]}"; do
    IFS=':' read -r skill_name skill_path <<< "$skill_entry"
    if [ -n "$SKILLS_FILTER" ]; then
      echo ",$SKILLS_FILTER," | grep -q ",$skill_name," || continue
    fi
    if install_one_skill "$skill_name" "$skill_path" "$skills_dir"; then
      installed=$((installed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo "$installed:$failed"
}

# ============================================================================
# MCP 配置生成
# ============================================================================

generate_mcp_server_json() {
  local agent_name="$1"
  printf '{"url":"%s","headers":{"X-API-Key":"%s"}}' \
    "$TIMEM_CLOUD_URL" "$API_KEY"
}

# ============================================================================
# MCP 合并 - JSON
# ============================================================================

merge_mcp_json() {
  local config_file="$1" agent_name="$2" root_key="$3"
  local server_name="${TIMEM_SERVER_NAME}"
  local server_config
  server_config="$(generate_mcp_server_json "$agent_name")"

  if [ "$DRY_RUN" = true ]; then
    dryrun "合并 MCP -> $config_file (key=$root_key)"
    return 0
  fi

  mkdir -p "$(dirname "$config_file")"

  local result
  result=$(python3 - "$config_file" "$root_key" "$server_name" "$server_config" "$FORCE" 2>&1 <<'PYEOF'
import json, sys, shutil, os
config_path, root_key, server_name, server_config_str, force = sys.argv[1:6]
force = force == "true"
server_config = json.loads(server_config_str)

if not os.path.exists(config_path):
    config = {root_key: {server_name: server_config}}
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print("CREATED"); sys.exit(0)

try:
    with open(config_path) as f:
        config = json.load(f)
except (json.JSONDecodeError, OSError) as e:
    print(f"ERROR:{e}", file=sys.stderr); sys.exit(2)

keys = root_key.split(".")
d = config
for k in keys[:-1]:
    d = d.setdefault(k, {})
servers = d.setdefault(keys[-1], {})

if server_name in servers:
    if force:
        servers[server_name] = server_config
    elif servers[server_name] == server_config:
        print("SKIP"); sys.exit(0)
    else:
        shutil.copy2(config_path, config_path + ".bak")
        servers[server_name] = server_config
else:
    servers[server_name] = server_config

with open(config_path, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print("MERGED")
PYEOF
  )
  local rc=$?

  if [ $rc -ne 0 ]; then
    error "合并 $config_file 失败: $result"
    return 1
  fi

  case "$result" in
    CREATED) success "MCP 配置已写入: $config_file" ;;
    MERGED)  success "MCP 配置已合并: $config_file" ;;
    SKIP)    info "MCP 配置已存在且相同，跳过: $config_file" ;;
  esac
  return 0
}

# ============================================================================
# MCP 合并 - TOML (Codex)
# ============================================================================

merge_mcp_toml() {
  local config_file="$1" agent_name="$2"
  local server_name="${TIMEM_SERVER_NAME}"

  if [ "$DRY_RUN" = true ]; then
    dryrun "合并 MCP -> $config_file (TOML)"
    return 0
  fi

  mkdir -p "$(dirname "$config_file")"

  if [ -f "$config_file" ] && grep -q "^\[mcp_servers\.${server_name}\]" "$config_file" 2>/dev/null; then
    if [ "$FORCE" = true ]; then
      warn "TOML MCP 已存在，--force 对 TOML 精确覆盖暂不支持，跳过"
      return 0
    else
      info "MCP 配置已存在，跳过: $config_file"
      return 0
    fi
  fi

  [ -f "$config_file" ] && [ "$FORCE" = false ] && cp "$config_file" "$config_file.bak" 2>/dev/null || true

  # Codex TOML: stdio 模式 (Codex 不原生支持 http MCP)
  cat >> "$config_file" <<TOMLEOF

[mcp_servers.${server_name}]
command = "uvx"
args = ["--from", "git+${TIMEM_MCP_REPO}.git@main", "timem-mcp"]

[mcp_servers.${server_name}.env]
TIMEM_API_KEY = "${API_KEY}"
TIMEM_API_HOST = "${TIMEM_API_HOST_DEFAULT}"
TIMEM_AGENT_ID = "${agent_name}"
TOMLEOF
  success "MCP 配置已追加: $config_file"
  return 0
}

# ============================================================================
# MCP 合并 - YAML (Hermes)
# ============================================================================

merge_mcp_yaml() {
  local config_file="$1" agent_name="$2"
  local server_name="${TIMEM_SERVER_NAME}"

  if [ "$DRY_RUN" = true ]; then
    dryrun "合并 MCP -> $config_file (YAML)"
    return 0
  fi

  mkdir -p "$(dirname "$config_file")"

  if [ -f "$config_file" ] && grep -q "^[[:space:]]*${server_name}:" "$config_file" 2>/dev/null; then
    if [ "$FORCE" = true ]; then
      warn "YAML MCP 已存在，--force 对 YAML 精确覆盖暂不支持，跳过"
      return 0
    else
      info "MCP 配置已存在，跳过: $config_file"
      return 0
    fi
  fi

  [ -f "$config_file" ] && [ "$FORCE" = false ] && cp "$config_file" "$config_file.bak" 2>/dev/null || true

  cat >> "$config_file" <<YAMLEOF

mcp_servers:
  ${server_name}:
    url: "${TIMEM_CLOUD_URL}"
    headers:
      X-API-Key: ***
YAMLEOF
  success "MCP 配置已追加: $config_file"
  return 0
}

# ============================================================================
# 全局 / 工作区 Agent 指令注入
# ============================================================================

resolve_agent_instruction_file() {
  local config_dir="$1" instruction_file="$2" candidate
  local -a candidates

  case "$instruction_file" in
    # Linux 文件系统通常大小写敏感：优先复用已有 Agent 指令文件，
    # 避免仅因扩展名使用 .MD 而额外创建一个 AGENTS.md。
    AGENTS.md) candidates=("AGENTS.md" "AGENTS.MD" "AGENT.md" "AGENT.MD" "agents.md" "agents.MD" "agent.md" "agent.MD") ;;
    CLAUDE.md) candidates=("CLAUDE.md" "CLAUDE.MD" "claude.md" "claude.MD") ;;
    *) candidates=("$instruction_file") ;;
  esac

  for candidate in "${candidates[@]}"; do
    if [ -f "$config_dir/$candidate" ]; then
      printf '%s\n' "$config_dir/$candidate"
      return 0
    fi
  done

  printf '%s\n' "$config_dir/$instruction_file"
}

resolve_openclaw_instruction_dirs() {
  local config_dir="$1" config_file="$2"

  python3 - "$config_dir" "$config_file" <<'PYEOF'
import json
import os
import sys

config_dir, config_file = sys.argv[1:3]

def resolve_workspace(value):
    value = (value or "").strip()
    if value == "~" or value.startswith("~/"):
        return os.path.expanduser(value)
    if os.path.isabs(value):
        return value
    return os.path.normpath(os.path.join(config_dir, value))

config = {}
if os.path.isfile(config_file):
    try:
        with open(config_file, "r", encoding="utf-8") as handle:
            config = json.load(handle)
    except Exception as exc:
        print("OpenClaw workspace 配置解析失败，将使用默认路径: " + str(exc), file=sys.stderr)

agents = config.get("agents") if isinstance(config, dict) else {}
if not isinstance(agents, dict):
    agents = {}

environment_workspace = os.environ.get("OPENCLAW_WORKSPACE_DIR", "").strip()
configured_workspace = (agents.get("defaults") or {}).get("workspace") if isinstance(agents.get("defaults"), dict) else ""
workspace_setting = environment_workspace or configured_workspace
if workspace_setting:
    default_workspace = resolve_workspace(workspace_setting)
else:
    profile = os.environ.get("OPENCLAW_PROFILE", "").strip()
    suffix = "" if not profile or profile.lower() == "default" else "-" + profile
    default_workspace = os.path.join(config_dir, "workspace" + suffix)

directories = []
def add_directory(path):
    if path and path not in directories:
        directories.append(path)

add_directory(default_workspace)
entries = agents.get("list")
if not isinstance(entries, list):
    entries = []
entries = list(entries)
configured_entries = agents.get("entries")
if isinstance(configured_entries, dict):
    for agent_id, entry in configured_entries.items():
        if isinstance(entry, dict):
            entries.append({"id": agent_id, "workspace": entry.get("workspace")})

for entry in entries:
    if not isinstance(entry, dict):
        continue
    agent_id = str(entry.get("id") or entry.get("name") or "").strip()
    workspace = entry.get("workspace")
    if workspace:
        add_directory(resolve_workspace(str(workspace)))
    elif agent_id and agent_id.lower() not in ("main", "default"):
        add_directory(os.path.join(config_dir, "workspace-" + agent_id))

for directory in directories:
    print(directory)
PYEOF
}

ensure_cursor_user_rule() {
  local agent_name="$1" config_dir="$2"
  local rules_dir="$config_dir/rules"
  local instruction_path="$rules_dir/timem-memory.mdc"
  local grep_status

  if [ "$SKIP_AGENT_INSTRUCTIONS" = true ]; then
    info "已跳过 Agent 指令注入"
    return 0
  fi

  if [ -e "$instruction_path" ] && [ ! -f "$instruction_path" ]; then
    error "Cursor User Rule 路径不是文件 ($agent_name): $instruction_path"
    return 1
  fi

  if [ -f "$instruction_path" ]; then
    grep -Eiq -- "$TIMEM_INSTRUCTION_MARKER_REGEX" "$instruction_path"
    grep_status=$?
    if [ "$grep_status" -eq 0 ]; then
      info "Cursor User Rule 已包含 TiMEM 标记: $instruction_path"
      return 0
    fi
    if [ "$grep_status" -ne 1 ]; then
      error "无法读取 Cursor User Rule ($agent_name): $instruction_path"
      return 1
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    dryrun "注入 Cursor User Rule -> $instruction_path"
    return 0
  fi

  mkdir -p "$rules_dir" || {
    error "无法创建 Cursor User Rule 目录 ($agent_name): $rules_dir"
    return 1
  }

  if [ -f "$instruction_path" ] && [ -s "$instruction_path" ]; then
    if tail -c 1 "$instruction_path" | grep -q '^$'; then
      printf '%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 Cursor User Rule ($agent_name): $instruction_path"
        return 1
      }
    else
      printf '\n%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 Cursor User Rule ($agent_name): $instruction_path"
        return 1
      }
    fi
  else
    printf '%s\n' '---' 'description: "TiMEM memory workflow"' 'alwaysApply: true' '---' '' "$TIMEM_AGENT_INSTRUCTION" > "$instruction_path" || {
      error "无法创建 Cursor User Rule ($agent_name): $instruction_path"
      return 1
    }
  fi

  success "Cursor User Rule 已注入: $instruction_path"
}

ensure_trae_user_rule() {
  local agent_name="$1"
  local rules_dir="$HOME/.trae/user_rules"
  local instruction_path="$rules_dir/timem-memory.md"
  local grep_status

  if [ "$SKIP_AGENT_INSTRUCTIONS" = true ]; then
    info "已跳过 Agent 指令注入"
    return 0
  fi

  if [ -e "$instruction_path" ] && [ ! -f "$instruction_path" ]; then
    error "TRAE Global Rule 路径不是文件 ($agent_name): $instruction_path"
    return 1
  fi

  if [ -f "$instruction_path" ]; then
    grep -Eiq -- "$TIMEM_INSTRUCTION_MARKER_REGEX" "$instruction_path"
    grep_status=$?
    if [ "$grep_status" -eq 0 ]; then
      info "TRAE Global Rule 已包含 TiMEM 标记: $instruction_path"
      return 0
    fi
    if [ "$grep_status" -ne 1 ]; then
      error "无法读取 TRAE Global Rule ($agent_name): $instruction_path"
      return 1
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    dryrun "注入 TRAE Global Rule -> $instruction_path"
    return 0
  fi

  mkdir -p "$rules_dir" || {
    error "无法创建 TRAE Global Rule 目录 ($agent_name): $rules_dir"
    return 1
  }

  if [ -f "$instruction_path" ] && [ -s "$instruction_path" ]; then
    if tail -c 1 "$instruction_path" | grep -q '^$'; then
      printf '%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 TRAE Global Rule ($agent_name): $instruction_path"
        return 1
      }
    else
      printf '\n%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 TRAE Global Rule ($agent_name): $instruction_path"
        return 1
      }
    fi
  else
    printf '%s\n' '---' 'alwaysApply: true' '---' '' "$TIMEM_AGENT_INSTRUCTION" > "$instruction_path" || {
      error "无法创建 TRAE Global Rule ($agent_name): $instruction_path"
      return 1
    }
  fi

  success "TRAE Global Rule 已注入: $instruction_path"
}

ensure_agent_instruction() {
  local agent_name="$1" instruction_dir="$2" instruction_file="$3" create_if_missing="${4:-yes}"
  local instruction_path grep_status

  if [ "$SKIP_AGENT_INSTRUCTIONS" = true ]; then
    info "已跳过 Agent 指令注入"
    return 0
  fi

  instruction_path="$(resolve_agent_instruction_file "$instruction_dir" "$instruction_file")"
  if [ -e "$instruction_path" ] && [ ! -f "$instruction_path" ]; then
    error "Agent 指令路径不是文件 ($agent_name): $instruction_path"
    return 1
  fi
  if [ "$create_if_missing" = "no" ] && [ ! -e "$instruction_path" ]; then
    info "Agent 指令文件不存在，保留默认行为 (跳过): $instruction_path"
    return 0
  fi

  if [ -f "$instruction_path" ]; then
    grep -Eiq -- "$TIMEM_INSTRUCTION_MARKER_REGEX" "$instruction_path"
    grep_status=$?
    if [ "$grep_status" -eq 0 ]; then
      info "Agent 指令已包含 TiMEM 标记: $instruction_path"
      return 0
    fi
    if [ "$grep_status" -ne 1 ]; then
      error "无法读取 Agent 指令文件 ($agent_name): $instruction_path"
      return 1
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    dryrun "注入 Agent 指令 -> $instruction_path"
    return 0
  fi

  mkdir -p "$instruction_dir" || {
    error "无法创建 Agent 指令目录 ($agent_name): $instruction_dir"
    return 1
  }

  if [ -f "$instruction_path" ] && [ -s "$instruction_path" ]; then
    if tail -c 1 "$instruction_path" | grep -q '^$'; then
      printf '%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 Agent 指令文件 ($agent_name): $instruction_path"
        return 1
      }
    else
      printf '\n%s\n' "$TIMEM_AGENT_INSTRUCTION" >> "$instruction_path" || {
        error "无法写入 Agent 指令文件 ($agent_name): $instruction_path"
        return 1
      }
    fi
  else
    printf '%s\n' "$TIMEM_AGENT_INSTRUCTION" > "$instruction_path" || {
      error "无法创建 Agent 指令文件 ($agent_name): $instruction_path"
      return 1
    }
  fi

  success "Agent 指令已注入: $instruction_path"
}

# ============================================================================
# 为单个 agent 安装 (skills + mcp + instructions)
# ============================================================================

install_for_agent() {
  local agent_line="$1"
  IFS='|' read -r name detect_cmd config_dir skills_dir mcp_config fmt root_key has_skills instruction_file instruction_scope instruction_create_if_missing additional_detect_dir <<< "$agent_line"

  echo ""
  echo "━━━ $name ━━━"

  if ! agent_in_filter "$name"; then
    info "被 --agent 过滤跳过"
    record_result "$name" "SKIP" "filtered out"
    return 0
  fi

  if ! detect_agent "$detect_cmd" "$config_dir" "$additional_detect_dir"; then
    info "未检测到 $name (跳过)"
    record_result "$name" "SKIP" "not installed"
    return 0
  fi

  success "检测到 $name"
  local agent_failed=false

  # 安装 skills
  if [ "$SKIP_SKILLS" = false ] && [ "$has_skills" = "yes" ]; then
    info "安装 skills 到 $skills_dir ..."
    local skill_result
    skill_result="$(install_skills_for_agent "$name" "$skills_dir")"
    local s_ok="${skill_result%%:*}"
    local s_fail="${skill_result##*:}"
    if [ "$s_fail" -gt 0 ]; then
      warn "skills: $s_ok 成功, $s_fail 失败"
    else
      success "skills: $s_ok 个已安装"
    fi
  fi

  # 合并 MCP
  if [ "$SKIP_MCP" = false ]; then
    info "合并 MCP 配置到 $mcp_config ..."
    case "$fmt" in
      json) merge_mcp_json "$mcp_config" "$name" "$root_key" || agent_failed=true ;;
      toml) merge_mcp_toml "$mcp_config" "$name" || agent_failed=true ;;
      yaml) merge_mcp_yaml "$mcp_config" "$name" || agent_failed=true ;;
      *)    warn "未知配置格式: $fmt (跳过 MCP)" ;;
    esac
  fi

  if [ -n "$instruction_file" ]; then
    if [ "$instruction_scope" = "cursor-user-rules" ]; then
      ensure_cursor_user_rule "$name" "$config_dir" || agent_failed=true
    elif [ "$instruction_scope" = "trae-user-rules" ]; then
      ensure_trae_user_rule "$name" || agent_failed=true
    elif [ "$instruction_scope" = "openclaw-workspaces" ]; then
      local instruction_dir
      while IFS= read -r instruction_dir; do
        [ -z "$instruction_dir" ] && continue
        ensure_agent_instruction "$name" "$instruction_dir" "$instruction_file" "$instruction_create_if_missing" || agent_failed=true
      done < <(resolve_openclaw_instruction_dirs "$config_dir" "$mcp_config")
    else
      ensure_agent_instruction "$name" "$config_dir" "$instruction_file" "$instruction_create_if_missing" || agent_failed=true
    fi
  fi

  if [ "$agent_failed" = true ]; then
    record_result "$name" "FAIL" "MCP merge or agent instruction update failed"
  else
    record_result "$name" "OK" "skills+MCP${instruction_file:+ +instructions}"
  fi
}

# ============================================================================
# Claude Desktop (MCP only, no skills)
# ============================================================================

install_claude_desktop() {
  echo ""
  echo "━━━ claude-desktop ━━━"

  if ! agent_in_filter "claude-desktop"; then
    info "被 --agent 过滤跳过"
    record_result "claude-desktop" "SKIP" "filtered out"
    return 0
  fi

  local desktop_config
  desktop_config="$(detect_claude_desktop)"
  if [ -z "$desktop_config" ]; then
    info "未检测到 Claude Desktop (跳过)"
    record_result "claude-desktop" "SKIP" "not installed"
    return 0
  fi

  success "检测到 Claude Desktop: $desktop_config"

  if [ "$SKIP_MCP" = true ]; then
    info "跳过 MCP (--skip-mcp)"
    record_result "claude-desktop" "OK" "skills only (no MCP)"
    return 0
  fi

  info "合并 MCP 配置到 $desktop_config ..."
  if merge_mcp_json "$desktop_config" "claude-desktop" "mcpServers"; then
    record_result "claude-desktop" "OK" "MCP only"
  else
    record_result "claude-desktop" "FAIL" "MCP merge failed"
  fi
}

# ============================================================================
# 交互式引导函数
# ============================================================================

# --- 1. 语言选择 ---
interactive_select_language() {
  echo ""
  echo "请选择语言 / Select language:"
  echo "  1) 中文"
  echo "  2) English"
  echo "  3) $(t "静默安装（一键全装）" "Silent install (all defaults)")"
  echo -n "> "
  read -r lang_choice
  case "$lang_choice" in
    1|zh|中文) LANG_SEL="zh" ;;
    2|en|English) LANG_SEL="en" ;;
    3|silent|静默)
      LANG_SEL="zh"
      SILENT_MODE=true
      ;;
    *) LANG_SEL="zh" ;;
  esac
}

# --- 2. Agent 选择 ---
interactive_select_agents() {
  # 如果 --agent 已指定，跳过
  if [ -n "$AGENT_FILTER" ]; then
    return 0
  fi

  echo ""
  echo "$(t "检测到以下已安装的 Agent 工具:" "Detected installed Agent tools:")"
  echo ""

  declare -a detected_names detected_dirs
  local idx=1

  for agent_line in "${AGENTS[@]}"; do
    IFS='|' read -r name detect_cmd config_dir _ _ _ _ _ _ _ _ additional_detect_dir <<< "$agent_line"
    if detect_agent "$detect_cmd" "$config_dir" "$additional_detect_dir"; then
      detected_names+=("$name")
      detected_dirs+=("$config_dir")
      printf "  [%d] %-14s (%s)\n" "$idx" "$name" "$config_dir"
      idx=$((idx + 1))
    fi
  done

  # 检测 Claude Desktop
  local desktop_config
  desktop_config="$(detect_claude_desktop 2>/dev/null || true)"
  if [ -n "$desktop_config" ]; then
    detected_names+=("claude-desktop")
    detected_dirs+=("$desktop_config")
    printf "  [%d] %-14s (%s)\n" "$idx" "claude-desktop" "$desktop_config"
    idx=$((idx + 1))
  fi

  local total_detected=${#detected_names[@]}

  if [ "$total_detected" -eq 0 ]; then
    echo "$(t "  未检测到任何已安装的 Agent 工具" "  No installed Agent tools detected")"
    echo "$(t "  支持的 agent: ${AGENTS[*]%%|*}" "  Supported: ${AGENTS[*]%%|*}")"
    return 0
  fi

  echo ""
  echo "$(t "选择安装目标:" "Select installation target:")"
  echo "  a) $(t "全部安装" "Install all")"
  echo "  s) $(t "选择部分安装" "Select specific")"
  echo "  q) $(t "退出" "Quit")"
  echo -n "> "
  read -r agent_choice

  case "$agent_choice" in
    a|A|"")
      AGENT_FILTER=""
      ;;
    q|Q)
      echo "$(t "已取消安装。" "Installation cancelled.")"
      exit 0
      ;;
    s|S)
      echo "$(t "请输入要安装的编号，用空格分隔 (如: 1 3 5):" "Enter numbers, space-separated (e.g: 1 3 5):")"
      echo -n "> "
      read -r agent_nums
      local selected=""
      for num in $agent_nums; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total_detected" ]; then
          if [ -n "$selected" ]; then
            selected="$selected,"
          fi
          selected="$selected${detected_names[$((num - 1))]}"
        else
          warn "$(t "忽略无效编号: $num" "Ignoring invalid number: $num")"
        fi
      done
      if [ -n "$selected" ]; then
        AGENT_FILTER="$selected"
      else
        echo "$(t "未选择任何 agent，将安装全部。" "No agent selected, installing all.")"
      fi
      ;;
    *)
      warn "$(t "无效选项: $agent_choice" "Invalid choice: $agent_choice")"
      AGENT_FILTER=""
      ;;
  esac
}

# --- 3. API Key 输入 ---
interactive_input_apikey() {
  # 如果 --api-key 已指定或环境变量已设置，跳过
  if [ -n "$API_KEY" ]; then
    return 0
  fi

  echo ""
  echo "$(t "请输入 TiMEM API Key (可在 space.timem.cloud 获取):" "Enter TiMEM API Key (get it from space.timem.cloud):")"

  # 尝试密码模式 (不回显)
  local key=""
  if [ -t 0 ]; then
    read -rs -p "> " key
    echo ""
  else
    read -r key
  fi

  if [ -n "$key" ]; then
    API_KEY="$key"
  else
    warn "$(t "未输入 API Key，MCP 配置将使用占位符。" "No API Key entered, MCP config will use placeholder.")"
  fi
}

# --- 4. Skill 选择 ---
interactive_select_skills() {
  # 如果 --skills 已指定，跳过
  if [ -n "$SKILLS_FILTER" ]; then
    return 0
  fi

  echo ""
  echo "$(t "选择要安装的 Skills:" "Select Skills to install:")"
  echo ""

  local idx=1
  declare -a skill_names
  for skill_entry in "${ALL_SKILLS[@]}"; do
    IFS=':' read -r skill_name _ <<< "$skill_entry"
    skill_names+=("$skill_name")
    local desc=""
    case "$skill_name" in
      timem-coding-memory)  desc="$(t "编程记忆" "Coding memory")" ;;
      timem-general-memory) desc="$(t "通用记忆" "General memory")" ;;
      timem-writing-memory) desc="$(t "写作记忆" "Writing memory")" ;;
    esac
    printf "  [%d] %s (%s)\n" "$idx" "$skill_name" "$desc"
    idx=$((idx + 1))
  done

  echo ""
  echo "  a) $(t "全部安装 (推荐)" "Install all (recommended)")"
  echo "  s) $(t "选择部分安装" "Select specific")"
  echo -n "> "
  read -r skill_choice

  case "$skill_choice" in
    a|A|"")
      SKILLS_FILTER=""
      ;;
    s|S)
      echo "$(t "请输入要安装的编号，用空格分隔 (如: 1 3 5):" "Enter numbers, space-separated (e.g: 1 3 5):")"
      echo -n "> "
      read -r skill_nums
      local selected=""
      for num in $skill_nums; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#skill_names[@]}" ]; then
          if [ -n "$selected" ]; then
            selected="$selected,"
          fi
          selected="$selected${skill_names[$((num - 1))]}"
        else
          warn "$(t "忽略无效编号: $num" "Ignoring invalid number: $num")"
        fi
      done
      if [ -n "$selected" ]; then
        SKILLS_FILTER="$selected"
      else
        echo "$(t "未选择任何 skill，将安装全部。" "No skill selected, installing all.")"
      fi
      ;;
    *)
      warn "$(t "无效选项: $skill_choice" "Invalid choice: $skill_choice")"
      SKILLS_FILTER=""
      ;;
  esac
}

# --- 5. 确认 ---
interactive_confirm() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$(t "安装摘要:" "Installation Summary:")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Agent
  local agent_display
  if [ -n "$AGENT_FILTER" ]; then
    agent_display="$AGENT_FILTER"
  else
    agent_display="$(t "全部 (已检测的)" "All (detected)")"
  fi
  printf "  %-12s %s\n" "$(t "Agent:" "Agent:")" "$agent_display"

  # Skills
  local skill_display
  if [ -n "$SKILLS_FILTER" ]; then
    skill_display="$SKILLS_FILTER"
  else
    local skill_count=${#ALL_SKILLS[@]}
    skill_display="$(t "全部 (${skill_count}个)" "All (${skill_count})")"
  fi
  printf "  %-12s %s\n" "$(t "Skills:" "Skills:")" "$skill_display"

  # MCP 模式
  local mcp_mode
  if [ "$SKIP_MCP" = true ]; then
    mcp_mode="$(t "跳过" "Skipped")"
  else
    mcp_mode="Cloud HTTP"
  fi
  printf "  %-12s %s\n" "$(t "MCP 模式:" "MCP Mode:")" "$mcp_mode"

  local instruction_mode
  if [ "$SKIP_AGENT_INSTRUCTIONS" = true ]; then
    instruction_mode="$(t "跳过" "Skipped")"
  else
    instruction_mode="$(t "注入已支持的 agent" "Inject for supported agents")"
  fi
  printf "  %-12s %s\n" "$(t "Agent 指令:" "Agent instructions:")" "$instruction_mode"

  # API Key (掩码显示)
  local key_display
  if [ -n "$API_KEY" ]; then
    local key_len=${#API_KEY}
    if [ "$key_len" -le 8 ]; then
      key_display="***"
    else
      key_display="${API_KEY:0:4}...${API_KEY: -4}"
    fi
  else
    key_display="$(t "未设置" "Not set")"
  fi
  printf "  %-12s %s\n" "API Key:" "$key_display"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo -n "$(t "确认安装? (y/n) " "Confirm installation? (y/n) ")"
  read -r confirm
  case "$confirm" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "$(t "已取消安装。" "Installation cancelled.")"
      exit 0
      ;;
  esac
}

# ============================================================================
# 主流程
# ============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  TiMEM Skill 一键安装 (install-all.sh)                        ║"
echo "║  为所有已检测的 Agent 工具安装 TiMEM Skills + MCP 配置         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# --- 交互式引导 ---
if [ "$INTERACTIVE" = true ]; then
  # 1. 语言选择
  interactive_select_language

  # 静默模式：只输入 API Key，然后一键全装
  if [ "$SILENT_MODE" = true ]; then
    interactive_input_apikey
    echo "$(t "静默安装：将为所有已检测的 Agent 工具安装全部 Skills + MCP" "Silent install: all skills + MCP for all detected agents")"
  else
    # 2. API Key 输入
    interactive_input_apikey

    # 3. Agent 选择
    interactive_select_agents

    # 4. Skill 选择
    interactive_select_skills

    # 5. 确认
    interactive_confirm
  fi
fi

# 显示配置
info "MCP 模式: Cloud HTTP (零安装)"
info "API Key: $([ -n "$API_KEY" ] && echo '已设置' || echo '未设置 (用 --api-key 或 \$TIMEM_API_KEY)')"
info "Dry-run: $DRY_RUN"
info "Agent 指令注入: $([ "$SKIP_AGENT_INSTRUCTIONS" = true ] && echo '跳过' || echo '已启用')"
[ -n "$SKILLS_FILTER" ] && info "Skills 过滤: $SKILLS_FILTER"
[ -n "$AGENT_FILTER" ]  && info "Agent 过滤: $AGENT_FILTER"

# 检查依赖
if ! command -v python3 &>/dev/null; then
  error "需要 python3 (用于 JSON 合并)"
  exit 1
fi
if ! command -v curl &>/dev/null; then
  error "需要 curl"
  exit 1
fi

# 下载 skills (除非 --skip-skills)
if [ "$SKIP_SKILLS" = false ]; then
  download_skills || {
    warn "TiMEM-SKILL 下载失败，skills 安装将跳过"
    SKIP_SKILLS=true
  }
fi

# 遍历所有 agent
for agent_line in "${AGENTS[@]}"; do
  install_for_agent "$agent_line"
done

# Claude Desktop
install_claude_desktop

# ============================================================================
# 摘要
# ============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  安装摘要                                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

for i in "${!RESULTS_NAME[@]}"; do
  name="${RESULTS_NAME[$i]}"
  status="${RESULTS_STATUS[$i]}"
  detail="${RESULTS_DETAIL[$i]}"
  case "$status" in
    OK)   echo "  [OK]   $name  ($detail)" ;;
    FAIL) echo "  [FAIL] $name  ($detail)" ;;
    SKIP) echo "  [SKIP] $name  ($detail)" ;;
  esac
done

echo ""
echo "  总计: $((RESULT_OK + RESULT_FAIL + RESULT_SKIP)) 个 agent"
echo "  成功: $RESULT_OK | 失败: $RESULT_FAIL | 跳过: $RESULT_SKIP"
echo ""

if [ $RESULT_FAIL -gt 0 ]; then
  echo "  ⚠️  有 $RESULT_FAIL 个 agent 安装失败，请检查上方日志"
  exit 1
fi

if [ $RESULT_OK -eq 0 ]; then
  echo "  ℹ️  没有检测到任何已安装的 Agent 工具"
  echo "  支持的 agent: claude-code, codex, cursor, openclaw, hermes, trae, workbuddy, qoder, claude-desktop"
  exit 0
fi

echo "  ✅ 所有检测到的 agent 均已安装完成"
echo ""
echo "  下一步:"
echo "    1. 配置环境变量 TIMEM_API_KEY (如尚未配置)"
echo "    2. 重启对应的 Agent 工具"
echo ""

echo "  提示: 当前使用 Cloud HTTP 模式 (零安装)"
echo ""
