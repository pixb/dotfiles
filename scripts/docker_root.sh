#!/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'
pacman-key --init
pacman-key --populate archlinux
http_proxy=http://192.168.123.88:10809
https_proxy=http://192.168.123.88:10809
ftp_proxy=http://192.168.123.88:10809
export http_proxy
export ftp_proxy
export https_proxy
pacman -Syu --noconfirm

function pacman_install() {
  if pacman -Qi "$1" &>/dev/null; then
    echo -e "${COLOR_GREEN}$1 is installed${COLOR_NC}"
  else
    echo -e "${COLOR_YELLOW}$1 is not install${COLOR_NC}"
    pacman -S "$1" --noconfirm
  fi
}

pacman_install neovim
pacman_install git
pacman_install base-devel
pacman_install binutils
pacman_install man
pacman_install ripgrep --noconfirm
pacman_install fd
pacman_install zsh

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
else
  echo -e "${COLOR_YELLOW} python3 is not install${COLOR_NC}"
  pyenv install 3.13.0
  pyenv global 3.13.0
fi

if grep -q pyenv ${HOME}/.zshrc; then
  echo -e "${COLOR_GREEN}pyenv config exists in .zshrc${COLOR_NC}"
else
  echo -e "${COLOR_YELLOW}pyenv config dont exists in .zshrc${COLOR_NC}"
  cat <<EOF >>${HOME}/.zshrc
###########
#  pyenv  #
###########
export PATH=\$HOME/.pyenv/bin:\$PATH
eval "\$(pyenv init -)"
eval "\$(pyenv init --path)"
if [ -d "\${HOME}/.venv" ]; then
    source "\${HOME}/.venv/bin/activate"
fi
EOF
fi
