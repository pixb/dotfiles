#!/usr/bin/env bash

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# === handing failures and errors. ===
set -euo pipefail

# === File Variable ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
SCRIPT_FULL_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_FILE_NAME="${SCRIPT_FULL_NAME%.*}"

echo -e "${COLOR_GREEN}SCRIPT_DIR = ${SCRIPT_DIR} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FULL_NAME = ${SCRIPT_FULL_NAME} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FILE_NAME = ${SCRIPT_FILE_NAME} ${COLOR_NC}"

SCRIPT_RES_DIR="${HOME}/Downloads"
if [ ! -e ${SCRIPT_RES_DIR} ]; then
  mkdir -p ${SCRIPT_RES_DIR}
fi

# AUR helper: trizen is unmaintained; prefer paru/yay if available.
AUR_HELPER="$(command -v paru || command -v yay || command -v trizen || echo trizen)"

pacman_install_noconfirm() {
  sudo pacman -S "$1" --noconfirm --needed
}

aur_install_noconfirm() {
  "$AUR_HELPER" -S "$1" --noconfirm --needed
}

echo_not_found() {
  echo -e "${COLOR_YELLOW}$1 is not installed, installing...${COLOR_NC}"
}

echo_is_existed() {
  echo -e "${COLOR_GREEN}$1 is already installed.${COLOR_NC}"
}

echo_install_failed() {
  echo -e "${COLOR_RED}Failed to install $1.${COLOR_NC}" >&2
}

warn() {
  echo -e "${COLOR_YELLOW}[warn] $*${COLOR_NC}" >&2
}

die() {
  echo -e "${COLOR_RED}[fail] $*${COLOR_NC}" >&2
  exit 1
}

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
      if ! pacman_install_noconfirm "$package"; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

aur_install() {
  for package in "$@"; do
    if ! check_install "$package"; then
      if ! aur_install_noconfirm "$package"; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

systemctl_enable() {
  if [ "$(systemctl is-enabled $1 2>/dev/null || true)" != "enabled" ]; then
    echo -e "${COLOR_GREEN}enabling $1.${COLOR_NC}"
    sudo systemctl enable $1
  else
    echo -e "${COLOR_GREEN}$1 already enabled${COLOR_NC}"
  fi
}

systemctl_start() {
  if [ "$(systemctl is-active $1 2>/dev/null || true)" != "active" ]; then
    echo -e "${COLOR_GREEN}starting $1${COLOR_NC}"
    sudo systemctl start $1
  else
    echo -e "${COLOR_GREEN}$1 already running${COLOR_NC}"
  fi
}

# === check environment ===
if [ "$(id -u)" -eq 0 ]; then
  die "please run as a normal user, the script uses sudo"
fi

if ! grep -qi '^ID=arch' /etc/os-release 2>/dev/null; then
  die "this script is for Arch Linux only"
fi

SYS_VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
PRODUCT_NAME="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"

if grep -qi 'MECHREVO' <<<"${SYS_VENDOR}"; then
  echo -e "${COLOR_GREEN}detected MECHREVO: ${PRODUCT_NAME}${COLOR_NC}"
else
  warn "no MECHREVO vendor found (sys_vendor=${SYS_VENDOR:-unknown}), TCC may not work"
fi

case "${PRODUCT_NAME}" in
  *JiguangX* | *GM6AR57C*)
    echo -e "${COLOR_GREEN}detected JiguangX (GM6AR57C)${COLOR_NC}"
    ;;
  *)
    warn "this is not JiguangX GM6AR57C, some TCC features may be unavailable"
    ;;
esac

# === conflicts ===
if pacman -Qi auto-cpufreq >/dev/null 2>&1; then
  die "auto-cpufreq conflicts with TCC, please remove it first: sudo pacman -Rns auto-cpufreq"
fi

if pacman -Qi tuxedo-control-center >/dev/null 2>&1; then
  die "source version tuxedo-control-center is installed, please remove it first"
fi

# === dependencies ===
pacman_install base-devel git dkms linux-headers
pacman_install libxss nss gtk3 upower libayatana-appindicator

# bootstrap trizen when no AUR helper is available
if ! command -v "$AUR_HELPER" &>/dev/null; then
  rm -rf "${SCRIPT_RES_DIR}/trizen"
  git clone https://aur.archlinux.org/trizen.git "${SCRIPT_RES_DIR}/trizen"
  cd "${SCRIPT_RES_DIR}/trizen" || exit
  makepkg -si --noconfirm
  cd "${SCRIPT_DIR}" || exit
fi

# === mechrevo/Tongfang driver (provides tuxedo-drivers-dkms) ===
if pacman -Qi tuxedo-drivers-dkms >/dev/null 2>&1 && ! pacman -Qi mechrevo-drivers-dkms >/dev/null 2>&1; then
  die "upstream tuxedo-drivers-dkms is installed, remove it first: sudo pacman -Rd tuxedo-drivers-dkms"
fi

aur_install mechrevo-drivers-dkms

if ! lsmod | grep -q '^tuxedo_io'; then
  sudo modprobe tuxedo_io 2>/dev/null || true
fi

if [ -e /dev/tuxedo_io ] || [ -e /sys/class/tuxedo_io ]; then
  echo -e "${COLOR_GREEN}tuxedo_io interface is available${COLOR_NC}"
else
  warn "tuxedo_io interface is not available yet, reboot and start tccd again"
fi

# === TUXEDO Control Center ===
aur_install tuxedo-control-center-bin

# === enable services ===
sudo systemctl daemon-reload
systemctl_enable tccd-sleep.service
# the AUR post_install may have started tccd-sleep, which stops tccd
sudo systemctl stop tccd-sleep.service 2>/dev/null || true
systemctl_enable tccd.service
systemctl_start tccd.service

# === verify ===
if systemctl is-active --quiet tccd.service; then
  echo -e "${COLOR_GREEN}tccd.service is running${COLOR_NC}"
else
  echo -e "${COLOR_RED}tccd.service is not running${COLOR_NC}" >&2
  sudo journalctl -u tccd.service -n 30 --no-pager || true
  exit 1
fi

cat <<'EOF'

=== install finished ===

start GUI:
  tuxedo-control-center

check service:
  systemctl status tccd

check hardware:
  tailor_hwcaps

notes:
  - JiguangX is not an official TUXEDO model, ODM performance profiles / TDP may be unavailable
  - fan, temperature and keyboard backlight should work through Tongfang/Uniwill drivers
  - reboot if DKMS drivers were installed or upgraded in this run
EOF
