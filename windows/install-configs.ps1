# Link or stub configs (Windows counterpart of ../install-configs.sh).
# Nothing is copied, so repo edits apply without re-running this script.
# Symlinks need admin rights or developer mode, so directories become
# junctions and single files become stubs.
# Run from PowerShell: .\install-configs.ps1

$repo = Split-Path $PSScriptRoot
$repoWin = $repo -replace '\\', '/'                                        # C:/Users/... for git
$repoMsys = '/' + $repoWin.Substring(0, 1).ToLower() + $repoWin.Substring(2) # /c/Users/... for zsh

# Junctions: a directory link that needs no admin rights. Directories only.
function Link-Config($src, $dst) {
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    $item = Get-Item $dst -Force -ErrorAction SilentlyContinue
    # Remove-Item -Recurse on a junction can delete the target's contents in
    # Windows PowerShell 5.1, so remove an existing link by itself
    if ($item.LinkType) { [IO.Directory]::Delete($dst) }
    elseif ($item) { Remove-Item -Recurse -Force $dst }
    New-Item -ItemType Junction -Path $dst -Target "$repo\$src" | Out-Null
    Write-Host "  $dst -> $src"
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

# Old layouts: ~/.vim is in the default runtimepath and would load stale
# plugins; ~/.vimrc and ~/.zshenv were full copies, which a stub would load twice
if (Test-Path "$HOME\.vim") {
    if (Test-Path "$HOME\.vim.bak") { Remove-Item -Recurse -Force "$HOME\.vim.bak" }
    Move-Item "$HOME\.vim" "$HOME\.vim.bak"
}
foreach ($f in "$HOME\.vimrc", "$HOME\.zshenv") {
    if ((Test-Path $f) -and (Get-Content $f -TotalCount 1) -notlike 'source *') {
        Move-Item -Force $f "$f.bak"
    }
}

Link-Config vim "$HOME\.config\vim"
Link-Config yazi "$env:APPDATA\yazi\config"

Add-Stub "$HOME\.vimrc" "source ~/.config/vim/vimrc"
Add-Stub "$HOME\.zshenv" "source $repoMsys/zsh/zshenv"
Add-Stub "$HOME\.zshrc" "source $repoMsys/zsh/zshrc"
# Git for Windows ignores /c/... include paths, so use C:/...
Add-Stub "$HOME\.gitconfig" "[include]`n`tpath = $repoWin/git/config"
exit 0
