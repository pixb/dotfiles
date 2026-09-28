#!/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

function pacman_install() {
  local pkg
  for pkg in "$@"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "${COLOR_GREEN}$pkg is installed${COLOR_NC}"
    else
      echo -e "${COLOR_YELLOW}$pkg is not install${COLOR_NC}"
      sudo pacman -S "$pkg" --noconfirm
    fi
  done
}

function systemctl_enable() {
  if [ "$(systemctl is-enabled "$1" 2>/dev/null || true)" != "enabled" ]; then
    echo -e "${COLOR_GREEN}enabling $1${COLOR_NC}"
    sudo systemctl enable "$1"
  else
    echo -e "${COLOR_GREEN}$1 already enabled${COLOR_NC}"
  fi
}

function systemctl_start() {
  if [ "$(systemctl is-active "$1" 2>/dev/null || true)" != "active" ]; then
    echo -e "${COLOR_GREEN}starting $1${COLOR_NC}"
    sudo systemctl start "$1"
  else
    echo -e "${COLOR_GREEN}$1 already running${COLOR_NC}"
  fi
}

function trizen_install() {
  local pkg
  for pkg in "$@"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo -e "${COLOR_GREEN}$pkg is installed${COLOR_NC}"
    else
      echo -e "${COLOR_YELLOW}$pkg is not install${COLOR_NC}"
      trizen -S "$pkg" --noconfirm
    fi
  done
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
pacman_install slurp
pacman_install code
pacman_install dbeaver
trizen_install flameshot-git

pacman_install swaybg
mkdir -p "${HOME}/Pictures/wallpapers"
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
pacman_install mpd ncmpcpp
pacman_install mpv
pacman_install yt-dlp yt-dlp-ejs
trizen_install abduco
trizen_install dvtm
trizen_install waylock
trizen_install wlrctl
pacman_install firejail
trizen_install wshowkeys-mao-git

# qutebrowser dependencies
pacman_install dictd
trizen_install dict-gcide
systemctl_enable dictd
systemctl_start dictd
pacman_install qrtool
pacman_install swayimg
pacman_install zathura
pacman_install zathura-pdf-mupdf

# docs for books/wiki/jdoc + X-branch viewers for gallery/selwall
pacman_install arch-wiki-docs openjdk-doc
pacman_install nsxiv xwallpaper

# mpd setup
mkdir -p "${HOME}/.cache/mpd" "${HOME}/Music/.playlists"
[ -f "${HOME}/Music/.mpdignore" ] || cp "${DOTFILES_PATH}/Music/.mpdignore" "${HOME}/Music/.mpdignore"

cd "${DOTFILES_PATH}" || exit
stow -t ~ foot
stow -t ~ waybar
stow -t ~ chrome
stow -t ~ fcitx5
stow -t ~ dunst
stow -t ~ qutebrowser
stow -t ~ mpd
stow -t ~ wob
stow -t ~ mutt
stow -t ~ newsboat
stow -t ~ mpv
stow -t ~ ncmpcpp
stow -t ~ yt-dlp
stow -t ~ firejail

# firejail system profiles: repo versions keep mpv/neomutt/newsboat/
# qutebrowser/zathura unwrapped (firecfg.config), then create the
# /usr/local/bin firejail symlinks (same as reference install-root.sh)
sudo cp "${DOTFILES_PATH}/etc/firejail/firecfg.config" /etc/firejail/firecfg.config
sudo cp "${DOTFILES_PATH}/etc/firejail/w3m.profile" /etc/firejail/w3m.profile
sudo firecfg >/dev/null 2>&1 && echo "firejail symlinks created"

# enable mpd socket activation (starts on first mpc connection)
systemctl --user enable --now mpd.socket 2>/dev/null || true

# ufw: allow mpd http stream from LAN
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow from 192.168.0.0/16 to any port 8000 comment "mpd http stream" 2>/dev/null || true
fi
