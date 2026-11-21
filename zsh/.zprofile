# .zprofile
# zsh specific profile

[ -f "${HOME}/.config/shell/profile.sh" ] && . "${HOME}/.config/shell/profile.sh"

[ -d "${XDG_CACHE_HOME}/zsh" ] || mkdir -p "${XDG_CACHE_HOME}/zsh"
[ -d "${XDG_STATE_HOME}/zsh" ] || mkdir -p "${XDG_STATE_HOME}/zsh"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
export LANGUAGE=en_US
export LANG=en_US.UTF-8

export HISTFILE="${XDG_STATE_HOME}/zsh/history"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"

export HISTORY_IGNORE="(cd|cd -|cd ..|pwd|ls|exit|)"
