#!/usr/bin/env bash

# MECHREVO 极光X (JiguangX Series GM6AR57C) 机型专用安装脚本
#
# 这台机器用 Uniwill/同方 EC，风扇占空比只能通过 mechrevo-drivers 提供的
# /dev/tuxedo_io 读取和写入（尺度 0-200，200 = 100%）。
#
# 安装内容:
#   dkms + linux-headers + mechrevo-drivers-dkms  (tuxedo_io / 键盘 / WMI 驱动)
#   /usr/local/bin/mechrevo-fan    读/写风扇占空比 (mechrevo-fan.c 编译)
#   /usr/local/bin/mechrevo-fanctl 风扇曲线执行器 (多源温度取最大值)
#   /etc/systemd/system/mechrevo-fanctl.{service,timer}  每 10 秒一拍
#     (旧的 /etc/cron.d/fanmode 每分钟一拍会被删除: 两处同时写占空比会互相打架)
#   /etc/systemd/system/nvidia-clocklimit.service  GPU 锁频 (本机 TGP 不可写)
# 停用:
#   tccd.service (Tuxedo Control Center) —— 它的 Auto 模式会在几秒内把
#   mechrevo-fanctl 写入的占空比拽回 EC 内置曲线，风扇控制权只能有一个。
#
# 曲线在 mechrevo-fanctl 顶部的 DUTIES / LIMITS 两行，说明见 README.md。

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1

# === Helpers (same conventions as arch_install_user.sh) ===
AUR_HELPER="$(command -v paru || command -v yay || command -v trizen || echo trizen)"

echo_not_found() { echo -e "${COLOR_YELLOW}$1 is not installed, installing...${COLOR_NC}"; }
echo_is_existed() { echo -e "${COLOR_GREEN}$1 is already installed.${COLOR_NC}"; }
echo_install_failed() { echo -e "${COLOR_RED}Failed to install $1.${COLOR_NC}" >&2; }
warn() { echo -e "${COLOR_YELLOW}[warn] $*${COLOR_NC}" >&2; }
info() { echo -e "${COLOR_GREEN}[ok] $*${COLOR_NC}"; }

check_install() {
  if pacman -Qi "$1" >/dev/null 2>&1; then
    echo_is_existed "$1"
    return 0
  else
    echo_not_found "$1"
    return 1
  fi
}

pacman_install() {
  for package in "$@"; do
    if ! check_install "$package"; then
      if ! sudo pacman -S "$package" --noconfirm --needed; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

aur_install() {
  for package in "$@"; do
    if ! check_install "$package"; then
      if ! "$AUR_HELPER" -S "$package" --noconfirm --needed; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

# === Machine check ===
if ! grep -qi 'MECHREVO' /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null; then
  warn "not a MECHREVO machine, nothing to do"
  exit 0
fi
info "MECHREVO $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"

# === Drivers ===
pacman_install dkms linux-headers gcc
aur_install mechrevo-drivers-dkms

if [ ! -e /dev/tuxedo_io ]; then
  warn "/dev/tuxedo_io 不存在，dkms 模块需要重启后才能用，重启后重跑本脚本"
  exit 0
fi

# === Fan read/set tool ===
if [ -f "${SCRIPT_DIR}/mechrevo-fan.c" ]; then
  sudo gcc -O2 -Wall -Wextra -fstack-protector-strong -fstack-clash-protection -s \
    -o /usr/local/bin/mechrevo-fan "${SCRIPT_DIR}/mechrevo-fan.c"
  sudo chmod 755 /usr/local/bin/mechrevo-fan
  info "/usr/local/bin/mechrevo-fan"
else
  warn "mechrevo-fan.c 不存在，跳过编译"
  exit 1
fi

# === Fan curve runner + systemd timer ===
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [ -f "${SCRIPT_DIR}/mechrevo-fanctl" ]; then
  sudo cp "${SCRIPT_DIR}/mechrevo-fanctl" /usr/local/bin/mechrevo-fanctl
  sudo chmod 755 /usr/local/bin/mechrevo-fanctl
  info "/usr/local/bin/mechrevo-fanctl"
else
  warn "mechrevo-fanctl 不存在，跳过曲线安装"
  exit 1
fi

for unit in mechrevo-fanctl.service mechrevo-fanctl.timer; do
  if [ -f "${DOTFILES_DIR}/etc/systemd/system/${unit}" ]; then
    sudo cp "${DOTFILES_DIR}/etc/systemd/system/${unit}" "/etc/systemd/system/${unit}"
    sudo chmod 644 "/etc/systemd/system/${unit}"
  else
    warn "etc/systemd/system/${unit} 不存在，跳过"
  fi
done

# 旧的 cron 一拍必须撤掉: 曲线只能有一个写入者
if [ -f /etc/cron.d/fanmode ]; then
  sudo rm -f /etc/cron.d/fanmode
  info "/etc/cron.d/fanmode 已删除 (改由 systemd timer 驱动)"
fi

sudo systemctl daemon-reload
sudo systemctl enable --now mechrevo-fanctl.timer
info "mechrevo-fanctl.timer 已启用 (每 10 秒一拍)"

# GPU 锁频 (TGP 在这台机器上不可写: nvidia-smi -pl 被拒, EC ctgp_offset 只接受正向偏移)
if command -v nvidia-smi >/dev/null 2>&1; then
  if [ -f "${DOTFILES_DIR}/etc/systemd/system/nvidia-clocklimit.service" ]; then
    sudo cp "${DOTFILES_DIR}/etc/systemd/system/nvidia-clocklimit.service" /etc/systemd/system/
    sudo chmod 644 /etc/systemd/system/nvidia-clocklimit.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now nvidia-clocklimit.service
    info "nvidia-clocklimit.service 已启用 (SM 210-1400MHz / 显存 6001MHz)"
  fi
fi

# tccd 的 Auto 会覆盖脚本写入的占空比
if systemctl list-unit-files --no-pager 2>/dev/null | grep -q '^tccd.service'; then
  sudo systemctl disable --now tccd.service 2>/dev/null || true
  info "tccd.service 已停用 (风扇由 mechrevo-fanctl 接管)"
fi

# === First run ===
sudo /usr/local/bin/mechrevo-fanctl
info "当前风扇: $(sudo /usr/local/bin/mechrevo-fan -v 2>&1 >/dev/null | tail -1)"

cat <<'EOF'

用法:
  sudo /usr/local/bin/mechrevo-fan          # 读占空比 (0-200)
  sudo /usr/local/bin/mechrevo-fan -v       # 附带风扇温度/限制
  sudo /usr/local/bin/mechrevo-fan w 120    # 手动设定 (0=停, 200=满)
  sudo /usr/local/bin/mechrevo-fan a        # 交回 EC 自动 (需重新启用 tccd)

改曲线: 编辑 /usr/local/bin/mechrevo-fanctl 顶部的 DUTIES / LIMITS
改锁频: 编辑 /etc/systemd/system/nvidia-clocklimit.service 里的 -lgc / -lmc 数值
回退 TCC: sudo systemctl enable --now tccd.service && sudo /usr/local/bin/mechrevo-fan a
EOF
