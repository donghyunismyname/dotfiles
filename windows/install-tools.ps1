# Install CLI tools with Scoop (Windows counterpart of ../install-tools.sh).
# Run from PowerShell: .\install-tools.ps1
# On a fresh PC, allow local scripts first (Scoop needs this too):
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Not installed, no Windows build: tmux, sesh, timg.
# gdu stands in for ncdu; btop is the btop4win port; trashy (`trash`) for
# trash-cli, sending files to the Windows Recycle Bin.
# vim comes from MSYS2 (install-shell.ps1) so it reads the same config as Unix.

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "=== Installing Scoop ==="
    Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
}

# Scoop needs git for buckets; skip if Git for Windows is already installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    scoop install git
}

# lazygit lives in the extras bucket
if (-not (scoop bucket list | Where-Object Name -eq extras)) {
    scoop bucket add extras
}

Write-Host "`n=== Installing CLI tools ==="
scoop install bat ripgrep fd delta eza zoxide btop dust gdu duf procs witr `
    lazygit lazydocker tokei miniserve fzf jq uv direnv chafa yazi broot trashy

# Nerd Font that terminal/settings.json uses; skip if already installed by
# hand (overwriting a font Terminal has open fails)
$fontKeys = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
            'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$hasFont = $fontKeys | ForEach-Object { (Get-ItemProperty $_ -ErrorAction SilentlyContinue).PSObject.Properties.Name } |
    Where-Object { $_ -like 'DroidSansM*Nerd*Font*Mono*' }
if (-not $hasFont) {
    Write-Host "`n=== Installing Nerd Font ==="
    if (-not (scoop bucket list | Where-Object Name -eq nerd-fonts)) {
        scoop bucket add nerd-fonts
    }
    scoop install DroidSansMono-NF-Mono
}

Write-Host "`n=== Verifying installation ==="
$cmds = 'bat rg fd delta eza zoxide btop dust gdu duf procs witr lazygit lazydocker tokei miniserve fzf jq uv direnv chafa yazi broot trash' -split ' '
$failed = $cmds | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

if ($failed) {
    Write-Host "Failed to install: $($failed -join ' ')"
    exit 1
}
Write-Host "All tools installed successfully!"
exit 0
