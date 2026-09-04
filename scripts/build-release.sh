#!/bin/bash
#
# TiMEM-SKILL — 构建 release ZIP 包
#
# 功能:
#   - 从 git tag 或 commit hash 读取版本号
#   - 将 skills/ + install-all.sh + install-all.ps1 + README.md 打包为 ZIP
#   - 输出到 dist/release/timem-skill-{version}.zip
#   - 幂等: 重复运行会覆盖同名 ZIP
#
# 用法:
#   bash scripts/build-release.sh [OPTIONS]
#
# 参数:
#   --version VER   手动指定版本号 (覆盖 git tag)
#   --output DIR    输出目录 (默认 dist/release/)
#   --clean         打包前先清理输出目录
#   --help          显示帮助
#

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── 默认值 ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/dist/release"
CUSTOM_VERSION=""
CLEAN=false

# ── 参数解析 ──────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      CUSTOM_VERSION="$2"; shift 2 ;;
    --output)
      OUTPUT_DIR="$2"; shift 2 ;;
    --clean)
      CLEAN=true; shift ;;
    --help|-h)
      cat <<EOF
用法: bash scripts/build-release.sh [OPTIONS]

选项:
  --version VER   手动指定版本号 (覆盖 git tag)
  --output DIR    输出目录 (默认 dist/release/)
  --clean         打包前先清理输出目录
  --help          显示此帮助
EOF
      exit 0 ;;
    *)
      error "未知参数: $1"; exit 1 ;;
  esac
done

# ── 版本号 ────────────────────────────────────────────
VERSION=""

if [[ -n "$CUSTOM_VERSION" ]]; then
  VERSION="$CUSTOM_VERSION"
  info "使用手动指定版本: $VERSION"
elif [[ -d "${PROJECT_ROOT}/.git" ]]; then
  # 尝试从最近的 git tag 读取 (只取 tag 名，去掉 refs/tags/ 前缀)
  TAG=$(cd "$PROJECT_ROOT" && git describe --tags --abbrev=0 2>/dev/null || true)
  if [[ -n "$TAG" ]]; then
    VERSION="${TAG#v}"  # 去掉前缀 v
    info "从 git tag 读取版本: $VERSION (tag: $TAG)"
  else
    # 没有 tag，用 commit short hash
    COMMIT=$(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || true)
    if [[ -n "$COMMIT" ]]; then
      VERSION="$COMMIT"
      info "无 git tag，使用 commit hash: $VERSION"
    fi
  fi
fi

if [[ -z "$VERSION" ]]; then
  VERSION="0.0.0-dev"
  warn "无法确定版本号，使用默认: $VERSION"
fi

# ── 检查必要文件 ──────────────────────────────────────
REQUIRED_FILES=(
  "install-all.sh"
  "install-all.ps1"
  "README.md"
)

REQUIRED_SKILLS=(
  "skills/timem-memory-skill"
  "skills/timem-rule-learning"
  "skills/timem-knowledge"
)

info "项目根目录: $PROJECT_ROOT"

# Always regenerate derived full/standalone packages so the release archive is
# a snapshot of this checkout rather than whatever happened to be in dist/.
if command -v python3 &>/dev/null; then
  PYTHON_BIN="python3"
elif command -v python &>/dev/null; then
  PYTHON_BIN="python"
else
  error "需要 python3 或 python 来生成发行包"
  exit 1
fi
"$PYTHON_BIN" "${PROJECT_ROOT}/scripts/build-all.py"

for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "${PROJECT_ROOT}/${f}" ]]; then
    error "缺少必要文件: $f"
    exit 1
  fi
done

for s in "${REQUIRED_SKILLS[@]}"; do
  if [[ ! -d "${PROJECT_ROOT}/${s}" ]]; then
    error "缺少必要 skill 目录: $s"
    exit 1
  fi
done

REQUIRED_INSTALL_SOURCES=(
  "dist/full/timem-memory-skill"
  "dist/standalone/timem-coding-memory"
  "dist/standalone/timem-general-memory"
  "skills/timem-writing-memory"
)

for s in "${REQUIRED_INSTALL_SOURCES[@]}"; do
  if [[ ! -f "${PROJECT_ROOT}/${s}/SKILL.md" ]]; then
    error "缺少安装器所需发行目录: $s"
    exit 1
  fi
done

ok "所有必要文件和目录检查通过"

