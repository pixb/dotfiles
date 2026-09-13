#!/bin/bash
sed -i '/Server/s/^#//p' /etc/pacman.d/mirrorlist
cat /etc/pacman.d/mirrorlist | grep ustc >>ustc.txt
sed '5r ustc.txt' /etc/pacman.d/mirrorlist >temp.txt && mv temp.txt /etc/pacman.d/mirrorlist
rm ustc.txt
sed -n '/\[multilib\]/,/#Include = /{ s/^#//; }' /etc/pacman.conf
pacman -Sy archlinux-keyring
pacman-key --refresh-keys
pacman -Syyu --noconfirm
pacman-key --init
pacman-key --populate archlinux

function pacman_install() {
  if pacman -Qi "$1" &>/dev/null; then
    echo -e "${COLOR_GREEN}$1 is installed${COLOR_NC}"
  else
    echo -e "${COLOR_YELLOW}$1 is not install${COLOR_NC}"
    pacman -S "$1" --noconfirm
  fi
}
pacman_install vi
pacman_install sudo
pacman_install zsh
pacman_install git
pacman_install openssh
pacman_install rsync

sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //p' /etc/sudoers
useradd --create-home --groups wheel,root --shell /bin/zsh pix
passwd pix

# set default user
cat <<EOF >/etc/wsl.conf
[user]
default = pix
EOF
