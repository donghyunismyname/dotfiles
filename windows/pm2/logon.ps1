# Run at logon by the task `pm2` (install.ps1): brings back the apps of the last `pm2 save`. Apps saved as stopped
# stay stopped, run-once apps on a cron schedule included; catching up on a run missed while the PC was off is up
# to each app.
& node (Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2') resurrect
