#!/usr/bin/env bash
# profile.sh
# @author pix
# @since 2026-11-20
# @desc shell config.
[ "$UID" -eq 0 ] || umask 022 # dir/file:755/644

[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:${PATH}"
[ -d "$HOME/.local/sbin" ] && export PATH="$HOME/.local/sbin:${PATH}"
[ -d "/usr/share/neomutt/oauth2" ] && export PATH="${PATH}:/usr/share/neomutt/oauth2"

[ -x /usr/bin/bat ] && export MANROFFOPT="-c" && export MANPAGER="sh -c 'col -bx | bat --pager \"less -XR\" -l man -p'"
export MANWIDTH=80

export TERM=xterm-256color
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8 # locale
export EDITOR="/usr/bin/nvim"
export PAGER="/usr/bin/less"
export DVTM_EDITOR="/usr/bin/vim"
export DVTM_PAGER="/usr/bin/less -R"
export BROWSER="qutebrowser"
command -v pacman >/dev/null && pacman -Qi nvidia-utils >/dev/null 2>&1 && export QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu' # fix qutebrowser crash on wlroots with nvidia

export XDG_DOWNLOAD_DIR="$HOME/Downloads"
export XDG_DOCUMENTS_DIR="$HOME/Documents"
export XDG_MUSIC_DIR="$HOME/Music"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_VIDEOS_DIR="$HOME/Videos"
export GRIM_DEFAULT_DIR="$HOME/Pictures/Screenshots"

export XDG_CONFIG_HOME="$HOME/.config"    # analogous to /etc
export XDG_CACHE_HOME="$HOME/.cache"      # analogous to /var/cache
export XDG_DATA_HOME="$HOME/.local/share" # analogous to /usr/share
export XDG_STATE_HOME="$HOME/.local/state"

# fzf
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/fzfrc"
export FZF_DEFAULT_COMMAND='fd --hidden --ignore-file=.gitignore --exclude .git --type f'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (batcat --color=always {} || bat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'
