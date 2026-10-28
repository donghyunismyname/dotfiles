# Registers the Task Scheduler task `pm2-ahk`: at logon, headless, it starts the scripts in ecosystem.config.cjs
# under pm2 (the global install, the same pm2 daemon as pm2-airi). Run from a normal (non-sandboxed) shell.
$ErrorActionPreference = 'Stop'
$node = (Get-Command node).Source
$pm2 = Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2'

$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\conhost.exe" `
  -Argument "--headless `"$node`" `"$pm2`" start ecosystem.config.cjs" -WorkingDirectory $PSScriptRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$trigger.Delay = 'PT10S'  # after pm2-airi has started the pm2 daemon, so the two tasks don't both spawn one
# Priority 4 is normal: a task's default (7) is below normal, which pm2 and every app it starts inherit.
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -StartWhenAvailable -Priority 4
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

Register-ScheduledTask -TaskName 'pm2-ahk' -Force -Action $action -Trigger $trigger -Settings $settings `
  -Principal $principal -Description "dotfiles: start the AutoHotkey scripts under pm2 ($PSScriptRoot\ecosystem.config.cjs)" | Out-Null
Start-ScheduledTask -TaskName 'pm2-ahk'
Start-Sleep -Seconds 5
& $node $pm2 ls
