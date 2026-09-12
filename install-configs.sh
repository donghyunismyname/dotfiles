#!/bin/sh

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

# Symlinks as "source:target" pairs. Only for configs that nothing else
# writes to, so the target can point straight into this repo.
SYMLINKS="
vim:$HOME/.config/vim
vim/vimrc:$HOME/.vimrc
nvim:$HOME/.config/nvim
yazi:$HOME/.config/yazi
tmux:$HOME/.config/tmux
zsh/zshenv:$HOME/.zshenv
"

# Stubs as "source:target" pairs. The target is a real file owned by this
# machine whose first lines load the repo config. Tools that append to it
# (git config --global, installers editing ~/.zshrc) never touch the repo,
# and whatever they append comes after the load line, so it overrides.
STUBS="
zsh/zshrc:$HOME/.zshrc
git/config:$HOME/.gitconfig
"

# stub_content <src>: the lines that load <src>
stub_content() {
    case "$1" in
        */zshrc)     printf 'source %s\n' "$1" ;;
        */git/config) printf '[include]\n\tpath = %s\n' "$1" ;;
    esac
}

# is_done <kind> <src> <dst>: target already links to / loads src
is_done() {
    case "$1" in
        link) [ -L "$3" ] && [ "$(readlink "$3")" = "$2" ] ;;
        stub) [ -f "$3" ] && [ ! -L "$3" ] && grep -qF "$2" "$3" ;;
    esac
}

# Categorize each target
SKIP=""
OVERWRITE=""
NEW=""

for kind in link stub; do
    [ "$kind" = link ] && pairs="$SYMLINKS" || pairs="$STUBS"
    for pair in $pairs; do
        src="$DIR/${pair%%:*}"
        dst="${pair#*:}"
        if is_done "$kind" "$src" "$dst"; then
            SKIP="$SKIP $dst"
        elif [ -e "$dst" ] || [ -L "$dst" ]; then
            OVERWRITE="$OVERWRITE $dst"
        else
            NEW="$NEW $dst"
        fi
    done
done

# Report what will happen
if [ -n "$SKIP" ]; then
    echo "Already set up (skip):"
    for f in $SKIP; do echo "    $f"; done
    echo ""
fi

if [ -n "$NEW" ]; then
    echo "New (create):"
    for f in $NEW; do echo "    $f"; done
    echo ""
fi

if [ -n "$OVERWRITE" ]; then
    echo "Exists (move to *.bak, then overwrite):"
    for f in $OVERWRITE; do echo "    $f"; done
    echo ""
    printf "Overwrite these files? (y/N): "
    read ans
    if [ "$ans" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
    echo ""
fi

# Create symlinks and stubs
for kind in link stub; do
    [ "$kind" = link ] && pairs="$SYMLINKS" || pairs="$STUBS"
    for pair in $pairs; do
        src="$DIR/${pair%%:*}"
        dst="${pair#*:}"
        is_done "$kind" "$src" "$dst" && continue

        mkdir -p "$(dirname "$dst")"
        if [ -L "$dst" ]; then
            rm "$dst"
        elif [ -e "$dst" ]; then
            rm -rf "$dst.bak"
            mv "$dst" "$dst.bak"
        fi

        if [ "$kind" = link ]; then
            ln -s "$src" "$dst"
        else
            stub_content "$src" > "$dst"
        fi
        echo "  $dst -> $src"
    done
done

echo ""
echo "Done."
