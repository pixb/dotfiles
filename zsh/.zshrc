export GPG_TTY=$(tty) # TUI pinentry, need be set for each pts

# 设置 vi 模式
set -o vi

###############
#  oh-my-zsh  #
###############
plugins=(
    git
    # 其他需要的插件可以在此添加
)
###########
#  zinit  #
###########
ZINIT_FILE=$HOME/.local/share/zinit/zinit.git/zinit.zsh
if [ -e ${ZINIT_FILE} ]; then
    source ${ZINIT_FILE}
else
    NO_EDIT=1 NO_ANNEXES=1 bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi


###################
#  my 10k config  #
###################
# Switch between prompt styles by editing the line below:
# source ~/.pl10krc    # Original style (detailed)
# source ~/.pl10krc2   # Minimal style (lean, performance-focused)
source ~/.pl10krc2


#########
#  fzf  #
#########
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# shell keybindings (migrated from dotfiles/config/fzf.zsh)
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
# Override Ctrl-T -> Ctrl-F for file finder
bindkey -M emacs '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget
bindkey -M viins '^F' fzf-file-widget

#########################
#  zsh-autosuggestions  #
#########################
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=yellow'

# ls colors (XDG config) + sync zsh completion colors
[ -f "$HOME/.config/dircolors" ] && eval "$(dircolors "$HOME/.config/dircolors")"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Load my custom configurations
# general bash/zsh aliases first, then zsh-specific ones (can override)
[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"
[ -f "$HOME/.config/shell/functions.sh" ] && . "$HOME/.config/shell/functions.sh"
source $HOME/dotfiles/config/alias.zsh
source $HOME/dotfiles/config/git.zsh
source $HOME/dotfiles/config/android.zsh

# shell teleport: comma-path aliases (,h ,dm ,m ...); autocd makes them cd
[ -f "$HOME/.config/shell/teleport.sh" ] && . "$HOME/.config/shell/teleport.sh"
setopt autocd    # auto cd by typing path

# shell functions: hist -d/-e/-D history switch (no-history sessions)
source $HOME/dotfiles/config/functions.zsh

export GOPROXY=https://goproxy.cn,direct


###########
#  pyenv  #
###########
# 安装由 scripts/arch_install_user.sh 负责；这里只做交互层初始化
[ -x "$PYENV_ROOT/bin/pyenv" ] && eval "$(pyenv init - zsh)"


#########
#  java #
#########
if [ ! -e $HOME/.sdkman ]; then
	curl -s "https://get.sdkman.io" | bash
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"


#######
#  ex #
#######
# ex - archive extractor
# usage: ex <file>
ex () {
  if [ -f "$1" ]; then
    case $1 in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 "$1"    ;;
      *.rar)       unrar x "$1"    ;;
      *.gz)        gunzip "$1"     ;;
      *.tar)       tar xf "$1"     ;;
      *.tbz2)      tar xjf "$1"    ;;
      *.tgz)       tar xzf "$1"    ;;
      *.zip)       unzip "$1"      ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"       ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Load JetBrains VM options
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"
[ -f "${___MY_VMOPTIONS_SHELL_FILE}" ] && . "${___MY_VMOPTIONS_SHELL_FILE}"

#################
#  zinit plugins
#################
# custom completions
fpath=(~/.local/share/zsh/site-functions $fpath)
# Ensure compinit is loaded before loading plugins
autoload -Uz compinit && compinit
zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit ice wait'1' lucid  # 延迟 1 秒加载
zinit light zsh-users/zsh-history-substring-search
zinit ice wait'0' lucid  # 异步+静默加载
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma/fast-syntax-highlighting
zinit light zpm-zsh/ls
zinit ice atload'
    local zlua="${ZINIT[PLUGINS_DIR]:-$HOME/.local/share/zinit/plugins}/skywind3000--z.lua/z.lua"
    [[ -f "$zlua" ]] && eval "$(lua "$zlua" --init zsh)"
'
zinit light skywind3000/z.lua
zinit snippet OMZ::plugins/extract/extract.plugin.zsh
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
# zinit light b4b4r07/enhancd

# Install plugins if there are plugins that have not been installed
# zinit self-update
# zinit update --all

if [ -e ${HOME}/dev/env ]; then
  . <(gpg -d ~/dev/env/env/agentmemory.env.gpg 2>/dev/null)
  . <(gpg -d ~/dev/env/env/amux.env.gpg 2>/dev/null)
  # eval "$(gpg --decrypt ~/dev/env/env/agentmemory.env.gpg 2>/dev/null)"
  # eval "$(gpg --decrypt ~/dev/env/env/amux.env.gpg 2>/dev/null)"
fi

# flutter (install_flutter_web.sh)
export PATH="$PATH:/home/pix/.local/share/flutter/bin"
export ANET_HUB_TOKEN="atok_820179a164ca41ccbc3ba21f770e9600"

# kvm
export LIBVIRT_DEFAULT_URI=qemu:///system
