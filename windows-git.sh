# Force pull --ff-only and merge --ff-only
git config --global pull.ff only
git config --global merge.ff only

# git status opens in less
git config --global pager.status false

# git default editor vim
git config --global core.editor "vim"


# git log made pretty
git config --global log.date short
git config --global format.pretty "format:%C(auto)%h %C(green)%ad %C(white)%s%C(auto)%d"


# git diff pretty
git config --global core.pager "less --tabs=4"
git config --global interactive.diffFilter "diff-so-fancy --patch"

git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"

git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.func       "146 bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"


