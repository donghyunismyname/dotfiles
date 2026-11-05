# Run at logon by the task `pm2` (install-pm2.ps1): brings back the apps of the last `pm2 save`. Resurrect leaves
# the apps saved as stopped stopped, and that includes the run-once apps on a cron schedule (autorestart off,
# cron_restart) once they have finished; those also run once here, to catch up on a run missed while the PC was off.
$pm2 = Join-Path $env:APPDATA 'npm\node_modules\pm2\bin\pm2'
& node $pm2 resurrect
# Single quotes only: Windows PowerShell drops the double quotes inside an argument it passes to a program.
$cronOnly = node -e @'
const list = require('child_process').execFileSync(process.execPath, [process.argv[1], 'jlist'], { maxBuffer: 1e8 });
for (const { name, pm2_env: e } of JSON.parse(list))
  if (e.status === 'stopped' && e.autorestart === false && e.cron_restart) console.log(name);
'@ $pm2
foreach ($name in $cronOnly) { & node $pm2 restart $name }
