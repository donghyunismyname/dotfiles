#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  CHROME="google-chrome"
fi

"$CHROME" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/workspace/playwright" \
  --disable-backgrounding-occluded-windows \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --no-first-run \
  --no-default-browser-check \
  --disable-infobars \
  --disable-popup-blocking

