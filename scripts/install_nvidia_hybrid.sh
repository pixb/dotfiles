#!/usr/bin/env bash
# install_nvidia_hybrid.sh - 安装 nvidia 闭源驱动 (Intel + NVIDIA 混合显卡)
# 适用于: HDMI 走 NVIDIA GPU，eDP 走 Intel GPU 的笔记本
# 作用: 开启 nvidia-drm modeset，让 wlroots 合成器能跨 GPU 共享缓冲区

set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

log_info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"; }
log_ok() { echo -e "${COLOR_GREEN}[OK]${COLOR_NC} $1"; }
log_warn() { echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $1"; }
log_err() { echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"; }

# ========== 步骤 1: 检查 GPU 环境 ==========
step1_check_gpu() {
  log_info "=== 步骤 1: 检查 GPU 环境 ==="

  if ! lspci | grep -qi "nvidia"; then
    log_err "未检测到 NVIDIA GPU，退出"
    exit 1
  fi
  log_ok "检测到 NVIDIA GPU"

  if ! lspci | grep -qi "intel"; then
    log_warn "未检测到 Intel GPU，可能不是混合显卡配置"
  fi

  # 检查当前是否已加载 nouveau
  if lsmod | grep -q nouveau; then
    log_info "当前使用 nouveau 驱动，将切换到 nvidia 闭源驱动"
  fi
}

# ========== 步骤 2: 安装 nvidia 驱动 ==========
step2_install_nvidia() {
  log_info "=== 步骤 2: 安装 nvidia 驱动 ==="

  sudo pacman -Sy --noconfirm
  sudo pacman -S --needed nvidia-open nvidia-utils lib32-nvidia-utils nvidia-prime nvtop --noconfirm

  log_ok "nvidia 驱动安装完成"
}

# ========== 步骤 3: 配置 nvidia-drm modeset ==========
step3_config_modeset() {
  log_info "=== 步骤 3: 配置 nvidia-drm modeset ==="

  local conf_file="/etc/modprobe.d/nvidia.conf"

  if [ -f "$conf_file" ] && grep -q "nvidia-drm modeset=1" "$conf_file"; then
    log_ok "nvidia-drm modeset 已配置"
  else
    log_info "写入 $conf_file"
    sudo tee "$conf_file" <<'EOF'
options nvidia-drm modeset=1
EOF
    log_ok "nvidia-drm modeset=1 配置完成"
  fi
}

# ========== 步骤 4: 重建 initramfs ==========
step4_rebuild_initramfs() {
  log_info "=== 步骤 4: 重建 initramfs ==="
  sudo mkinitcpio -P
  log_ok "initramfs 重建完成"
}

# ========== 步骤 5: 禁用 nouveau (可选) ==========
step5_disable_nouveau() {
  log_info "=== 步骤 5: 禁用 nouveau ==="

  local blacklist_file="/etc/modprobe.d/blacklist-nouveau.conf"

  if [ -f "$blacklist_file" ]; then
    log_ok "nouveau 已在黑名单中"
  else
    sudo tee "$blacklist_file" <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    log_ok "nouveau 已禁用"
  fi
}

main() {
  echo "=== NVIDIA 混合显卡驱动安装 ==="
  echo ""

  step1_check_gpu
  step2_install_nvidia
  step3_config_modeset
  step5_disable_nouveau
  step4_rebuild_initramfs

  echo ""
  echo "=== 安装完成 ==="
  echo "请重启系统使配置生效: sudo reboot"
  echo ""
  echo "重启后验证:"
  echo "  cat /sys/module/nvidia_drm/parameters/modeset  # 应输出 Y"
  echo "  nvidia-smi  # 应显示 GPU 信息"
  echo "  wlr-randr  # 应能看到两个 output 且鼠标可跨屏"
}

main "$@"
