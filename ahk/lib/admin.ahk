; Included first by each script: run elevated, as the only instance of the including script.
; Single-instance is handled here: a non-admin instance cannot close an elevated one,
; so #SingleInstance Force would get stuck asking whether to keep waiting.
#SingleInstance Off

; Relaunch elevated so admin windows (e.g. an elevated terminal) are reachable too.
; If the UAC prompt is declined, keep running without admin; /restart prevents a relaunch loop.
if !A_IsAdmin && !InStr(DllCall("GetCommandLine", "str"), " /restart") {
    try {
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp()
    }
}

; Replace any older instance of this script.
DetectHiddenWindows(true)
for hwnd in WinGetList(A_ScriptFullPath " - AutoHotkey ahk_class AutoHotkey")
    if (pid := WinGetPID(hwnd)) != ProcessExist()
        try ProcessClose(pid)
DetectHiddenWindows(false)
