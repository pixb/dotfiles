#!/usr/bin/env bash
# install_river.sh - 安装 river + kwm (与参考项目一致)
# 参考: https://codeberg.org/unixchad/kwm

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m'

TIME="$(date +%Y-%m-%d_%H-%M-%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
FILE_NAME="${SCRIPT_NAME%.*}"

ZIG_VERSION_RIVER="0.16.0"
ZIG_PATH_RIVER="/opt/zig-x86_64-linux-${ZIG_VERSION_RIVER}"

log_info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"; }
log_ok() { echo -e "${COLOR_GREEN}[OK]${COLOR_NC} $1"; }
log_err() { echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"; }

SRC_DIR="$HOME/.local/src"

# ========== 步骤 1: 安装编译依赖 ==========
step1_deps() {
  log_info "=== 步骤 1: 安装编译依赖 ==="

  if [ -d "$ZIG_PATH_RIVER" ] && [ -x "$ZIG_PATH_RIVER/zig" ]; then
    log_ok "Zig (river) 目录已存在: $ZIG_PATH_RIVER"
  else
    log_info "下载 zig $ZIG_VERSION_RIVER (river)..."
    local zig_url="https://ziglang.org/download/${ZIG_VERSION_RIVER}/zig-x86_64-linux-${ZIG_VERSION_RIVER}.tar.xz"
    local zig_file="/tmp/zig-river.tar.xz"
    wget -q -O "$zig_file" "$zig_url" || curl -sL "$zig_url" -o "$zig_file"
    sudo rm -rf "$ZIG_PATH_RIVER"
    sudo tar -xf "$zig_file" -C /opt
    rm -f "$zig_file"
    log_ok "Zig $ZIG_VERSION_RIVER 安装完成"
  fi

  if ! command -v zig &>/dev/null; then
    log_info "安装 zig (kwm)..."
    sudo pacman -S --noconfirm zig
  fi
  log_ok "Zig $(zig version) (kwm)"

  sudo pacman -S --needed wlroots0.20 scdoc tllist wayland-protocols sysstat gammastep --noconfirm
  sudo pacman -S --needed kanshi swayidle stow --noconfirm

  # fcft 是 AUR 包，需要 yay 或 paru
  if ! pacman -Qi fcft >/dev/null 2>&1; then
    if command -v yay &>/dev/null; then
      yay -S --needed fcft --noconfirm
    elif command -v paru &>/dev/null; then
      paru -S --needed fcft --noconfirm
    else
      log_err "未找到 AUR helper (yay/paru)，请手动安装 fcft"
      exit 1
    fi
  fi
  log_ok "依赖安装完成"
}

# ========== 步骤 2: 编译安装 river (官方) ==========
step2_install_river() {
  log_info "=== 步骤 2: 编译安装 river ==="
  local src_dir="$SRC_DIR/river"
  if [ -f "/usr/local/bin/river" ]; then
    log_ok "river 已安装"
  else
    [ ! -d "$src_dir" ] && git clone https://codeberg.org/river/river "$src_dir"
    cd "$src_dir"
    export PATH="$ZIG_PATH_RIVER:$PATH"
    sudo env "PATH=$PATH" SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt "$ZIG_PATH_RIVER/zig" build -Doptimize=ReleaseSafe --prefix /usr/local install
    log_ok "river 安装完成"
  fi
}

# ========== 步骤 3: 编译安装 kwm ==========
step3_install_kwm() {
  log_info "=== 步骤 3: 编译安装 kwm ==="
  local src_dir="$SRC_DIR/kwm"
  if [ -f "/usr/local/bin/kwm" ]; then
    log_ok "kwm 已安装"
  else
    [ ! -d "$src_dir" ] && git clone https://codeberg.org/unixchad/kwm "$src_dir"
    cd "$src_dir"
    git checkout master

    # 克隆 GitHub 依赖到本地，避免网络问题
    if [ ! -d "mvzr" ]; then
      log_info "克隆 mvzr..."
      git clone https://github.com/mnemnion/mvzr mvzr
    fi
    if [ ! -d "fcft" ]; then
      log_info "克隆 zig-fcft..."
      git clone https://github.com/kewuaa/zig-fcft fcft
    fi

    # 修改 build.zig.zon，将 GitHub URL 改为本地 path
    sed -i 's|\.url = "https://github.com/mnemnion/mvzr/archive/refs/tags/v0.3.10.tar.gz",|\.path = "mvzr",|' build.zig.zon
    sed -i 's|\.hash = "mvzr-0.3.9-ZSOky8FzAQBQ9-GkQnaLjOZZHxrioD8NwY-QyZT6oAyR",||' build.zig.zon
    sed -i 's|\.url = "https://github.com/kewuaa/zig-fcft/archive/refs/tags/v2.0.0.tar.gz",|\.path = "fcft",|' build.zig.zon
    sed -i 's|\.hash = "fcft-2.0.0-zcx6C5EaAADIEaQzDg5D4UvFFMjSEwDE38vdE9xObeN9",||' build.zig.zon

    sudo rm -rf .zig-cache zig-cache zig-out
    sudo env "PATH=/usr/local/bin:/usr/bin:$PATH" SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt zig build -Doptimize=ReleaseSafe --prefix /usr/local install
    log_ok "kwm 安装完成"
  fi
}

# ========= Step 4: stow config ===========
step4_stow_config() {
  log_info "=== Step 4: stow config ==="
  if [ -e "${HOME}/dotfiles" ]; then
    cd "${HOME}/dotfiles" || exit
    stow -t ~ kwm
    stow -t ~ river
  fi
}

main() {
  echo "=== River + kwm 安装 (与参考项目一致) ==="
  echo ""

  step1_deps
  step2_install_river
  step3_install_kwm
  step4_stow_config

  echo ""
  echo "=== 安装完成 ==="
  echo "启动: river"
  echo "配置目录: ~/.config/river/"
}

main "$@"