# ── 准备输出目录 ──────────────────────────────────────
if [[ "$CLEAN" == true ]]; then
  info "清理输出目录: $OUTPUT_DIR"
  rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

# ── 临时打包目录 ─────────────────────────────────────
TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

STAGING="$TMP_DIR/timem-skill"
mkdir -p "$STAGING"

info "准备打包内容到临时目录..."

# 复制 5 个 skill 目录
for s in "${REQUIRED_SKILLS[@]}"; do
  skill_name=$(basename "$s")
  cp -r "${PROJECT_ROOT}/${s}" "${STAGING}/${skill_name}"
  ok "添加 skill: $skill_name"
done

# 复制 shared 目录 (mcp-tools.md 等)
if [[ -d "${PROJECT_ROOT}/skills/shared" ]]; then
  cp -r "${PROJECT_ROOT}/skills/shared" "${STAGING}/shared"
  ok "添加 shared/"
fi

# Preserve the repository-relative paths used by both one-click installers.
# These copies are recursive, so future files added under the skill packages
# are included without maintaining another allowlist.
mkdir -p "${STAGING}/dist/full" "${STAGING}/dist/standalone" "${STAGING}/skills"
cp -r "${PROJECT_ROOT}/dist/full/timem-memory-skill" "${STAGING}/dist/full/"
cp -r "${PROJECT_ROOT}/dist/standalone/timem-coding-memory" "${STAGING}/dist/standalone/"
cp -r "${PROJECT_ROOT}/dist/standalone/timem-general-memory" "${STAGING}/dist/standalone/"
cp -r "${PROJECT_ROOT}/skills/timem-writing-memory" "${STAGING}/skills/"
ok "添加一键安装器所需的完整发行目录"

# 复制安装脚本和文档
for f in "${REQUIRED_FILES[@]}"; do
  cp "${PROJECT_ROOT}/${f}" "${STAGING}/$(basename "$f")"
  ok "添加 $(basename "$f")"
done

# 复制 README_zh.md (如果存在)
if [[ -f "${PROJECT_ROOT}/README_zh.md" ]]; then
  cp "${PROJECT_ROOT}/README_zh.md" "${STAGING}/README_zh.md"
  ok "添加 README_zh.md"
fi

# 复制 LICENSE (如果存在)
if [[ -f "${PROJECT_ROOT}/LICENSE" ]]; then
  cp "${PROJECT_ROOT}/LICENSE" "${STAGING}/LICENSE"
  ok "添加 LICENSE"
fi

# 生成 VERSION 文件
echo "$VERSION" > "${STAGING}/VERSION"
ok "添加 VERSION ($VERSION)"

# ── 打包 ZIP ─────────────────────────────────────────
ZIP_NAME="timem-skill-${VERSION}.zip"
ZIP_PATH="${OUTPUT_DIR}/${ZIP_NAME}"

info "打包 ZIP: $ZIP_PATH"

# 先删除已存在的同名 ZIP (幂等)
rm -f "$ZIP_PATH"

# 固定条目顺序、时间戳和权限；同一源码重复构建必须得到相同 SHA-256，
# 才能安全复用不可变的 COS 版本对象。
"$PYTHON_BIN" "${PROJECT_ROOT}/scripts/deterministic_zip.py" \
  --source "$STAGING" \
  --destination "$ZIP_PATH" \
  --archive-root timem-skill

# ── 验证 ─────────────────────────────────────────────
if [[ ! -f "$ZIP_PATH" ]]; then
  error "ZIP 文件创建失败"
  exit 1
fi

ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)

# 统计条目数：直接用 python3 标准库读 zip 中央目录，
# 跨平台一致，不依赖 zip -l / unzip -l 的输出格式，
# 也避免 head -n 负数参数（busybox 不支持）和 grep -q 提前退出引发的 SIGPIPE。
ZIP_CONTENTS=$(python3 -c "import zipfile; print(len(zipfile.ZipFile('$ZIP_PATH').namelist()))")

ok "打包成功!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  TiMEM-SKILL Release${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  版本:  ${BLUE}${VERSION}${NC}"
echo -e "  文件:  ${BLUE}${ZIP_PATH}${NC}"
echo -e "  大小:  ${BLUE}${ZIP_SIZE}${NC}"
echo -e "  条目:  ${BLUE}${ZIP_CONTENTS} 个文件${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
info "用户使用方式: 下载 ZIP → 解压 → bash install-all.sh"
