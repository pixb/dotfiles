# fzf shell keybindings
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh

# Override Ctrl-T → Ctrl-F for file finder
bindkey -M emacs '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget
bindkey -M viins '^F' fzf-file-widget

export FZF_DEFAULT_OPTS='--bind ctrl-e:down,ctrl-u:up,ctrl-d:preview-page-down,ctrl-f:preview-page-up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (batcat --color=always {} || bat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500" --preview-window right:60%:wrap --height 80% --layout reverse --border'
export FZF_DEFAULT_COMMAND='fd --hidden --ignore-file=.gitignore --exclude .git --type f'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (batcat --color=always {} || bat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'
