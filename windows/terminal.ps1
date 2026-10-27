# Copies Windows Terminal settings.json between the repo and the app.
# Copies instead of symlinking: Terminal rewrites the file on GUI saves.
#   .\terminal.ps1          # repo -> app
#   .\terminal.ps1 backup   # app -> repo

$repo = "$PSScriptRoot\terminal\settings.json"
$app = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if ($args[0] -eq 'backup') {
    Copy-Item $app $repo
} else {
    New-Item -ItemType Directory -Force (Split-Path $app) | Out-Null
    if (Test-Path $app) { Copy-Item $app "$app.bak" }
    Copy-Item $repo $app
}
