# Run at logon by the task `pm2-ahk` (install-pm2-task.ps1): starts the scripts in ecosystem.config.cjs under pm2.
# another project's task starts the pm2 daemon at the same logon, and when two pm2 commands both find no daemon, both spawn
# one and the loser hangs, so this waits for that daemon (up to a minute, then spawns one itself).
$deadline = (Get-Date).AddMinutes(1)
while (-not ([IO.Directory]::GetFiles('\\.\pipe\') -contains '\\.\pipe\rpc.sock') -and (Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 1
}
& (Get-Command node).Source (Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2') start "$PSScriptRoot\ecosystem.config.cjs"
