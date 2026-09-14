#########################################################################
# File Name: config_zsh.sh
# Author: pix
# mail: tpxsky@163.com
# Created Time: 2019年12月28日 星期六 18时28分44秒
# Description: 
#########################################################################
#!/bin/bash

echo """
# my configure
source $HOME/dev/linux-demo/config/alias.zsh
source $HOME/dev/linux-demo/config/git.zsh
source $HOME/dev/linux-demo/config/fzf.zsh
source $HOME/dev/linux-demo/config/android.zsh
source $HOME/.profile
""" >> $HOME/.zshrc
