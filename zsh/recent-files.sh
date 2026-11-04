#!/bin/sh
# List files, recently modified first, for fzf's CTRL-T (current directory)
# and CTRL-G (home). Arguments go to fd, e.g. an ignore file and a root.
# Exact mtime sorting (rg --sortr modified) takes minutes over home on
# Windows, so emit coarse age buckets and drop the repeats instead.

for age in 1d 7d 30d ''; do
  fd --type f --hidden ${age:+--changed-within "$age"} "$@"
done 2>/dev/null | awk '!seen[$0]++'
