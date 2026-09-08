#!/bin/sh
# Run all install scripts in order. Stops at the first failure.
#
#   sh install.sh            # tools, shell, symlinks
#   sh install.sh --system   # also run install-system.sh (Linux servers, sudo)

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

STEPS="install-tools.sh install-shell.sh install-symlinks.sh"
[ "$1" = "--system" ] && STEPS="$STEPS install-system.sh"

for step in $STEPS; do
    echo ""
    echo "##### $step #####"
    sh "$DIR/$step"
done

echo ""
echo "✅ All done. Open a new shell to apply."
