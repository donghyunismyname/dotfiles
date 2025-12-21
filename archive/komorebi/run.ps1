set WHKD_CONFIG_HOME="$Env:USERPROFILE/dotfiles/komorebi"
komorebic stop
komorebic start -c "$Env:USERPROFILE/dotfiles/komorebi/komorebi.json" --whkd