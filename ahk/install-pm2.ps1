# Adds ecosystem.config.cjs to the ecosystem files the pm2 logon task starts (windows/install-pm2.ps1, run that
# first) and starts it now. Removes the old task `pm2-ahk`, which started it itself. Run from a normal
# (non-sandboxed) shell: ecosystem.config.cjs reads LOCALAPPDATA.
$ErrorActionPreference = 'Stop'
$file = "$PSScriptRoot\ecosystem.config.cjs"
$list = "$HOME\.pm2\ecosystems.txt"
if (-not ((Get-Content $list -ErrorAction SilentlyContinue) -contains $file)) { Add-Content $list $file }

if (Get-ScheduledTask -TaskName 'pm2-ahk' -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName 'pm2-ahk' -Confirm:$false
}
$pm2 = Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2'
& node $pm2 start $file
