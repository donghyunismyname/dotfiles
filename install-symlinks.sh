#!/bin/sh

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

# Define symlinks as "source:target" pairs
SYMLINKS="
vim/vimrc:$HOME/.vimrc
vim:$HOME/.vim
nvim:$HOME/.config/nvim
tmux/tmux.conf:$HOME/.tmux.conf
zsh/zshrc:$HOME/.zshrc
git/gitconfig:$HOME/.gitconfig
claude/commands:$HOME/.claude/commands
claude/CLAUDE.md:$HOME/.claude/CLAUDE.md
"

# Categorize each symlink
SKIP=""
OVERWRITE=""
NEW=""

for pair in $SYMLINKS; do
    src="$DIR/$(echo "$pair" | cut -d: -f1)"
    dst="$(echo "$pair" | cut -d: -f2)"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        SKIP="$SKIP $dst"
    elif [ -e "$dst" ] || [ -L "$dst" ]; then
        OVERWRITE="$OVERWRITE $dst"
    else
        NEW="$NEW $dst"
    fi
done

# Report what will happen
if [ -n "$SKIP" ]; then
    echo "Already linked (skip):"
    for f in $SKIP; do echo "    $f"; done
    echo ""
fi

if [ -n "$NEW" ]; then
    echo "New (create):"
    for f in $NEW; do echo "    $f"; done
    echo ""
fi

if [ -n "$OVERWRITE" ]; then
    echo "Exists (overwrite):"
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

# Create symlinks
for pair in $SYMLINKS; do
    src="$DIR/$(echo "$pair" | cut -d: -f1)"
    dst="$(echo "$pair" | cut -d: -f2)"

    # Skip already correct
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        continue
    fi

    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    ln -snf "$src" "$dst"
    echo "  $dst -> $src"
done

echo ""
echo "Done."
