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
alias sps="sudo pacman -S"
alias df='df -h -x tmpfs -x efivarfs -x devtmpfs'
alias free='free -h'
alias ip='ip -color=auto'
alias ipa='ip -4 addr show scope global'
alias less='less -i -F'
alias info='info --vi-keys'
alias gpl='gpg --list-keys'
alias gpls='gpg --list-secret-keys'
alias ..='cd ..'
alias ...='cd ../..'
alias lb='lsblk -o name,mountpoints,type,size'
alias lt='ls -rlt --time-style=long-iso'
alias grm="git rebase main"
alias grh="git rebase -i HEAD~~"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdm="git diff main"
alias gp="git pull --rebase"
alias gpo="git push origin"
alias gpom="git push origin main"
alias gcm="git commit -m"
alias gm="git commit"
alias ga="git add"
alias gc="git checkout"
alias gcb="git checkout -b"
alias gco="git clone"
alias gs="git status"
alias gl="git log --graph --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold white)— %an%C(reset)%C(bold yellow)%d%C(reset)' --abbrev-commit --date=relative"
alias gf="git fetch"
