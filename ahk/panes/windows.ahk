; Top-level app windows: which ones count, and their visible frame.

; Top-level app windows in z-order, topmost first.
Windows() {
    list := []
    for hwnd in WinGetList()
        if IsAppWindow(hwnd)
            list.Push(hwnd)
    return list
}

IsAppWindow(hwnd) {
    try {
        if WinGetTitle(hwnd) = "" || WinGetPID(hwnd) = ProcessExist()
            return false
        if WinGetExStyle(hwnd) & 0x80 || DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")  ; tool window or owned window
            return false
        cloaked := 0  ; e.g. suspended UWP apps and windows on other virtual desktops
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4)
        return !cloaked && !IsDesktop(hwnd) && !(WinGetClass(hwnd) ~= "^Shell_(Secondary)?TrayWnd$")
    }
    return false
}

IsDesktop(hwnd) {
    try return WinGetClass(hwnd) ~= "^(Progman|WorkerW)$"
    return false
}

; The top-level window at the point. Click-through windows (the previews, the focus border) are skipped.
WindowAt(x, y) => DllCall("GetAncestor", "ptr", DllCall("WindowFromPoint", "int64", y << 32 | x & 0xFFFFFFFF, "ptr"), "uint", 2, "ptr")  ; GA_ROOT

; Visible frame, without the invisible resize borders that WinGetPos includes.
FrameRect(hwnd) {
    WinGetPos(&x, &y, &w, &h, hwnd)
    buf := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", buf, "uint", 16)
        return {x: x, y: y, w: w, h: h}
    l := NumGet(buf, 0, "int"), t := NumGet(buf, 4, "int"), r := NumGet(buf, 8, "int"), b := NumGet(buf, 12, "int")
    return {x: l, y: t, w: r - l, h: b - t}
}

; Widths of the invisible resize borders around the visible frame, which Windows counts as part of the
; window. Measured while the window is shown normally; otherwise those of a standard window at its DPI,
; which an app drawing its own frame may differ from by a few pixels (Settle fits it afterwards).
Insets(hwnd) {
    if WinGetMinMax(hwnd) = 0 {
        WinGetPos(&x, &y, &w, &h, hwnd), f := FrameRect(hwnd)
        return {l: f.x - x, t: f.y - y, r: x + w - f.x - f.w, b: y + h - f.y - f.h}
    }
    if !(WinGetStyle(hwnd) & 0x40000)  ; WS_THICKFRAME: no resize borders
        return {l: 0, t: 0, r: 0, b: 0}
    dpi := DllCall("GetDpiForWindow", "ptr", hwnd, "uint")
    ; SM_CXSIZEFRAME + SM_CXPADDEDBORDER, less the 1px border that is visible
    side := DllCall("GetSystemMetricsForDpi", "int", 32, "uint", dpi) + DllCall("GetSystemMetricsForDpi", "int", 92, "uint", dpi) - 1
    return {l: side, t: 0, r: side, b: side}
}

; Moves the window so its visible frame fills r. A minimized or maximized window is restored straight
; into r, so the restore animation ends there, and activated only when asked.
MoveTo(hwnd, r, activate := true) {
    if WinGetMinMax(hwnd) != 0
        SetNormalRect(hwnd, r, activate ? 9 : 4)  ; SW_RESTORE, SW_SHOWNOACTIVATE
    i := Insets(hwnd)
    WinMove(r.x - i.l, r.y - i.t, r.w + i.l + i.r, r.h + i.t + i.b, hwnd)
}

; Sets where the window goes when restored to normal (its visible frame filling r), then shows it
; with showCmd.
SetNormalRect(hwnd, r, showCmd) {
    i := Insets(hwnd), wp := Placement(hwnd)
    WorkspaceOffset(&dx, &dy)
    NumPut("uint", 0, "uint", showCmd, wp, 4)  ; flags 0: restore to normal, not maximized
    NumPut("int", r.x - i.l - dx, "int", r.y - i.t - dy, "int", r.x + r.w + i.r - dx, "int", r.y + r.h + i.b - dy, wp, 28)
    return DllCall("SetWindowPlacement", "ptr", hwnd, "ptr", wp)
}

; The visible frame the window has when shown normally, neither minimized nor maximized.
NormalFrame(hwnd) {
    wp := Placement(hwnd), i := Insets(hwnd)
    WorkspaceOffset(&dx, &dy)
    x := NumGet(wp, 28, "int") + dx + i.l, y := NumGet(wp, 32, "int") + dy + i.t
    return {x: x, y: y, w: NumGet(wp, 36, "int") + dx - i.r - x, h: NumGet(wp, 40, "int") + dy - i.b - y}
}

Placement(hwnd) {
    wp := Buffer(44, 0)  ; WINDOWPLACEMENT
    NumPut("uint", 44, wp)
    DllCall("GetWindowPlacement", "ptr", hwnd, "ptr", wp)
    return wp
}

; A restore position is in workspace coordinates: relative to the primary monitor's work area.
WorkspaceOffset(&dx, &dy) {
    p := MonitorGetPrimary(), MonitorGet(p, &ml, &mt), MonitorGetWorkArea(p, &wl, &wt)
    dx := wl - ml, dy := wt - mt
}
