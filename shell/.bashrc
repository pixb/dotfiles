#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export GPG_TTY=$(tty) # TUI pinentry, need be set for each pts

# ls colors (XDG config)
[ -f "$HOME/.config/dircolors" ] && eval "$(dircolors "$HOME/.config/dircolors")"

# general aliases (shared with zsh)
[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"
[ -f "$HOME/.config/shell/functions.sh" ] && . "$HOME/.config/shell/functions.sh"
PS1='[\u@\h \W]\$ '

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
