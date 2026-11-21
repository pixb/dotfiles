# .config/shell/functions.sh
# general functions shared by bash/zsh (sourced from .bashrc and .zshrc)

# cd to the root of the current git repository
gcd() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
    cd "$root" || return 1
}

# print the 16 terminal base colors (0-15)
colors() {
    local i
    for i in {0..15}; do
        printf '\e[48;5;%sm  \e[0m' "$i"
        [ $(((i + 1) % 8)) -eq 0 ] && printf '\n'
    done
}
