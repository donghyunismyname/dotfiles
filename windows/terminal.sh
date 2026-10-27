#!/bin/sh
# Run from Git Bash. Copies Windows Terminal settings.json between the repo and
# the app. Copies instead of symlinking: Terminal rewrites the file on GUI saves.
#   sh terminal.sh          # repo -> app
#   sh terminal.sh backup   # app -> repo

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"

if [ "$1" = backup ]; then
    cp "$APP/settings.json" "$DIR/terminal/settings.json"
else
    mkdir -p "$APP"
    cp "$APP/settings.json" "$APP/settings.json.bak" 2>/dev/null
    cp "$DIR/terminal/settings.json" "$APP/settings.json"
fi
