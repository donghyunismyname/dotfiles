#!/bin/sh
# List files under $HOME, recently modified first, for fzf's CTRL-T.
# Exact mtime sorting (rg --sortr modified) takes minutes over home on
# Windows, so emit coarse age buckets and drop the repeats instead.

ignore="$(dirname "$0")/fzf-home.ignore"
for age in 1d 7d 30d ''; do
  fd --type f --hidden --ignore-file "$ignore" ${age:+--changed-within "$age"} . "$HOME"
done 2>/dev/null | awk '!seen[$0]++'
