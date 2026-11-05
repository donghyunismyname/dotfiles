# Sets up pm2, the process manager that dotfiles/ahk and other repos run their apps under: one daemon for the user
# (~/.pm2), started at logon by the Task Scheduler task `pm2`, which runs logon.ps1 (`pm2 resurrect`). A
# project adds its apps once with `pm2 start ecosystem.config.cjs` and `pm2 save`; this knows no project.
# Run from a normal (non-sandboxed) shell.
$ErrorActionPreference = 'Stop'
$PM2_VERSION = '7.0.4'  # what projects pin in their own devDependencies, so their pm2 commands match the daemon
$pm2 = Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2'
if (-not (Test-Path $pm2)) { npm install -g "pm2@$PM2_VERSION" }

$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\conhost.exe" -WorkingDirectory $PSScriptRoot `
  -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\logon.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
# Priority 4 is normal: a task's default (7) is below normal, which pm2 and every app it starts inherit.
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -StartWhenAvailable -Priority 4
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
Register-ScheduledTask -TaskName 'pm2' -Force -Action $action -Trigger $trigger -Settings $settings `
  -Principal $principal -Description "dotfiles: bring back the pm2 apps of the last pm2 save ($PSScriptRoot\logon.ps1)" | Out-Null

# Keeps the logs pm2 writes of each app's output small; a pm2 module, started with the daemon from then on.
if (-not (Test-Path "$HOME\.pm2\modules\pm2-logrotate")) { & node $pm2 install pm2-logrotate }
& node $pm2 set pm2-logrotate:max_size 10M
& node $pm2 set pm2-logrotate:retain 3
