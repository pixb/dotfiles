#!/usr/bin/env bash
# install_nvidia_hybrid.sh - 安装 nvidia 闭源驱动
# 支持: 单 NVIDIA 显卡 / Intel 或 AMD 核显 + NVIDIA 独显的混合显卡
# 作用: 开启 nvidia-drm modeset，让 wlroots 合成器能跨 GPU 共享缓冲区
# 说明: 仅在检测到核显时才安装 nvidia-prime 启用 PRIME 切换

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

# 全局标记
HAS_IGPU=0
IGPU_VENDOR=""

# ========== 步骤 1: 检查 GPU 环境 ==========
step1_check_gpu() {
  log_info "=== 步骤 1: 检查 GPU 环境 ==="

  # 只看显示类设备，避免误匹配 Intel 网卡/声卡等
  local gpus
  gpus=$(lspci -nn | grep -Ei 'VGA compatible controller|3D controller|Display controller')

  if echo "$gpus" | grep -qi '\[10de:'; then
    log_ok "检测到 NVIDIA 独立显卡"
  else
    log_err "未检测到 NVIDIA GPU，退出"
    exit 1
  fi

  # 通过 PCI vendor id 判断核显: Intel=8086, AMD=1002
  if echo "$gpus" | grep -qi '\[8086:'; then
    HAS_IGPU=1
    IGPU_VENDOR="Intel"
  elif echo "$gpus" | grep -qi '\[1002:'; then
    HAS_IGPU=1
    IGPU_VENDOR="AMD"
  fi

  if [ "$HAS_IGPU" -eq 1 ]; then
    log_ok "检测到 $IGPU_VENDOR 核显，按混合显卡模式安装 (启用 PRIME)"
  else
    log_warn "未检测到核显，按单 NVIDIA 显卡模式安装 (跳过 nvidia-prime)"
  fi

  # 检查当前是否已加载 nouveau
  if lsmod | grep -q nouveau; then
    log_info "当前使用 nouveau 驱动，将切换到 nvidia 闭源驱动"
  fi
}

# ========== 步骤 2: 安装 nvidia 驱动 ==========
step2_install_nvidia() {
  log_info "=== 步骤 2: 安装 nvidia 驱动 ==="

  # 必须用 -Syu 做完整升级：nvidia-open 是针对仓库里最新 linux 内核编译的，
  # 只同步数据库 (-Sy) 会造成内核与 nvidia 模块版本不匹配，导致模块无法加载。
  sudo pacman -Syu --noconfirm

  local pkgs=(nvidia-open nvidia-utils nvtop)

  # 32 位库仅在有 multilib 仓库时安装，否则 pacman 会直接报错
  if grep -qE '^\[multilib\]' /etc/pacman.conf; then
    pkgs+=(lib32-nvidia-utils)
  else
    log_warn "未启用 multilib 仓库，跳过 lib32-nvidia-utils"
  fi

  # 仅混合显卡 (存在核显) 才需要 PRIME 切换
  if [ "$HAS_IGPU" -eq 1 ]; then
    pkgs+=(nvidia-prime)
  else
    log_warn "无核显，跳过 nvidia-prime"
  fi

  sudo pacman -S --needed "${pkgs[@]}" --noconfirm

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

# ========== 步骤 6: 校验当前内核是否有 nvidia 模块 ==========
step6_verify_modules() {
  log_info "=== 步骤 6: 校验内核模块 ==="

  local kver
  kver=$(uname -r)

  if ls /usr/lib/modules/"$kver"/extramodules/nvidia.ko* >/dev/null 2>&1; then
    log_ok "当前内核 $kver 已包含 nvidia 模块"
  else
    log_warn "当前运行内核 $kver 没有 nvidia 模块 (通常是因为刚刚升级了内核)"
    log_warn "这是正常的，重启进入新内核后即可加载"
  fi
}

main() {
  echo "=== NVIDIA 显卡驱动安装 ==="
  echo ""

  step1_check_gpu
  step2_install_nvidia
  step3_config_modeset
  step5_disable_nouveau
  step4_rebuild_initramfs
  step6_verify_modules

  echo ""
  echo "=== 安装完成 ==="
  echo "请重启系统使配置生效: sudo reboot"
  echo ""
  echo "重启后验证:"
  echo "  cat /sys/module/nvidia_drm/parameters/modeset  # 应输出 Y"
  echo "  nvidia-smi  # 应显示 GPU 信息"
  if [ "$HAS_IGPU" -eq 1 ]; then
    echo "  wlr-randr  # 应能看到两个 output 且鼠标可跨屏"
  fi
}

main "$@"
