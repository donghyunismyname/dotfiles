# Windows

Run the `.sh` scripts from Git Bash. They copy files instead of symlinking,
since symlinks need admin rights or developer mode on Windows.

| Path | What | Apply |
| ---- | ---- | ----- |
| `install-tools.ps1` | CLI tools via Scoop (counterpart of `../install-tools.sh`) | `.\install-tools.ps1` in PowerShell |
| `git.sh` | Makes `~/.gitconfig` include `../git/config` | `sh git.sh` |
| `vim.sh` | Copies `../vim` to `~/.config/vim` and `~/.vimrc` | `sh vim.sh` |
| `terminal.sh`, `terminal/` | Windows Terminal `settings.json` | `sh terminal.sh` (repo → app), `sh terminal.sh backup` (app → repo) |
| `keyboard/` | Key remaps via the registry `Scancode Map` | Double-click a `.reg`, then reboot |
| `wsl/.wslconfig` | WSL2 memory limit | Copy to `%USERPROFILE%\.wslconfig`, then `wsl --shutdown` |
| `wsl/sshserver.ps1` | Starts sshd in WSL and forwards Windows port 2222 to it | Copy to Desktop |
| `wsl/startup.cmd` | Runs `sshserver.ps1` from Desktop at login | Put in `shell:startup` |

## keyboard/

- `remap.reg`: LCtrl → Esc, CapsLock → LCtrl, ScrollLock → CapsLock, RWin → Volume Down, Menu → Volume Up
- `volume.reg`: only the two volume keys
- `reset.reg`: removes all remaps

Key codes and references are in the comments of `remap.reg`.
