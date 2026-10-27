# Install CLI tools with Scoop (Windows counterpart of ../install-tools.sh).
# Run from PowerShell: .\install-tools.ps1
# On a fresh PC, allow local scripts first (Scoop needs this too):
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Not installed, no Windows build: tmux, sesh, timg, trash-cli.
# gdu stands in for ncdu; btop is the btop4win port.

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "=== Installing Scoop ==="
    Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
}

# lazygit lives in the extras bucket
if (-not (scoop bucket list | Where-Object Name -eq extras)) {
    scoop bucket add extras
}

Write-Host "`n=== Installing CLI tools ==="
scoop install neovim bat ripgrep fd delta eza zoxide btop dust gdu duf procs witr `
    lazygit lazydocker tokei miniserve fzf jq uv direnv chafa yazi broot

Write-Host "`n=== Verifying installation ==="
$cmds = 'nvim bat rg fd delta eza zoxide btop dust gdu duf procs witr lazygit lazydocker tokei miniserve fzf jq uv direnv chafa yazi broot' -split ' '
$failed = $cmds | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

if ($failed) {
    Write-Host "Failed to install: $($failed -join ' ')"
    exit 1
}
Write-Host "All tools installed successfully!"
