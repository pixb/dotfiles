# .zprofile
# zsh specific profile

[ -f "${HOME}/.config/shell/profile.sh" ] && . "${HOME}/.config/shell/profile.sh"

[ -d "${XDG_CACHE_HOME}/zsh" ] || mkdir -p "${XDG_CACHE_HOME}/zsh"
[ -d "${XDG_STATE_HOME}/zsh" ] || mkdir -p "${XDG_STATE_HOME}/zsh"

export HISTFILE="${XDG_STATE_HOME}/zsh/history"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

export HISTORY_IGNORE="(cd|cd -|cd ..|pwd|ls|exit|)"
