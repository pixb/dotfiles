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
# fzf
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/fzfrc"
export FZF_DEFAULT_COMMAND='fd --hidden --ignore-file=.gitignore --exclude .git --type f'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (batcat --color=always {} || bat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'

export XDG_CONFIG_HOME="$HOME/.config"    # analogous to /etc
export XDG_CACHE_HOME="$HOME/.cache"      # analogous to /var/cache
export XDG_DATA_HOME="$HOME/.local/share" # analogous to /usr/share
export XDG_STATE_HOME="$HOME/.local/state"

export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export LESSKEYIN="$XDG_CONFIG_HOME/lesskey" # less 710+ reads plain-text key file directly

export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
# ~/.calc_history
export CALCHISTFILE="$XDG_CACHE_HOME/calc_history"
# ~/.nv
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
# export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
# ~/.w3m
export W3M_DIR="$XDG_STATE_HOME/w3m"
# ~/.mailcap
export MAILCAPS="$XDG_CONFIG_HOME/mailcap"
# .Xauthority
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
# ~/.wgetrc
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export ANDROID_SDK_HOME="$XDG_CONFIG_HOME/android"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export PATH="$CARGO_HOME/bin:$PATH" # cargo-installed binaries (rust toolchain comes from pacman)
export NPM_GLOBAL="$XDG_DATA_HOME/npm-global"
export PATH="$NPM_GLOBAL/bin:$PATH" # npm globally-installed binaries
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod" # module cache is disposable, keep in cache
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history" # ~/.node_repl_history
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history" # ~/.python_history
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc" # ~/.npmrc
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle" # ~/.gradle
export ABDUCO_SOCKET_DIR="$XDG_RUNTIME_DIR" # abduco sessions in runtime dir
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" # systemd socket-activated ssh-agent

# pyenv login layer (shell-agnostic): root + bin PATH + shims.
# Interactive layer `pyenv init - <shell>` lives in each rc file.
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

export GRIM_DEFAULT_DIR="$HOME/Pictures/Screenshots"
