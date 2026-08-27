#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/timem-shell-install-test.XXXXXX")"
INSTRUCTION="每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

run_installer() {
  local profile_dir="$1" agent_name="$2"
  shift 2
  HOME="$profile_dir" CODEX_HOME= TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent "$agent_name" --api-key 'test-key-12345678' --skip-skills --quiet "$@" > /dev/null
}

run_codex_installer_with_home() {
  local profile_dir="$1" codex_home="$2"
  HOME="$profile_dir" CODEX_HOME="$codex_home" TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent codex --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

run_qoder_installer_with_config_dir() {
  local profile_dir="$1" config_dir="$2"
  HOME="$profile_dir" CODEX_HOME= QODER_CONFIG_DIR="$config_dir" TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent qoder --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

run_trae_installer_with_appdata() {
  local profile_dir="$1" appdata_dir="$2"
  HOME="$profile_dir" CODEX_HOME= APPDATA="$appdata_dir" TRAE_MCP_CONFIG= TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent trae --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

run_trae_installer_with_platform() {
  local profile_dir="$1" platform="$2"
  local shim_dir="$TEST_ROOT/uname-$platform"

  mkdir -p "$shim_dir"
  printf '%s\n' '#!/usr/bin/env bash' \
    'if [ "${1:-}" = "-s" ]; then' \
    "  printf '%s\\n' '$platform'" \
    'else' \
    '  /usr/bin/uname "$@"' \
    'fi' > "$shim_dir/uname"
  chmod +x "$shim_dir/uname"

  HOME="$profile_dir" CODEX_HOME= APPDATA= TRAE_MCP_CONFIG= PATH="$shim_dir:$PATH" TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent trae --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

run_openclaw_installer_with_workspace() {
  local profile_dir="$1" workspace_dir="$2"
  HOME="$profile_dir" CODEX_HOME= OPENCLAW_WORKSPACE_DIR="$workspace_dir" TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent openclaw --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

run_hermes_installer_with_home() {
  local profile_dir="$1" hermes_home="$2"
  HOME="$profile_dir" CODEX_HOME= HERMES_HOME="$hermes_home" TIMEM_API_KEY='test-key-12345678' \
    bash "$REPO_ROOT/install-all.sh" --agent hermes --api-key 'test-key-12345678' --skip-skills --quiet > /dev/null
}

test_codex_instruction_injection() {
  local profile_dir="$TEST_ROOT/codex-profile"
  local instruction_file="$profile_dir/.codex/AGENTS.md"

  mkdir -p "$profile_dir/.codex"
  printf '# existing codex config\n' > "$profile_dir/.codex/config.toml"
  printf '# Existing global instructions\n' > "$instruction_file"
  printf '# Existing global instructions\n%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_installer "$profile_dir" codex
  run_installer "$profile_dir" codex

  test -f "$instruction_file"
  cmp -s "$instruction_file.expected" "$instruction_file"
}

test_codex_home_override() {
  local profile_dir="$TEST_ROOT/codex-home-profile"
  local config_dir="$TEST_ROOT/custom-codex"
  local instruction_file="$config_dir/AGENTS.md"

  mkdir -p "$config_dir"
  printf '# existing codex config\n' > "$config_dir/config.toml"
  printf '%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_codex_installer_with_home "$profile_dir" "$config_dir"

  test -f "$instruction_file"
  cmp -s "$instruction_file.expected" "$instruction_file"
  grep -q 'TiMEM-SPACE' "$config_dir/config.toml"
  test ! -e "$profile_dir/.codex/AGENTS.md"
}

test_codex_reuses_existing_agent_md_variant() {
  local profile_dir="$TEST_ROOT/codex-agent-md-profile"
  local config_dir="$profile_dir/.codex"
  local instruction_file="$config_dir/agent.MD"

  mkdir -p "$config_dir"
  printf '# existing codex config\n' > "$config_dir/config.toml"
  printf '# Existing Agent instructions\n' > "$instruction_file"
  printf '# Existing Agent instructions\n%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_installer "$profile_dir" codex
  run_installer "$profile_dir" codex

  cmp -s "$instruction_file.expected" "$instruction_file"
  test ! -e "$config_dir/AGENTS.md"
}

test_cursor_user_rule_injection() {
  local profile_dir="$TEST_ROOT/cursor-profile"
  local config_dir="$profile_dir/.cursor"
  local rule_file="$config_dir/rules/timem-memory.mdc"
  local expected_file="$TEST_ROOT/cursor-user-rule.expected"

  mkdir -p "$config_dir"
  printf '{"mcpServers":{}}\n' > "$config_dir/mcp.json"
  printf '%s\n' '---' 'description: "TiMEM memory workflow"' 'alwaysApply: true' '---' '' "$INSTRUCTION" > "$expected_file"

  run_installer "$profile_dir" cursor
  run_installer "$profile_dir" cursor

  test -f "$rule_file"
  cmp -s "$expected_file" "$rule_file"
  test ! -e "$config_dir/AGENTS.md"
}

test_claude_marker_preserves_file() {
  local profile_dir="$TEST_ROOT/claude-profile"
  local instruction_file="$profile_dir/.claude/CLAUDE.md"

  mkdir -p "$profile_dir/.claude"
  printf '# Team guidance\n本项目已接入太忆空间。\n' > "$instruction_file"
  cp "$instruction_file" "$instruction_file.expected"

  run_installer "$profile_dir" claude-code

  cmp -s "$instruction_file.expected" "$instruction_file"
}

test_claude_code_uses_user_mcp_config() {
  local profile_dir="$TEST_ROOT/claude-user-mcp-profile"
  local config_dir="$profile_dir/.claude"
  local config_file="$profile_dir/.claude.json"
  local legacy_settings_file="$config_dir/settings.json"

  mkdir -p "$config_dir"
  printf '%s\n' '{"projects":{"Workspace":{"enabled":true},"workspace":{"enabled":false}},"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}' > "$config_file"

  run_installer "$profile_dir" claude-code
  run_installer "$profile_dir" claude-code

  grep -q '"TiMEM-SPACE"' "$config_file"
  test "$(grep -c '"Workspace"' "$config_file")" -eq 1
  test "$(grep -c '"workspace"' "$config_file")" -eq 1
  test ! -e "$legacy_settings_file"
}

test_trae_uses_current_user_mcp_config() {
  local profile_dir="$TEST_ROOT/trae-profile"
  local appdata_dir="$TEST_ROOT/trae-appdata"
  local config_file="$appdata_dir/Trae/User/mcp.json"
  local legacy_config_file="$profile_dir/.trae/mcp.json"

  mkdir -p "$(dirname "$config_file")"
  printf '%s\n' '{"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}' > "$config_file"

  run_trae_installer_with_appdata "$profile_dir" "$appdata_dir"
  run_trae_installer_with_appdata "$profile_dir" "$appdata_dir"

  grep -q '"existing"' "$config_file"
  test "$(grep -c '"TiMEM-SPACE"' "$config_file")" -eq 1
  test ! -e "$legacy_config_file"
}

test_trae_legacy_state_detects_current_mcp_target() {
  local profile_dir="$TEST_ROOT/trae-legacy-profile"
  local appdata_dir="$TEST_ROOT/trae-legacy-appdata"
  local config_file="$appdata_dir/Trae/User/mcp.json"

  mkdir -p "$profile_dir/.trae" "$appdata_dir"

  run_trae_installer_with_appdata "$profile_dir" "$appdata_dir"

  test -f "$config_file"
  grep -q '"TiMEM-SPACE"' "$config_file"
}

test_trae_linux_platform_path() {
  local profile_dir="$TEST_ROOT/trae-linux-profile"
  local config_file="$profile_dir/.config/Trae/User/mcp.json"

  mkdir -p "$(dirname "$config_file")"

  run_trae_installer_with_platform "$profile_dir" Linux
  run_trae_installer_with_platform "$profile_dir" Linux

  test -f "$config_file"
  test "$(grep -c '"TiMEM-SPACE"' "$config_file")" -eq 1
}

test_trae_macos_platform_path() {
  local profile_dir="$TEST_ROOT/trae-macos-profile"
  local config_file="$profile_dir/Library/Application Support/Trae/User/mcp.json"

  mkdir -p "$(dirname "$config_file")"

  run_trae_installer_with_platform "$profile_dir" Darwin
  run_trae_installer_with_platform "$profile_dir" Darwin

  test -f "$config_file"
  test "$(grep -c '"TiMEM-SPACE"' "$config_file")" -eq 1
}

test_trae_global_user_rule_injection() {
  local profile_dir="$TEST_ROOT/trae-rule-profile"
  local appdata_dir="$TEST_ROOT/trae-rule-appdata"
  local config_file="$appdata_dir/Trae/User/mcp.json"
  local rule_file="$profile_dir/.trae/user_rules/timem-memory.md"
  local expected_file="$TEST_ROOT/trae-user-rule.expected"

  mkdir -p "$(dirname "$config_file")"
  printf '%s\n' '{"mcpServers":{}}' > "$config_file"
  printf '%s\n' '---' 'alwaysApply: true' '---' '' "$INSTRUCTION" > "$expected_file"

  run_trae_installer_with_appdata "$profile_dir" "$appdata_dir"
  run_trae_installer_with_appdata "$profile_dir" "$appdata_dir"

  test -f "$rule_file"
  cmp -s "$expected_file" "$rule_file"
  test ! -e "$profile_dir/.trae/rules/timem-memory.md"
}

test_qoder_instruction_injection() {
  local profile_dir="$TEST_ROOT/qoder-profile"
  local instruction_file="$profile_dir/.qoder/AGENTS.md"

  mkdir -p "$profile_dir/.qoder"
  printf '{"mcpServers":{}}\n' > "$profile_dir/.qoder/settings.json"
  printf '%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_installer "$profile_dir" qoder
  run_installer "$profile_dir" qoder

  test -f "$instruction_file"
  cmp -s "$instruction_file.expected" "$instruction_file"
}

test_qoder_config_dir_override() {
  local profile_dir="$TEST_ROOT/qoder-override-profile"
  local config_dir="$TEST_ROOT/custom-qoder"
  local instruction_file="$config_dir/AGENTS.md"

  mkdir -p "$config_dir"
  printf '{"mcpServers":{}}\n' > "$config_dir/settings.json"
  printf '%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_qoder_installer_with_config_dir "$profile_dir" "$config_dir"

  test -f "$instruction_file"
  cmp -s "$instruction_file.expected" "$instruction_file"
  test ! -e "$profile_dir/.qoder/AGENTS.md"
}

test_openclaw_workspace_instruction_injection() {
  local profile_dir="$TEST_ROOT/openclaw-profile"
  local config_dir="$profile_dir/.openclaw"
  local default_workspace="$TEST_ROOT/openclaw-default-workspace"
  local work_workspace="$profile_dir/.openclaw-work"
  local ops_workspace="$config_dir/workspace-ops"
  local research_workspace="$profile_dir/.openclaw-research"
  local configured_default_workspace="$profile_dir/.configured-openclaw"
  local expected_file="$TEST_ROOT/openclaw.expected"

  mkdir -p "$config_dir"
  printf '%s\n' '{"agents":{"defaults":{"workspace":"~/.configured-openclaw"},"list":[{"id":"work","workspace":"~/.openclaw-work"},{"id":"ops"}],"entries":{"research":{"workspace":"~/.openclaw-research"}}},"mcp":{"servers":{}}}' > "$config_dir/openclaw.json"
  printf '%s\n' "$INSTRUCTION" > "$expected_file"

  run_openclaw_installer_with_workspace "$profile_dir" "$default_workspace"
  run_openclaw_installer_with_workspace "$profile_dir" "$default_workspace"

  for instruction_file in "$default_workspace/AGENTS.md" "$work_workspace/AGENTS.md" "$ops_workspace/AGENTS.md" "$research_workspace/AGENTS.md"; do
    test -f "$instruction_file"
    cmp -s "$expected_file" "$instruction_file"
  done
  test ! -e "$configured_default_workspace/AGENTS.md"
  test ! -e "$config_dir/AGENTS.md"
}

test_hermes_soul_instruction_injection() {
  local profile_dir="$TEST_ROOT/hermes-profile"
  local hermes_home="$TEST_ROOT/custom-hermes"
  local instruction_file="$hermes_home/SOUL.md"

  mkdir -p "$hermes_home"
  printf 'model: test\n' > "$hermes_home/config.yaml"
  printf '# Existing Hermes soul\n' > "$instruction_file"
  printf '# Existing Hermes soul\n%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_hermes_installer_with_home "$profile_dir" "$hermes_home"
  run_hermes_installer_with_home "$profile_dir" "$hermes_home"

  cmp -s "$instruction_file.expected" "$instruction_file"
  test ! -e "$profile_dir/.hermes/SOUL.md"
}

test_hermes_missing_soul_is_preserved() {
  local profile_dir="$TEST_ROOT/hermes-missing-profile"
  local hermes_home="$TEST_ROOT/custom-hermes-missing"
  local instruction_file="$hermes_home/SOUL.md"

  mkdir -p "$hermes_home"
  printf 'model: test\n' > "$hermes_home/config.yaml"

  run_hermes_installer_with_home "$profile_dir" "$hermes_home"

  test ! -e "$instruction_file"
}

test_workbuddy_soul_instruction_injection() {
  local profile_dir="$TEST_ROOT/workbuddy-profile"
  local config_dir="$profile_dir/.workbuddy"
  local instruction_file="$config_dir/SOUL.md"

  mkdir -p "$config_dir"
  printf '# Existing WorkBuddy soul\n' > "$instruction_file"
  printf '# Existing WorkBuddy soul\n%s\n' "$INSTRUCTION" > "$instruction_file.expected"

  run_installer "$profile_dir" workbuddy
  run_installer "$profile_dir" workbuddy

  cmp -s "$instruction_file.expected" "$instruction_file"
}

test_workbuddy_missing_soul_is_preserved() {
  local profile_dir="$TEST_ROOT/workbuddy-missing-profile"
  local config_dir="$profile_dir/.workbuddy"
  local instruction_file="$config_dir/SOUL.md"

  mkdir -p "$config_dir"

  run_installer "$profile_dir" workbuddy

  test ! -e "$instruction_file"
}

test_skip_agent_instructions() {
  local profile_dir="$TEST_ROOT/skip-profile"
  local instruction_file="$profile_dir/.codex/AGENTS.md"

  mkdir -p "$profile_dir/.codex"
  printf '# existing codex config\n' > "$profile_dir/.codex/config.toml"

  run_installer "$profile_dir" codex --skip-agent-instructions

  test ! -e "$instruction_file"
}

test_codex_instruction_injection
test_codex_home_override
test_codex_reuses_existing_agent_md_variant
test_cursor_user_rule_injection
test_claude_marker_preserves_file
test_claude_code_uses_user_mcp_config
test_trae_uses_current_user_mcp_config
test_trae_legacy_state_detects_current_mcp_target
test_trae_linux_platform_path
test_trae_macos_platform_path
test_trae_global_user_rule_injection
test_qoder_instruction_injection
test_qoder_config_dir_override
test_openclaw_workspace_instruction_injection
test_hermes_soul_instruction_injection
test_hermes_missing_soul_is_preserved
test_workbuddy_soul_instruction_injection
test_workbuddy_missing_soul_is_preserved
test_skip_agent_instructions
