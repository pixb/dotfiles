# .config/shell/aliases.sh
# general aliases shared by bash/zsh (sourced from .bashrc and .zshrc)

# safety: prompt before destructive / overwriting operations
alias rm='rm -I'       # prompt once when removing >3 files or recursively
alias cp='cp -i'
alias mv='mv -i'

# listing
alias ls='ls -F --color=auto --group-directories-first'
alias ll='ls -lh --time-style=long-iso'
alias la='ls -A'
alias lla='ls -lhA --time-style=long-iso'

# convenience
alias cmd='command'
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias e='$EDITOR'
