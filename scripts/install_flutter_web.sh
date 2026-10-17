#!/usr/bin/env bash
# install_flutter_web.sh - 安装 Flutter SDK (官方 git stable) 用于 flutter web 构建
# 无头 Linux 纯终端版本: 不安装浏览器 / 桌面 / UI 组件

set -euo pipefail

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# === File Variable ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1

FLUTTER_DIR="${HOME}/.local/share/flutter"
FLUTTER_BIN="${FLUTTER_DIR}/bin"
ZSHRC="${HOME}/.zshrc"

log_info() { echo -e "${COLOR_YELLOW}[INFO]${COLOR_NC} $1"; }
log_ok() { echo -e "${COLOR_GREEN}[OK]${COLOR_NC} $1"; }
log_err() { echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1" >&2; }

pacman_install() {
  local pkg
  for pkg in "$@"; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
      log_ok "$pkg is already installed"
    else
      log_info "$pkg is not installed, installing..."
      sudo pacman -S "$pkg" --noconfirm --needed
    fi
  done
}

# ========== 步骤 1: 基础依赖 ==========
step1_deps() {
  log_info "=== 步骤 1: 基础依赖 (纯终端, 无 UI) ==="
  pacman_install git curl unzip xz
  # clang: flutter 构建依赖; rust: 可选, 仅 --wasm 构建需要
  pacman_install clang
  if command -v rustc &>/dev/null; then
    log_ok "rustc $(rustc --version | awk '{print $2}') 已安装 (--wasm 可选)"
  else
    log_info "rustc 未安装: 仅影响 'flutter build web --wasm', 跳过"
  fi
}

# ========== 步骤 2: 安装 Flutter SDK (官方 git stable) ==========
step2_install_flutter() {
  log_info "=== 步骤 2: 安装 Flutter SDK (git stable) ==="
  if [ -x "${FLUTTER_BIN}/flutter" ]; then
    log_ok "Flutter 已存在: ${FLUTTER_DIR}"
  else
    mkdir -p "$(dirname "${FLUTTER_DIR}")"
    git clone https://github.com/flutter/flutter.git -b stable "${FLUTTER_DIR}"
    log_ok "Flutter clone 完成"
  fi

  # PATH 写入 ~/.zshrc (幂等)
  if ! grep -q 'flutter/bin' "$ZSHRC" 2>/dev/null; then
    log_info "写入 PATH 到 $ZSHRC"
    printf '\n# flutter (install_flutter_web.sh)\nexport PATH="$PATH:%s"\n' "$FLUTTER_BIN" >>"$ZSHRC"
  else
    log_ok "PATH 已配置在 $ZSHRC"
  fi
  export PATH="$PATH:${FLUTTER_BIN}"
}

# ========== 步骤 3: 首次运行 + web 支持 ==========
step3_setup_web() {
  log_info "=== 步骤 3: 首次运行 + web 平台 ==="
  # 首次执行 flutter 会自举下载 Dart SDK
  flutter --version
  flutter config --no-analytics --enable-web
  # 只下载 web 平台产物, 不下载 android/ios/linux 等
  flutter precache --web
  flutter doctor -v
}

main() {
  echo "=== Flutter Web 安装 (无头纯终端) ==="
  echo ""

  step1_deps
  step2_install_flutter
  step3_setup_web

  echo ""
  echo "=== 安装完成 ==="
  echo "SDK 目录: ${FLUTTER_DIR}"
  echo "PATH 已写入 ~/.zshrc, 重新打开终端或: source ~/.zshrc"
  echo ""
  echo "构建: cd <project> && flutter build web --release"
  echo "产物: build/web/ (静态文件, 可用任意静态服务器部署)"
  echo "预览(可选): python3 -m http.server -d build/web 8080"
}

main "$@"
