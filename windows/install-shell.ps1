# zsh on MSYS2 (Windows counterpart of ../install-shell.sh).
# zsh has no native Windows build, so it runs on MSYS2's POSIX layer. Only zsh
# and vim come from MSYS2's pacman; CLI tools stay native (install-tools.ps1).
# Run from PowerShell after install-tools.ps1: .\install-shell.ps1

if (-not (Get-Command msys2 -ErrorAction SilentlyContinue)) {
    scoop install msys2
}
$bash = "$(scoop prefix msys2)\usr\bin\bash.exe"

function Invoke-Msys($cmd) {
    & $bash -lc $cmd
    if ($LASTEXITCODE) { throw "MSYS2 command failed: $cmd" }
}

Write-Host "=== Updating MSYS2 ==="
# The first login shell initializes MSYS2 (keyring, /etc, skeleton home).
Invoke-Msys 'true'
# The first -Syu may only update the core runtime and then exit, so run it again.
& $bash -lc 'pacman -Syu --noconfirm'
Invoke-Msys 'pacman -Syu --noconfirm'

Write-Host "`n=== Installing zsh and vim ==="
Invoke-Msys 'pacman -S --needed --noconfirm zsh vim'

# Use the Windows home (C:\Users\<name>) instead of MSYS2's own, so zsh, vim
# and git share ~/.zshrc, ~/.vimrc, ~/.gitconfig and ~/.ssh with Windows.
Invoke-Msys "sed -i 's/^db_home:.*/db_home: windows/' /etc/nsswitch.conf"

Write-Host "`n=== Installing zsh plugins ==="
$plugins = "$HOME\.zsh\plugins"
foreach ($p in 'zsh-autosuggestions', 'zsh-syntax-highlighting') {
    $dir = "$plugins\$p"
    if (Test-Path $dir) {
        git -C $dir pull
    } else {
        # zsh fails on CRLF scripts, which core.autocrlf=true would produce
        git clone -c core.autocrlf=false "https://github.com/zsh-users/$p" $dir
    }
    if ($LASTEXITCODE) { throw "Failed to fetch $p" }
}
exit 0
