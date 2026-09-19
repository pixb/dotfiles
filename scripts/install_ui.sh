#!/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

function pacman_install() {
  if pacman -Qi "$1" &>/dev/null; then
    echo -e "${COLOR_GREEN}$1 is installed${COLOR_NC}"
  else
    echo -e "${COLOR_YELLOW}$1 is not install${COLOR_NC}"
    sudo pacman -S "$1" --noconfirm
  fi
}

function trizen_install() {
  if pacman -Qi "$1" &>/dev/null; then
    echo -e "${COLOR_GREEN}$1 is installed${COLOR_NC}"
  else
    echo -e "${COLOR_YELLOW}$1 is not install${COLOR_NC}"
    trizen -S "$1" --noconfirm
  fi
}

DOTFILES_PATH="${HOME}/dotfiles"

pacman_install cpio
pacman_install xorg-xinput
pacman_install glfw-wayland
pacman_install waybar
pacman_install obsidian
trizen_install google-chrome
pacman_install kate
pacman_install otf-font-awesome
pacman_install ttf-arimo-nerd
pacman_install noto-fonts
pacman_install noto-fonts-cjk
pacman_install noto-fonts-emoji

sudo usermod -aG input "$USER"

pacman_install wmenu

pacman_install dolphin
pacman_install xorg-xlsclients
pacman_install fcitx5
pacman_install fcitx5-chinese-addons
pacman_install fcitx5-configtool
pacman_install fcitx5-gtk
pacman_install fcitx5-qt
trizen_install fcitx5-skin-fluentdark-git
trizen_install adwaita-qt5
trizen_install adwaita-qt6
pacman_install grim
pacman_install code
trizen_install flameshot-git

pacman_install swaybg
trizen_install greetd

trizen_install foot
trizen_install wlogout

trizen_install xorg-xrdb
pacman_install cliphist
pacman_install wl-clipboard
pacman_install dunst
pacman_install libnotify

pacman_install qutebrowser
pacman_install python-adblock
pacman_install lf
pacman_install wtype
pacman_install mpc
trizen_install abduco
trizen_install dvtm
trizen_install waylock
trizen_install wlrctl

# qutebrowser dependencies
pacman_install dictd
trizen_install dict-gcide
pacman_install qrtool
pacman_install swayimg
pacman_install zathura
pacman_install zathura-pdf-mupdf

cd "${DOTFILES_PATH}" || exit
stow -t ~ foot
stow -t ~ waybar
stow -t ~ chrome
stow -t ~ fcitx5
stow -t ~ dunst
stow -t ~ qutebrowser
