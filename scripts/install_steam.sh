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

echo -e "${COLOR_GREEN}SCRIPT_DIR = ${SCRIPT_DIR} ${COLOR_NC}"

# === Helper functions ===

pacman_install_noconfirm() {
  sudo pacman -S "$1" --noconfirm --needed
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

# === Enable multilib repository ===
echo -e "${COLOR_GREEN}Checking multilib repository...${COLOR_NC}"

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo -e "${COLOR_YELLOW}Enabling multilib repository...${COLOR_NC}"
  sudo sed -i '/\[multilib\]/!b;n;/Include/!b;s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|' /etc/pacman.conf
  sudo sed -i '/^#\[multilib\]/{s/#//;n;s/#//}' /etc/pacman.conf
  sudo pacman -Sy
else
  echo -e "${COLOR_GREEN}multilib repository is already enabled.${COLOR_NC}"
fi

# === Install Steam ===
echo -e "${COLOR_GREEN}Installing Steam...${COLOR_NC}"
pacman_install steam

# === Install optional but recommended packages ===
echo -e "${COLOR_GREEN}Installing optional dependencies...${COLOR_NC}"
pacman_install lib32-mesa lib32-vulkan-icd-loader vulkan-tools

# === Wayland / XWayland 检查 ===
echo -e "${COLOR_GREEN}Checking Wayland/XWayland environment...${COLOR_NC}"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  echo -e "${COLOR_GREEN}Running on Wayland session.${COLOR_NC}"

  # 检查 xorg-xwayland 是否安装
  if pacman -Qi xorg-xwayland >/dev/null 2>&1; then
    echo_is_existed "xorg-xwayland"
  else
    echo -e "${COLOR_YELLOW}xorg-xwayland is not installed, installing...${COLOR_NC}"
    pacman_install xorg-xwayland
  fi

  # 检查 DISPLAY 是否设置
  if [ -z "$DISPLAY" ]; then
    echo -e "${COLOR_RED}DISPLAY is not set. Steam requires XWayland to run.${COLOR_NC}"
    echo -e "${COLOR_YELLOW}To fix this, ensure your compositor enables XWayland:${COLOR_NC}"
    echo -e "${COLOR_YELLOW}  - River: Add 'riverctl xwayland' and 'export DISPLAY=:0' to ~/.config/river/init${COLOR_NC}"
    echo -e "${COLOR_YELLOW}  - Hyprland: XWayland is enabled by default${COLOR_NC}"
    echo -e "${COLOR_YELLOW}  - Sway: Add 'xwayland enable' to ~/.config/sway/config${COLOR_NC}"
  else
    echo -e "${COLOR_GREEN}DISPLAY=$DISPLAY is set.${COLOR_NC}"
  fi
else
  echo -e "${COLOR_GREEN}Running on X11 session. No XWayland needed.${COLOR_NC}"
fi

echo -e "${COLOR_GREEN}Steam installation completed!${COLOR_NC}"
echo -e "${COLOR_YELLOW}Note: You may need to install GPU drivers for optimal performance.${COLOR_NC}"
echo -e "${COLOR_YELLOW}  - NVIDIA: sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils${COLOR_NC}"
echo -e "${COLOR_YELLOW}  - AMD: sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon${COLOR_NC}"
echo -e "${COLOR_YELLOW}  - Intel: sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel${COLOR_NC}"
