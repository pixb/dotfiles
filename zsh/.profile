# ~/.profile: executed by the command interpreter for login shells.
# @author nate zhou
# @since 2023,2024,2025,2026

[ -f "$HOME/.config/shell/profile.sh" ] && . "$HOME/.config/shell/profile.sh"

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # include .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
  fi
fi

[ -d "$XDG_STATE_HOME"/bash ] || mkdir -p "$XDG_STATE_HOME/bash"
export HISTFILE="$XDG_STATE_HOME/bash/history"
export HISTIGNORE="cd:cd -:cd ..:pwd:ls:exit"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# export BROWSER=/usr/bin/chromium
export BROWSER=/usr/bin/google-chrome-stable
export EDITOR=/usr/bin/nvim
export SYSTEMD_EDITOR=vim

# export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

################
# wayland env
################
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_FONT_DPI=96
export QT_QPA_PLATFORM="wayland;xcb"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_QPA_PLATFORMTHEME=qt5ct
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
export QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu'
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONEREPARENTING=1
export GDK_BACKEND="wayland,x11"
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=River
export XDG_CURRENT_DESKTOP=River

. "$HOME/.cargo/env"
