# Windows

Same layout as the top-level scripts, in PowerShell: CLI tools come from
Scoop, and zsh and vim from MSYS2, since zsh has no native Windows build.

## Quick Start

On a fresh PC, in a non-admin PowerShell (the Scoop installer refuses to run
elevated):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
scoop install git
git clone https://github.com/donghyunismyname/dotfiles ~/dotfiles
~/dotfiles/windows/install.ps1   # runs the three scripts below in order
```

Or run them individually:

```powershell
.\install-tools.ps1    # CLI tools (uses Scoop)
.\install-shell.ps1    # MSYS2, zsh, vim, zsh plugins
.\install-configs.ps1  # Copy vim, yazi, zshenv; stub ~/.zshrc and ~/.gitconfig
```

Configs are copied, not symlinked (symlinks need admin rights or developer
mode), so re-run `install-configs.ps1` after changing them in the repo.

## Other files

| Path | What | Apply |
| ---- | ---- | ----- |
| `terminal.ps1`, `terminal/` | Windows Terminal `settings.json`, including the "MSYS2 zsh" profile | `.\terminal.ps1` (repo → app), `.\terminal.ps1 backup` (app → repo) |
| `keyboard/` | Key remaps via the registry `Scancode Map` | Double-click a `.reg`, then reboot |
| `wsl/.wslconfig` | WSL2 memory limit | Copy to `%USERPROFILE%\.wslconfig`, then `wsl --shutdown` |
| `wsl/sshserver.ps1` | Starts sshd in WSL and forwards Windows port 2222 to it | Copy to Desktop |
| `wsl/startup.cmd` | Runs `sshserver.ps1` from Desktop at login | Put in `shell:startup` |

## keyboard/

- `remap.reg`: LCtrl → Esc, CapsLock → LCtrl, ScrollLock → CapsLock, RWin → Volume Down, Menu → Volume Up
- `volume.reg`: only the two volume keys
- `reset.reg`: removes all remaps

Key codes and references are in the comments of `remap.reg`.
