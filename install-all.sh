#!/bin/bash
#
# AICI CC Plugin - 一键安装到所有已检测的 AI Agent CLI
#
# 功能:
#   - 自动检测已安装的 agent CLI (Claude Code, Codex, Cursor, OpenClaw, Hermes,
#     Trae, CodeBuddy, Qoder, Claude Desktop)
#   - 为每个 agent 安装 TiMEM Skills (5 个) + 合并 TiMEM MCP 配置
#   - 幂等: 重复安装安全，已有配置不覆盖，同名 skill 先 .bak 备份
#   - 部分 agent 失败不影响其他，最后汇总
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/AIGility-Cloud-Innovation/aici-cc-plugin/main/install-all.sh | bash
#   bash install-all.sh [OPTIONS]
#
# 参数:
#   --api-key KEY       TiMEM API Key (默认读 $TIMEM_API_KEY 环境变量)
#   --user-id ID        TiMEM 用户 ID (默认: $USER 或 "default")
#   --skills LIST       只安装指定 skill (逗号分隔，默认全部 5 个)
#   --local             使用本地 stdio MCP (uvx) 而非 Cloud HTTP
#   --skip-mcp          跳过 MCP 配置，只装 skills
#   --skip-skills       跳过 skills，只配 MCP
#   --force             强制覆盖已有配置 (不用 .bak)
#   --quiet             静默模式，只输出错误和最终摘要
#   --dry-run           只检测和打印，不实际安装
#   --agent NAME        只安装指定 agent (逗号分隔)
#   --help              显示帮助
#
# MCP 配置方式:
#   默认 (Cloud HTTP):  "url": "https://api.timem.cloud/mcp" + headers (零安装)
#   --local (stdio):    uvx --from git+https://github.com/TiMEM-AI/timem-mcp@main timem-mcp

set -uo pipefail

# ============================================================================
# 常量
# ============================================================================

TIMEM_SKILL_REPO="https://github.com/TiMEM-AI/TiMEM-SKILL"
TIMEM_MCP_REPO="https://github.com/TiMEM-AI/timem-mcp"
TIMEM_CLOUD_URL="https://api.timem.cloud/mcp"
TIMEM_API_HOST_DEFAULT="https://api.timem.cloud"

# 5 个 TiMEM skills: name:repo_relative_path
ALL_SKILLS=(
  "timem-coding-memory:dist/standalone/timem-coding-memory"
  "timem-general-memory:dist/standalone/timem-general-memory"
  "timem-writing-memory:skills/timem-writing-memory"
  "timem-rule-learning:skills/timem-rule-learning"
  "timem-knowledge:skills/timem-knowledge"
)

# Agent 矩阵: name|detect_cmd|config_dir|skills_dir|mcp_config|format|root_key|has_skills
AGENTS=(
  "claude-code|claude|$HOME/.claude|$HOME/.claude/skills|$HOME/.claude/settings.json|json|mcpServers|yes"
  "codex|codex|$HOME/.codex|$HOME/.codex/skills|$HOME/.codex/config.toml|toml|mcp_servers|yes"
  "cursor|cursor|$HOME/.cursor|$HOME/.cursor/skills|$HOME/.cursor/mcp.json|json|mcpServers|yes"
  "openclaw|openclaw|$HOME/.openclaw|$HOME/.openclaw/skills|$HOME/.openclaw/openclaw.json|json|mcp.servers|yes"
  "hermes|hermes|$HOME/.hermes|$HOME/.hermes/skills|$HOME/.hermes/config.yaml|yaml|mcp_servers|yes"
  "trae|trae|$HOME/.trae|$HOME/.trae/skills|$HOME/.trae/mcp.json|json|mcpServers|yes"
  "codebuddy|codebuddy|$HOME/.codebuddy|$HOME/.codebuddy/skills|$HOME/.codebuddy/.mcp.json|json|mcpServers|yes"
  "qoder|qoder|$HOME/.qoder|$HOME/.qoder/skills|$HOME/.qoder/mcp.json|json|mcpServers|yes"
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
USER_ID="${USER:-default}"
SKILLS_FILTER=""
LOCAL_MODE=false
SKIP_MCP=false
SKIP_SKILLS=false
FORCE=false
QUIET=false
DRY_RUN=false
AGENT_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)     API_KEY="$2"; shift 2 ;;
    --user-id)     USER_ID="$2"; shift 2 ;;
    --skills)      SKILLS_FILTER="$2"; shift 2 ;;
    --local)       LOCAL_MODE=true; shift ;;
    --skip-mcp)    SKIP_MCP=true; shift ;;
    --skip-skills) SKIP_SKILLS=true; shift ;;
    --force)       FORCE=true; shift ;;
    --quiet)       QUIET=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --agent)       AGENT_FILTER="$2"; shift 2 ;;
    --help|-h)     sed -n '2,30p' "$0" 2>/dev/null; exit 0 ;;
    *)             echo "未知参数: $1 (用 --help 查看帮助)" >&2; exit 1 ;;
  esac
