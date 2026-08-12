#!/bin/bash
#
# TiMEM-SKILL — 上传 Release ZIP 到腾讯云 COS
#
# 功能:
#   - 上传 dist/release/timem-skill-{version}.zip 到 COS bucket
#   - 支持两种方式: coscli (CLI) 或 Python SDK (cos-python-sdk-v5)
#   - 上传后输出公开下载 URL
#   - 缺少配置时给出明确提示
#
# 用法:
#   bash scripts/upload-cos.sh [OPTIONS]
#
# 参数:
#   --file PATH      指定要上传的 ZIP 文件 (默认自动查找最新 release)
#   --version VER    指定版本号 (用于 COS 路径)
#   --key PATH       COS 对象 key 前缀 (默认 releases/)
#   --public         生成公开下载 URL (默认)
#   --help           显示帮助
#
# 环境变量:
#   COS_SECRET_ID    腾讯云 SecretId  (必需)
#   COS_SECRET_KEY   腾讯云 SecretKey (必需)
#   COS_BUCKET       COS Bucket 名    (必需, 如 timem-skill-1234567890)
#   COS_REGION       COS 区域          (默认 ap-guangzhou)
#   COS_KEY_PREFIX   COS key 前缀     (默认 releases/)
#

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── 默认值 ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_DIR="${PROJECT_ROOT}/dist/release"
ZIP_FILE=""
CUSTOM_VERSION=""
KEY_PREFIX="${COS_KEY_PREFIX:-releases/}"

# ── 参数解析 ──────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      ZIP_FILE="$2"; shift 2 ;;
    --version)
      CUSTOM_VERSION="$2"; shift 2 ;;
    --key)
      KEY_PREFIX="$2"; shift 2 ;;
    --public)
      shift ;;
    --help|-h)
      cat <<EOF
用法: bash scripts/upload-cos.sh [OPTIONS]

选项:
  --file PATH      指定要上传的 ZIP 文件 (默认自动查找最新 release)
  --version VER    指定版本号 (用于 COS 路径和 URL)
  --key PATH       COS key 前缀 (默认 releases/)
  --public         生成公开下载 URL (默认行为)
  --help           显示此帮助

环境变量:
  COS_SECRET_ID    腾讯云 SecretId  (必需)
  COS_SECRET_KEY   腾讯云 SecretKey (必需)
  COS_BUCKET       COS Bucket 名    (必需)
  COS_REGION       COS 区域          (默认 ap-guangzhou)
  COS_KEY_PREFIX   COS key 前缀     (默认 releases/)
EOF
      exit 0 ;;
    *)
      error "未知参数: $1"; exit 1 ;;
  esac
done

# ── 检查 COS 配置 ────────────────────────────────────
REGION="${COS_REGION:-ap-guangzhou}"

MISSING=()
if [[ -z "${COS_SECRET_ID:-}" ]]; then
  MISSING+=("COS_SECRET_ID")
fi
if [[ -z "${COS_SECRET_KEY:-}" ]]; then
  MISSING+=("COS_SECRET_KEY")
fi
if [[ -z "${COS_BUCKET:-}" ]]; then
  MISSING+=("COS_BUCKET")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  error "缺少必需的 COS 配置!"
  echo ""
  echo "请设置以下环境变量:"
  for m in "${MISSING[@]}"; do
    echo -e "  ${RED}✗${NC} $m"
  done
  echo -e "  ${YELLOW}○${NC} COS_REGION (可选, 默认 ap-guangzhou)"
  echo ""
  echo "设置方式 (临时):"
  echo "  export COS_SECRET_ID='your-secret-id'"
  echo "  export COS_SECRET_KEY='your-secret-key'"
  echo "  export COS_BUCKET='your-bucket-name'"
  echo "  export COS_REGION='ap-guangzhou'  # 可选"
  echo ""
  echo "设置方式 (永久, 写入 ~/.bashrc):"
  echo "  echo 'export COS_SECRET_ID=\"...\"' >> ~/.bashrc"
  echo "  # ... 其他变量同理"
  echo ""
  echo "获取 COS 密钥: https://console.cloud.tencent.com/cam/capi"
  exit 1
fi

ok "COS 配置检查通过 (Bucket: $COS_BUCKET, Region: $REGION)"

# ── 查找 ZIP 文件 ────────────────────────────────────
if [[ -z "$ZIP_FILE" ]]; then
  # 自动查找 dist/release/ 下最新的 ZIP
  if [[ ! -d "$RELEASE_DIR" ]]; then
    error "Release 目录不存在: $RELEASE_DIR"
    echo "请先运行: bash scripts/build-release.sh"
    exit 1
  fi

  ZIP_FILE=$(ls -t "$RELEASE_DIR"/timem-skill-*.zip 2>/dev/null | head -1 || true)

  if [[ -z "$ZIP_FILE" ]] || [[ ! -f "$ZIP_FILE" ]]; then
    error "未找到 ZIP 文件"
    echo "请先运行: bash scripts/build-release.sh"
    exit 1
  fi

  info "自动找到 ZIP: $ZIP_FILE"
fi

if [[ ! -f "$ZIP_FILE" ]]; then
  error "ZIP 文件不存在: $ZIP_FILE"
  exit 1
