# Run at logon by the task `pm2` (install-pm2.ps1): starts each ecosystem file listed in ~\.pm2\ecosystems.txt,
# one after another, so only the first spawns the pm2 daemon. Not `pm2 resurrect`: that brings back the apps
# saved as stopped, run-once ones included, stopped, and they are meant to run at logon.
$pm2 = Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2'
foreach ($file in Get-Content "$HOME\.pm2\ecosystems.txt" -ErrorAction SilentlyContinue) {
  if ($file -and (Test-Path $file)) { & node $pm2 start $file }
}
