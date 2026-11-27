alias .r=". ~/.zprofile && . ~/.zshrc"
alias rh="rehash"
autoload -Uz run-help
(( ${+aliases[run-help]} )) && unalias run-help
alias help=run-help
