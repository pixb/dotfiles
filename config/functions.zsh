# config/functions.zsh
# zsh specific functions
# @adapted 2026-09-27 from reference .config/zsh/functions.zsh:
#   - restore source changed to ~/.profile (its `export HISTFILE=` line is
#     what actually wins: .zshrc sources ~/.profile after its own HISTFILE)
#   - dropped `prompt` calls (this repo uses p10k, no prompt() function)

# shell history switch
function hist() {
    PROFILE="${HOME}/.profile"

    function status() {
        if [ -z "$HISTFILE" ]; then
            echo "[zsh]: history is disabled"
        else
            echo "[zsh]: history is enabled"
        fi
    }

    function disable() {
        unset HISTFILE
        status
    }

    function enable() {
        eval "$( grep '^export HISTFILE=' $PROFILE)"
        status
    }

    function delete() {
        selection=$(cat "$HISTFILE" | nl -n'ln' -s' ' \
            | /usr/bin/fzf --height 50% --no-preview --wrap \
                           --layout=reverse-list --color \
                           --tac \
                   )
        [ -z "$selection" ] && echo aboarted && return
        echo "$selection"

        lineNumber=$(echo "$selection" | cut -d' ' -f1)
        read "?Delete history entry? (y/n): "
        [ "$REPLY" = "y"  ] && sed -i "${lineNumber}d" "$HISTFILE" || echo aborted
    }

    function print_help() {
        cat <<_EOF_
USAGE
        $(basename "$0") [OPTIONS]
OPTIONS
        -d,--disable    disable shell history for current session
        -D, --Delete    choose a history to be deleted
        -e,--enable     enable shell history for current session
        -f,--file       print shell history file for current session
        -h,--help       print this help info
_EOF_
    }

    [ -z "$1" ] && status

    while [ -n "$1" ]; do
        case "$1" in
            -d|--disable) disable;;
            -e|--enable) enable;;
            -f|--file) echo "[zsh]: history is saved to $HISTFILE";;
            -D|--Delete) delete;;
            -h|--help) print_help;;
            *) print_help;;
        esac
        shift
    done
}
