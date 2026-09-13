#########################################################################
# File Name: config_tmux.sh
# Author: pix
# mail: tpxsky@163.com
# Created Time: Tue 14 Apr 2020 06:35:10 AM UTC
# Description:
#########################################################################
#!/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# Exit when an error occurs
set -e
# Throw error when using an undefined variable
set -u

TIME="$(date +%Y-%m-%d_%H-%M-%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
FILE_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
git clone https://github.com/gpakosz/.tmux.git "${HOME}/.tmux"
ln -s -f "${HOME}/.tmux/.tmux.conf" "${HOME}/.tmux.conf"
cp "${HOME}/.tmux/.tmux.conf.local" "${HOME}"
cat "${SCRIPT_DIR}/.tmux.conf" >>"${HOME}/.tmux.conf.local"
