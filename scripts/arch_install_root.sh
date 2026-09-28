#!/usr/bin/env bash

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# === handing failures and errors. ===
set -euo pipefail

# === Time ===
TIME="$(date +%Y-%m-%d_%H-%M-%S)"
# === File Variable ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
FILE_NAME="${SCRIPT_NAME%.*}"

# === General function definition ===
pacman_install_noconfirm() {
  pacman -S "$1" --noconfirm --needed
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

# Check whether a package is installed in the local pacman database.
# AUR packages installed via any helper are also tracked here.
# Returns 0 if installed, 1 otherwise.
check_install() {
  if pacman -Qi "$1" >/dev/null 2>&1; then
    echo_is_existed "$1"
    return 0
  else
    echo_not_found "$1"
    return 1
  fi
}

# Install one package from official repos if not already installed.
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

# === key init update.===
pacman-key --init
pacman-key --populate archlinux

# === CPU type ===
CPU="Intel"
if grep -q AMD /proc/cpuinfo; then
  echo "AMD CPU"
  CPU="AMD"
fi

if grep -q Intel /proc/cpuinfo; then
  echo "Intel CPU"
  CPU="Intel"
fi

pacman_install base-devel binutils debugedit git
pacman_install zip unzip vim wget linux-headers

if [ ${CPU} = "Intel" ]; then
  echo -e "${COLOR_GREEN}Install intel-ucode${COLOR_NC}"
  pacman_install intel-ucode
else
  echo -e "${COLOR_GREEN}Install amd-ucode${COLOR_NC}"
  pacman_install amd-ucode
fi

pacman_install tree man linux neovim networkmanager
pacman_install net-tools wpa_supplicant zsh sudo

if [ -e /etc/localtime ]; then
  echo -e "${COLOR_GREEN}/etc/localtime is exists${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}/etc/localtime is not exists${COLOR_NC}"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
fi

hwclock --systohc
locale_file="/etc/locale.gen"
# check locale file
if [ -f "$locale_file" ]; then
  # 使用 sed 移除前面的注释符号
  sed -i 's/# *\(en_US.UTF-8 UTF-8\)/\1/' "$locale_file"
  sed -i 's/# *\(zh_CN.UTF-8 UTF-8\)/\1/' "$locale_file"
  echo "Success update /etc/locale.gen"
else
  echo -e "${COLOR_RED}Error:file $locale_file is not exists.${COLOR_NC}"
fi

locale-gen
echo LANG=en_US.UTF-8 >/etc/locale.conf

if [ ! -f /etc/hostname ]; then
  echo -e "${COLOR_GREEN}Plase input hostname:${COLOR_NC}"
  read -r HOST_NAME
  echo "${HOST_NAME}"
  echo "${HOST_NAME}" >>/etc/hostname
  cat <<EOF >/etc/hosts
  127.0.0.1       localhost
  ::1             localhost
  127.0.1.1       ${HOST_NAME}.localdomain ${HOST_NAME}
EOF
fi

systemctl enable NetworkManager.service
echo -e "${COLOR_GREEN}Input root password${COLOR_NC}"
passwd
echo -e "${COLOR_GREEN}Plase input username:${COLOR_NC}"
read -r USER_NAME
if id "${USER_NAME}" &>/dev/null; then
  echo -e "${COLOR_GREEN}${USER_NAME} is exists${COLOR_NC}"
else
  useradd --create-home --groups wheel,root --shell /bin/zsh "${USER_NAME}"
  echo -e "${COLOR_GREEN}Input ${USER_NAME} password${COLOR_NC}"
  passwd "${USER_NAME}"
fi

# sed -i 's/# *\(%wheel.*NOPASSWD: ALL\)/\1/' /etc/sudoers
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //p' /etc/sudoers

# 自动检测引导模式
if [ -d /sys/firmware/efi ]; then
  BOOT_MODE="uefi"
else
  BOOT_MODE="bios"
fi

# 自动检测安装磁盘
echo -e "${COLOR_GREEN}可用磁盘列表：${COLOR_NC}"
lsblk -dpno NAME,SIZE,MODEL
echo ""
read -r -p "请输入目标磁盘（如 /dev/sda）: " TARGET_DISK

if [ -z "$TARGET_DISK" ]; then
  echo -e "${COLOR_RED}错误：未指定目标磁盘${COLOR_NC}" >&2
  exit 1
fi

if [ ! -b "$TARGET_DISK" ]; then
  echo -e "${COLOR_RED}错误：$TARGET_DISK 不存在或不是块设备${COLOR_NC}" >&2
  exit 1
fi

if [ "$BOOT_MODE" = "uefi" ]; then
  pacman_install archlinux-keyring grub efibootmgr os-prober openssh
else
  pacman_install archlinux-keyring grub os-prober openssh
fi

if [ ! -d /boot/grub ]; then
  mkdir -p /boot/grub
fi

if [ "$BOOT_MODE" = "uefi" ]; then
  # 验证 /boot 是否为 FAT32 文件系统（EFI 分区要求）
  BOOT_FS=$(findmnt -n -o FSTYPE /boot 2>/dev/null || true)
  if [ "$BOOT_FS" != "vfat" ]; then
    echo -e "${COLOR_YELLOW}警告：/boot 分区不是 FAT32 格式（当前：$BOOT_FS），EFI 引导可能失败${COLOR_NC}"
    read -r -p "是否继续安装？(y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
      echo -e "${COLOR_RED}安装已取消${COLOR_NC}"
      exit 1
    fi
  fi
  
  if ! grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch; then
    echo -e "${COLOR_RED}错误：grub-install (UEFI) 安装失败${COLOR_NC}" >&2
    exit 1
  fi
else
  if ! grub-install --target=i386-pc "$TARGET_DISK"; then
    echo -e "${COLOR_RED}错误：grub-install (BIOS) 安装失败${COLOR_NC}" >&2
    exit 1
  fi
fi

if ! grub-mkconfig -o /boot/grub/grub.cfg; then
  echo -e "${COLOR_RED}错误：grub-mkconfig 生成配置失败${COLOR_NC}" >&2
  exit 1
fi

systemctl enable sshd.service
