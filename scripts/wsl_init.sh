#!/usr/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# Exit when an error occurs
set -e
# Throw error when using an undefined variable
set -u

TIME="$(date +%Y-%m-%d_%H-%M-%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
FILE_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

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

# config proxy
# if grep -q "http_proxy" /etc/profile; then
#  echo -e "${COLOR_GREEN}http_proxy is already set.${COLOR_NC}"
#else
#  echo -e "${COLOR_YELLOW}config http_proxy${COLOR_NC}"
#  sudo tee -a /etc/profile <"${HOME}/dev/install-arch/proxy.env"
#fi
# proxy
# http_proxy=http://192.168.123.187:10809
# https_proxy=http://192.168.123.187:10809
# ftp_proxy=http://192.168.123.187:10809
# export http_proxy
# export ftp_proxy
# export https_proxy
sudo pacman-key --init
sudo pacman-key --populate archlinux
pacman_install openssh
pacman_install zip
pacman_install unzip
pacman_install p7zip
pacman_install base-devel
pacman_install git
pacman_install man
pacman_install binutils
pacman_install debugedit
pacman_install highlight

# install trizen
if command -v trizen &>/dev/null; then
  echo -e "${COLOR_GREEN}trizen is installed.${COLOR_NC}"
else
  git clone https://aur.archlinux.org/trizen.git "${HOME}"/Downloads/trizen
  cd "${HOME}"/Downloads/trizen || exit
  makepkg -si
fi

if [ -d "${HOME}"/dev ]; then
  echo -e "${COLOR_GREEN}${HOME}/dev is exist.${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}Create ${HOME}/dev path${COLOR_NC}"
  mkdir -p "${HOME}"/dev
fi

if [ -d "${HOME}"/dev/linux-demo ]; then
  echo -e "${COLOR_GREEN}${HOME}/dev/linux-demo is exist${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}clone linux-demo${COLOR_NC}"
  git clone git@github.com:pixb/linux-demo.git ${HOME}/dev/linux-demo
fi
export EDITOR=vim
trizen_install rcm

if [ -d "${HOME}"/.dotfiles ]; then
  echo -e "${COLOR_GREEN}${HOME}/.dotfiles is exist${COLOR_NC}"
  cd "${HOME}" || exit
  rcup -t rcm
  rcup
else
  echo -e "${COLOR_YELLOW}clone .dotfiles${COLOR_NC}"
  git clone https://github.com/pixb/.dotfiles "${HOME}"/.dotfiles
  cd "${HOME}" || exit
  rcup -t rcm
  rcup
fi

pacman_install fzf
pacman_install the_silver_searcher
pacman_install nodejs
pacman_install npm
rm -rf /home/pix/.cache/trizen/sources/ccat
trizen_install ccat-bin
pacman_install tmux
pacman_install postgresql

if [ ! -d "${HOME}/.tmux" ]; then
  bash "${SCRIPT_DIR}/tmux/config_tmux.sh"
fi

trizen_install duf
pacman_install hdparm
pacman_install fio
pacman_install openssh
pacman_install ripgrep
pacman_install yarn
pacman_install neovim
if [ ! -d "${HOME}/.config/nvim" ]; then
  git clone https://github.com/pixb/pixvim.git ~/.config/nvim
fi
pacman_install fastfetch
pacman_install fd
pacman_install lazygit

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
if command -v python3 >/dev/null 2>&1; then
  echo -e "${COLOR_GREEN}$(python3 --version) is installed${COLOR_NC}"
  if [ -d "${HOME}/.venv" ]; then
    echo -e "${COLOR_GREEN}${HOME}/.venv is exists.${COLOR_NC}"
    source "${HOME}/.venv/bin/activate"
  else
    echo -e "${COLOR_YELLOW}${HOME}/.venv is not exists.${COLOR_NC}"
    python3 -m venv "${HOME}/.venv"
    source "${HOME}/.venv/bin/activate"
  fi
else
  echo -e "${COLOR_YELLOW} python3 is not install${COLOR_NC}"
  pyenv install 3.13.0
  pyenv global 3.13.0
fi
if [ -d "${HOME}/dev/vimrc" ]; then
  echo -e "${COLOR_GREEN}echo vimrc is exists${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}echo vimrc is not exists${COLOR_NC}"
  git clone https://github.com/pixb/vimrc.git "${HOME}/dev/vimrc"
fi

if [ -e "${HOME}/.vimrc" ]; then
  echo -e "${COLOR_GREEN}${HOME}/.vimrc is exists${COLOR_NC}"
else
  echo -e "${COLOR_GREEN}${HOME}/.vimrc is not exists${COLOR_NC}"
  ln -sf "${HOME}/dev/vimrc/vimrc" "${HOME}"/.vimrc
fi

pacman_install btop
pacman_install htop
pacman_install wget

if command -v ranger >/dev/null 2>&1; then
  echo -e "${COLOR_GREEN}ranger is intalled${COLOR_NC}"
  ln -sf "${HOME}/dev/install-arch/config/ranger" "${HOME}/.config/ranger"
else
  echo -e "${COLOR_YELLOW}ranger is not install${COLOR_NC}"
  pip3 install setuptools
  trizen_install ranger-git
fi

pacman_install openbsd-netcat
pacman_install pkgfile
pacman_install man
pacman_install docker
pacman_install docker-compose
if [ -d /etc/docker ]; then
  sudo mkdir -p /etc/docker
fi
# if ! grep -q cf-workers /etc/docker/daemon.json; then
#   sudo tee -a /etc/docker/daemon.json <<EOF
# {
#   "registry-mirrors": ["https://cf-workers-docker-io-682.pages.dev/"]
# }
# EOF
# fi

sudo systemctl enable docker
sudo systemctl start docker
pacman_install lsof
pacman_install nethogs

### config cuda
if command -v nvidia-smi >/dev/null 2>&1; then
  echo -e "${COLOR_GREEN}nvidia-smi is exists.${COLOR_NC}"
  pacman_install cuda
  pacman_install nvidia-container-toolkit
fi