done

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

TMPDIR_WORK="$(mktemp -d /tmp/aici-install-all.XXXXXX)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# ============================================================================
# Agent 检测
# ============================================================================

detect_agent() {
  local detect_cmd="$1" config_dir="$2"
  command -v "$detect_cmd" &>/dev/null && return 0
  [ -d "$config_dir" ] && return 0
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
  if [ "$LOCAL_MODE" = true ]; then
    printf '{"type":"stdio","command":"uvx","args":["--from","git+%s.git@main","timem-mcp"],"env":{"TIMEM_API_KEY":"%s","TIMEM_API_HOST":"%s","TIMEM_USER_ID":"%s","TIMEM_AGENT_ID":"%s"}}' \
      "$TIMEM_MCP_REPO" "$API_KEY" "$TIMEM_API_HOST_DEFAULT" "$USER_ID" "$agent_name"
  else
    printf '{"type":"http","url":"%s","headers":{"Authorization":"Bearer %s","X-TiMEM-User-Id":"%s","X-TiMEM-Agent-Id":"%s"}}' \
      "$TIMEM_CLOUD_URL" "$API_KEY" "$USER_ID" "$agent_name"
  fi
}

# ============================================================================
# MCP 合并 - JSON
# ============================================================================

merge_mcp_json() {
  local config_file="$1" agent_name="$2" root_key="$3"
  local server_name="TiMEM-MCP"
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
  local server_name="TiMEM-MCP"

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
TIMEM_USER_ID = "${USER_ID}"
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
  local server_name="TiMEM-MCP"

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

  if [ "$LOCAL_MODE" = true ]; then
    cat >> "$config_file" <<YAMLEOF

mcp_servers:
  ${server_name}:
    type: stdio
    command: uvx
    args:
      - "--from"
      - "git+${TIMEM_MCP_REPO}.git@main"
      - "timem-mcp"
    env:
      TIMEM_API_KEY: "${API_KEY}"
      TIMEM_API_HOST: "${TIMEM_API_HOST_DEFAULT}"
      TIMEM_USER_ID: "${USER_ID}"
      TIMEM_AGENT_ID: "${agent_name}"
YAMLEOF
  else
    cat >> "$config_file" <<YAMLEOF

mcp_servers:
  ${server_name}:
    type: http
    url: "${TIMEM_CLOUD_URL}"
    headers:
      Authorization: "Bearer ${API_KEY}"
      X-TiMEM-User-Id: "${USER_ID}"
      X-TiMEM-Agent-Id: "${agent_name}"
YAMLEOF
  fi
  success "MCP 配置已追加: $config_file"
  return 0
}

# ============================================================================
# 为单个 agent 安装 (skills + mcp)
# ============================================================================

install_for_agent() {
  local agent_line="$1"
  IFS='|' read -r name detect_cmd config_dir skills_dir mcp_config fmt root_key has_skills <<< "$agent_line"

  echo ""
  echo "━━━ $name ━━━"

  if ! agent_in_filter "$name"; then
    info "被 --agent 过滤跳过"
    record_result "$name" "SKIP" "filtered out"
    return 0
  fi

  if ! detect_agent "$detect_cmd" "$config_dir"; then
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

  if [ "$agent_failed" = true ]; then
    record_result "$name" "FAIL" "MCP merge failed"
  else
    record_result "$name" "OK" "skills+MCP"
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
# 主流程
# ============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  AICI CC Plugin - TiMEM 一键安装 (install-all.sh)            ║"
echo "║  为所有已检测的 AI Agent CLI 安装 TiMEM Skills + MCP 配置     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 显示配置
info "MCP 模式: $([ "$LOCAL_MODE" = true ] && echo '本地 stdio (uvx)' || echo 'Cloud HTTP (零安装)')"
info "API Key: $([ -n "$API_KEY" ] && echo '已设置' || echo '未设置 (用 --api-key 或 \$TIMEM_API_KEY)')"
info "User ID: $USER_ID"
info "Dry-run: $DRY_RUN"
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
  echo "  ℹ️  没有检测到任何已安装的 agent CLI"
  echo "  支持的 agent: claude-code, codex, cursor, openclaw, hermes, trae, codebuddy, qoder, claude-desktop"
  exit 0
fi

echo "  ✅ 所有检测到的 agent 均已安装完成"
echo ""
echo "  下一步:"
echo "    1. 配置环境变量 TIMEM_API_KEY (如尚未配置)"
echo "    2. 重启对应的 agent CLI"
echo ""

if [ "$LOCAL_MODE" = false ]; then
  echo "  提示: 当前使用 Cloud HTTP 模式 (零安装)"
  echo "  如需本地 stdio 模式: bash install-all.sh --local"
  echo ""
fi