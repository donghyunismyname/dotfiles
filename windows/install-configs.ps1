# Copy or stub configs (Windows counterpart of ../install-configs.sh).
# Copies instead of symlinking, since symlinks need admin rights or developer
# mode; re-run after changing vim/, yazi/ or zsh/zshenv in the repo.
# Run from PowerShell: .\install-configs.ps1

$repo = Split-Path $PSScriptRoot
$repoWin = $repo -replace '\\', '/'                                        # C:/Users/... for git
$repoMsys = '/' + $repoWin.Substring(0, 1).ToLower() + $repoWin.Substring(2) # /c/Users/... for zsh

# Copies: the repo owns these files, so overwrite whatever is there.
function Copy-Config($src, $dst) {
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse "$repo\$src" $dst
    Write-Host "  $dst <- $src"
}

# Stubs: a machine-owned file whose first lines load the repo config. Tools that
# append to it (git config --global, installers) never touch the repo, and what
# they append comes after the load line, so it overrides.
function Add-Stub($file, $load) {
    $text = if (Test-Path $file) { [IO.File]::ReadAllText($file) } else { '' }
    if ($text.Contains($load)) { return }
    [IO.File]::WriteAllText($file, "$load`n$text")
    Write-Host "  $file -> stub"
}

# Old layout: ~/.vim is in the default runtimepath and would load stale plugins
if (Test-Path "$HOME\.vim") {
    if (Test-Path "$HOME\.vim.bak") { Remove-Item -Recurse -Force "$HOME\.vim.bak" }
    Move-Item "$HOME\.vim" "$HOME\.vim.bak"
}

Copy-Config vim "$HOME\.config\vim"
Copy-Config vim\vimrc "$HOME\.vimrc"
Copy-Config yazi "$env:APPDATA\yazi\config"
Copy-Config zsh\zshenv "$HOME\.zshenv"

Add-Stub "$HOME\.zshrc" "source $repoMsys/zsh/zshrc"
# Git for Windows ignores /c/... include paths, so use C:/...
Add-Stub "$HOME\.gitconfig" "[include]`n`tpath = $repoWin/git/config"
exit 0
