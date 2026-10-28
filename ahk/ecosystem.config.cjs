// The AutoHotkey scripts, under pm2 in the namespace `ahk`: `pm2 ls`, `pm2 restart ahk-zones` after editing one,
// and `pm2 restart ahk` / `pm2 stop ahk` for all of them at once.
// Started at logon by the Task Scheduler task `pm2-ahk` (install-pm2-task.ps1). They run without admin rights, so
// they can't reach elevated windows (an admin terminal, Task Manager).
const { join } = require("node:path");

const AUTOHOTKEY = join(process.env.LOCALAPPDATA, "Programs/AutoHotkey/v2/AutoHotkey64.exe");
const SCRIPTS = ["zones", "ime"];

module.exports = {
  apps: SCRIPTS.map((script) => ({
    name: `ahk-${script}`,
    namespace: "ahk",
    cwd: __dirname,
    script: AUTOHOTKEY,
    args: `${script}.ahk`,
    interpreter: "none",
    autorestart: true,
    restart_delay: 5_000,
  })),
};
