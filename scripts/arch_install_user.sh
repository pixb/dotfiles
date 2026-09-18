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
SCRIPT_FULL_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_FILE_NAME="${SCRIPT_FULL_NAME%.*}"

echo -e "${COLOR_GREEN}SCRIPT_DIR = ${SCRIPT_DIR} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FULL_NAME = ${SCRIPT_FULL_NAME} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FILE_NAME = ${SCRIPT_FILE_NAME} ${COLOR_NC}"

# res path
SCRIPT_RES_DIR="${HOME}/Downloads"
if [ ! -e ${SCRIPT_RES_DIR} ]; then
  mkdir -p ${SCRIPT_RES_DIR}
fi

# Define the methods for install Arch Linux packages.

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

# Install one package from AUR (or any repo the helper supports) if not installed.
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
  # 未启用才 enable
  if [ "$(systemctl is-enabled $1 2>/dev/null || true)" != "enabled" ]; then
    echo -e "${COLOR_GREEN}enabling $1.${COLOR_NC}"
    sudo systemctl enable $1
  else
    echo -e "${COLOR_GREEN}$1 already enabled${COLOR_NC}"
  fi
}

systemctl_start() {
  # 未运行才 start
  if [ "$(systemctl is-active $1 2>/dev/null || true)" != "active" ]; then
    echo -e "${COLOR_GREEN}starting $1${COLOR_NC}"
    sudo systemctl start $1
  else
    echo -e "${COLOR_GREEN}$1 already running${COLOR_NC}"
  fi
}

### Install nodejs

pacman_install nodejs npm

if [ ! -e ${HOME}/.npm-global ]; then
  mkdir -p ${HOME}/.npm-global
fi

npm config set prefix ~/.npm-global

pacman_install stow

# === dotfiles ===
DOTFILES_PATH=${HOME}/dotfiles

# === vimrc ===
cd ${DOTFILES_PATH}
stow -t ~ vim
stow -t ~ zsh
stow -t ~ git
stow -t ~ shell
stow -t ~ go
cd ${SCRIPT_DIR}

if [ -e $HOME/.sdkman/bin/sdkman-init.sh ]; then
  echo -e "${COLOR_GREEN}sdkman is installed${COLOR_NC}"
  set +u
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  set -u
else
  echo -e "${COLOR_YELLOW}sdkman not init, init...${COLOR_NC}"
  curl -s "https://get.sdkman.io" | bash
fi

if command -v java &>/dev/null; then
  echo -e "${COLOR_GREEN}java is installed${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}java is not install${COLOR_NC}"
  if command -v sdk &>/dev/null; then
    echo -e "${COLOR_GREEN}sdkman is installed${COLOR_GREEN}"
    set +u
    if [ ! -e ${HOME}/.sdkman/candidates/java/11.0.23-tem ]; then
      sdk install java 11.0.23-tem
    fi
    set -u
  else
    echo -e "${COLOR_YELLOW}sdknam is not install${COLOR_NC}"
  fi
fi

# === Create dev ===
if [ -d "${HOME}/dev" ]; then
  echo -e "${COLOR_GREEN}${HOME}/dev is exists${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}${HOME}/dev is not exists${COLOR_NC}"
  mkdir -p "${HOME}/dev"
fi

# === install trizen ===
if command -v trizen &>/dev/null; then
  echo -e "${COLOR_GREEN}trizen is installed.${COLOR_NC}"
else
  rm -rf "${SCRIPT_RES_DIR}/trizen"
  git clone https://aur.archlinux.org/trizen.git "${SCRIPT_RES_DIR}/trizen"
  cd "${SCRIPT_RES_DIR}/trizen" || exit
  makepkg -si --noconfirm
  cd ${SCRIPT_DIR}
fi

cd "${HOME}/dotfiles" || exit
stow -t ~ trizen
cd "${SCRIPT_DIR}" || exit

pacman_install neovim openssh tk fzf the_silver_searcher
pacman_install tmux go ripgrep lazygit imagemagick highlight
pacman_install p7zip rsync cifs-utils smbclient stow

# ssh service start
if command -v ssh >/dev/null 2>&1; then
  echo -e "${COLOR_GREEN}openssh is installed${COLOR_NC}"

  # 未启用才 enable
  systemctl_enable sshd.service
  # 未运行才 start
  systemctl_start sshd.service
fi

# pyenv
if [ -d "${HOME}"/.pyenv ]; then
  echo -e "${COLOR_GREEN}pyenv is installed${COLOR_NC}"
  export PATH=$HOME/.pyenv/bin:$PATH
  eval "$(pyenv init -)"
else
  echo -e "${COLOR_YELLOW}pyenv is not install${COLOR_NC}"
  git clone https://github.com/pyenv/pyenv.git "${HOME}"/.pyenv
  export PATH=$HOME/.pyenv/bin:$PATH
  eval "$(pyenv init -)"
fi

if command -v pyenv &>/dev/null; then
  if pyenv versions --bare | grep -qx "3.12.13"; then
    echo "3.12.13 已安装，跳过"
  else
    pyenv install 3.12.13
    pyenv global 3.12.13
  fi
fi

# === ranger ===
pip3 install setuptools
aur_install ranger-git

cd ${DOTFILES_PATH}
stow -t ~ ranger
cd ${SCRIPT_DIR}

aur_install fastfetch
pacman_install gdb gcc cmake meson htop btop duf usbutils rust

if [ ! -d $HOME/.tmux ]; then
  bash ${SCRIPT_DIR}/../tmux/config_tmux.sh
fi

pacman_install bc

if command -v pkgfile &>/dev/null; then
  echo -e "${COLOR_GREEN}pkgfile is installed${COLOR_NC}"
  sudo pkgfile --update
else
  echo -e "${COLOR_YELLOW}pkgfile is not install${COLOR_NC}"
  sudo pacman -S pkgfile --noconfirm
fi

pacman_install openbsd-netcat
pacman_install docker
pacman_install docker-compose
if [ ! -d /etc/docker ]; then
  sudo mkdir -p /etc/docker
fi

if [ ! -e /etc/docker/daemon.json ]; then
  sudo tee -a /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [
      "https://docker.xuanyuan.me",
      "https://docker.1ms.run",
      "https://docker.m.daocloud.io",
      "https://docker.1panel.live",
      "https://registry.hub.docker.com",
      "https://docker.m.daocloud.io"
    ]
}
EOF
fi

systemctl_enable docker
systemctl_start docker

pacman_install pipewire
pacman_install pipewire-pulse
pacman_install pipewire-alsa
pacman_install wireplumber
systemctl --user enable --now pipewire pipewire-pulse wireplumber

pacman_install bluez
pacman_install bluez-utils
pacman_install bluetui
systemctl_enable bluetooth
systemctl_start bluetooth
pacman_install nethogs
pacman_install fd

# samba
pacman_install samba
cd "${DOTFILES_PATH}"
sudo stow -t / samba
cd "${SCRIPT_DIR}"
mkdir -p ~/work

# create samba user
sudo groupadd sambashare 2>/dev/null || true
sudo usermod -aG sambashare "$(whoami)"
echo "设置 samba 密码（将用于 Windows/macOS 访问共享）:"
sudo smbpasswd -a "$(whoami)"

systemctl_enable smb
systemctl_start smb
systemctl_enable nmb
systemctl_start nmb
