# Load Zsh profile
source ~/.zprofile

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
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi


# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

###################
#  my 10k config  #
###################
source ~/.pl10krc


#########
#  fzf  #
#########
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#########################
#  zsh-autosuggestions  #
#########################
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=yellow'

# Load my custom configurations
source $HOME/dev/linux-demo/config/alias.zsh
source $HOME/dev/linux-demo/config/git.zsh
source $HOME/dev/linux-demo/config/fzf.zsh
source $HOME/dev/linux-demo/config/android.zsh
source $HOME/.profile
export PATH=$HOME/dev/linux-demo/pix-shell:$PATH
export PATH=$HOME/dev/linux-demo/bin:$PATH

############
#  golang  #
############
GVM_FILE=$HOME/.gvm/scripts/gvm
if [ -e ${GVM_FILE} ]; then
  source ${GVM_FILE}
else
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  source ${GVM_FILE}
fi
if ! command -v go >/dev/null 2>&1 || ! $(go version | grep -q 1.25.1) ; then
  gvm install go1.25.1 -B --with-protobuf
  gvm use go1.25.1 --default
fi
go env -w GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOPATH/bin



###########
#  pyenv  #
###########
if [ ! -d "${HOME}"/.pyenv ]; then
  echo -e "${COLOR_YELLOW}pyenv is not install${COLOR_NC}"
  git clone https://github.com/pyenv/pyenv.git "${HOME}"/.pyenv
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo -e "${COLOR_YELLOW} python3 is not install${COLOR_NC}"
  pyenv install 3.13.0
  pyenv global 3.13.0
fi
export PATH=$HOME/.pyenv/bin:$PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"


#########
#  java #
#########
if [ ! -e $HOME/.sdkman ]; then
	curl -s "https://get.sdkman.io" | bash
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"

export JAVA_HOME="/usr/local/jdk-17.0.9/"
export CLASSPATH=.:${JAVA_HOME}/lib:${JAVA_HOME}/jre/lib
export PATH="$PATH:${JAVA_HOME}/lib/tools.jar"

###########
#  rust   #
###########
if [ ! -e $HOME/.cargo ]; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
. "$HOME/.cargo/env"


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

### End of Zinit's installer chunk

[[ -s "/home/pix/.gvm/scripts/gvm" ]] && source "/home/pix/.gvm/scripts/gvm"

if [ -e ${HOME}/dev/env ]; then
  source ${HOME}/dev/env/agentmemory.env
fi