fi

# ── 推导版本号 ───────────────────────────────────────
if [[ -z "$CUSTOM_VERSION" ]]; then
  # 从文件名提取版本: timem-skill-{version}.zip
  BASENAME=$(basename "$ZIP_FILE")
  if [[ "$BASENAME" =~ ^timem-skill-(.+)\.zip$ ]]; then
    CUSTOM_VERSION="${BASH_REMATCH[1]}"
  else
    CUSTOM_VERSION="unknown"
    warn "无法从文件名提取版本号，使用: $CUSTOM_VERSION"
  fi
fi

# ── COS 对象 key ────────────────────────────────────
# 去掉 key_prefix 末尾的 /
KEY_PREFIX="${KEY_PREFIX%/}"
COS_KEY="${KEY_PREFIX}/timem-skill-${CUSTOM_VERSION}.zip"

info "上传目标: cos://${COS_BUCKET}/${COS_KEY}"

# ── 上传 ─────────────────────────────────────────────
UPLOAD_SUCCESS=false

# 方式 1: 尝试 coscli (腾讯云 COS CLI)
if command -v coscli &>/dev/null; then
  info "使用 coscli 上传..."

  # 配置 coscli (如果还没有配置)
  # coscli 需要配置文件，我们通过环境变量临时配置
  export COSCLI_SECRET_ID="$COS_SECRET_ID"
  export COSCLI_SECRET_KEY="$COS_SECRET_KEY"

  if coscli cp "$ZIP_FILE" "cos://${COS_BUCKET}/${COS_KEY}" -e "cos.${REGION}.myqcloud.com" 2>&1; then
    UPLOAD_SUCCESS=true
    ok "coscli 上传成功"
  else
    warn "coscli 上传失败，尝试 Python SDK..."
  fi
fi

# 方式 2: 使用 Python SDK (cos-python-sdk-v5)
if [[ "$UPLOAD_SUCCESS" == false ]]; then
  info "使用 Python SDK 上传..."

  # 检查 Python SDK 是否安装
  if ! python3 -c "import qcloud_cos" 2>/dev/null; then
    warn "cos-python-sdk-v5 未安装，尝试安装..."
    pip install cos-python-sdk-v5 2>/dev/null || pip3 install cos-python-sdk-v5 2>/dev/null || {
      error "无法安装 cos-python-sdk-v5"
      echo ""
      echo "请手动安装:"
      echo "  pip install cos-python-sdk-v5"
      echo ""
      echo "或安装 coscli:"
      echo "  https://cloud.tencent.com/document/product/436/63144"
      exit 1
    }
  fi

  # 用 Python SDK 上传
  python3 << PYEOF || {
    error "Python SDK 上传失败"
    exit 1
  }
import sys
import os
from qcloud_cos import CosConfig, CosS3Client

secret_id = os.environ['COS_SECRET_ID']
secret_key = os.environ['COS_SECRET_KEY']
region = os.environ.get('COS_REGION', 'ap-guangzhou')
bucket = os.environ['COS_BUCKET']
local_file = "$ZIP_FILE"
cos_key = "$COS_KEY"

config = CosConfig(
    Region=region,
    SecretId=secret_id,
    SecretKey=secret_key,
    Scheme='https',
)
client = CosS3Client(config)

# 上传文件
client.upload_file(
    Bucket=bucket,
    Key=cos_key,
    LocalFilePath=local_file,
    EnableMD5=True,
)

# 设置对象为公有读 (生成公开下载链接)
try:
    from qcloud_cos import CosConfig as CC
    client.put_object_acl(
        Bucket=bucket,
        Key=cos_key,
        ACL='public-read',
    )
    print("[OK] 已设置公有读权限")
except Exception as e:
    print(f"[WARN] 设置公有读失败 (可能 bucket 默认权限已公开): {e}")

print("[OK] Python SDK 上传成功")
PYEOF

  UPLOAD_SUCCESS=true
fi

# ── 输出下载 URL ─────────────────────────────────────
if [[ "$UPLOAD_SUCCESS" == true ]]; then
  # 公开下载 URL 格式: https://{bucket}.cos.{region}.myqcloud.com/{key}
  DOWNLOAD_URL="https://${COS_BUCKET}.cos.${REGION}.myqcloud.com/${COS_KEY}"

  ok "上传成功!"
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  COS 上传完成${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  版本:     ${BLUE}${CUSTOM_VERSION}${NC}"
  echo -e "  Bucket:   ${BLUE}${COS_BUCKET}${NC}"
  echo -e "  Region:   ${BLUE}${REGION}${NC}"
  echo -e "  COS Key:  ${BLUE}${COS_KEY}${NC}"
  echo -e "  下载 URL: ${BLUE}${DOWNLOAD_URL}${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  info "用户安装方式:"
  echo "  curl -fsSL '${DOWNLOAD_URL}' -o timem-skill.zip"
  echo "  unzip timem-skill.zip"
  echo "  cd timem-skill && bash install-all.sh"
  echo ""
  # 输出 URL 供脚本调用
  echo "DOWNLOAD_URL=${DOWNLOAD_URL}"
else
  error "上传失败"
  exit 1
fi