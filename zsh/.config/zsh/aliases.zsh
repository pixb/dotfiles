alias sps="sudo pacman -S"
alias pc="proxychains"
alias pcsps="proxychains sudo pacman -S"
alias .r=". ~/.zprofile && . ~/.zshrc"
alias rh="rehash"
autoload -Uz run-help
(( ${+aliases[run-help]} )) && unalias run-help
alias help=run-help
