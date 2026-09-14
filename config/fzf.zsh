# fzf
export FZF_DEFAULT_OPTS='--bind ctrl-e:down,ctrl-u:up,ctrl-d:preview-page-down,ctrl-f:preview-page-up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (batcat --color=always {} || bat --color=always {} || ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500" --preview-window right:60%:wrap --height 80% --layout reverse --border'
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX_HEIGHT='80%'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'
