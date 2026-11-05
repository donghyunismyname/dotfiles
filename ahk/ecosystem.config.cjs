// The AutoHotkey scripts, under pm2 in the namespace `ahk`: `pm2 ls`, `pm2 restart ahk-panes` after editing one,
// and `pm2 restart ahk` / `pm2 stop ahk` for all of them at once.
// Started at logon by the pm2 logon task (windows/install-pm2.ps1), which install-pm2.ps1 adds this file to.
// They run without admin rights, so they can't reach elevated windows (an admin terminal, Task Manager).
const { join } = require("node:path");

const AUTOHOTKEY = join(process.env.LOCALAPPDATA, "Programs/AutoHotkey/v2/AutoHotkey64.exe");
const SCRIPTS = { panes: "panes/main.ahk", ime: "ime/main.ahk", keyboard: "keyboard/main.ahk" }; // name -> entry script

module.exports = {
  apps: Object.entries(SCRIPTS).map(([name, script]) => ({
    name: `ahk-${name}`,
    namespace: "ahk",
    cwd: __dirname,
    script: AUTOHOTKEY,
    args: script,
    interpreter: "none",
    autorestart: true,
    restart_delay: 5_000,
  })),
};
