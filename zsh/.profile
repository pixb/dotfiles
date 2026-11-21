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

# SYSTEMD_EDITOR is not set in profile.sh (systemd tools need it)
export SYSTEMD_EDITOR=vim

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
# 原先这里有 export QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu'
# 该方式会覆盖 qutebrowser 自己的 flag 处理(含其崩溃 workaround)，qutebrowser 会告警。
# 已改为在 qutebrowser 的 config.py 里用 c.qt.force_software_rendering='chromium' +
# c.qt.args 实现。参见 dotfiles/qutebrowser/.config/qutebrowser/config.py
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONEREPARENTING=1
export GDK_BACKEND="wayland,x11"
