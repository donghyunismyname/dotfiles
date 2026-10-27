#!/bin/sh
# Run from Git Bash. Makes ~/.gitconfig load ../git/config, the same stub as
# install-configs.sh. Machine-specific settings (user, credentials) stay in
# ~/.gitconfig below the include line, so they override the repo.

# pwd -W gives C:/... ; Git for Windows does not resolve /c/... include paths
DIR="$(cd "$(dirname "$0")/.." && pwd -W)"
CONF="$HOME/.gitconfig"

grep -qF "$DIR/git/config" "$CONF" 2>/dev/null && exit 0

touch "$CONF"
printf '[include]\n\tpath = %s\n' "$DIR/git/config" | cat - "$CONF" > "$CONF.tmp"
mv "$CONF.tmp" "$CONF"
echo "  $CONF -> $DIR/git/config"
