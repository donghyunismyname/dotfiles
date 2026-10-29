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

frameInsets := Map()  ; hwnd -> widths of its invisible resize borders, see FrameRect

; Visible frame, without the invisible resize borders that WinGetPos includes. The border widths are
; remembered while the window is shown normally, since a minimized window has no frame to measure.
FrameRect(hwnd) {
    WinGetPos(&x, &y, &w, &h, hwnd)
    buf := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", buf, "uint", 16)
        return {x: x, y: y, w: w, h: h}
    l := NumGet(buf, 0, "int"), t := NumGet(buf, 4, "int"), r := NumGet(buf, 8, "int"), b := NumGet(buf, 12, "int")
    if WinGetMinMax(hwnd) = 0
        frameInsets[hwnd] := {l: l - x, t: t - y, r: x + w - r, b: y + h - b}
    return {x: l, y: t, w: r - l, h: b - t}
}

; Moves the window so its visible frame fills r. A minimized or maximized window is restored straight
; into r, so the restore animation ends there.
MoveTo(hwnd, r) {
    if WinGetMinMax(hwnd) != 0 && !SetNormalRect(hwnd, r, 9)  ; SW_RESTORE
        WinRestore(hwnd)
    WinGetPos(&x, &y, &w, &h, hwnd)
    f := FrameRect(hwnd)
    WinMove(r.x - (f.x - x), r.y - (f.y - y), r.w + (w - f.w), r.h + (h - f.h), hwnd)
}

; Sets where the window goes when restored to normal (its visible frame filling r), then shows it
; with showCmd. Needs the border widths FrameRect remembered; returns false without them.
SetNormalRect(hwnd, r, showCmd) {
    if !(i := frameInsets.Get(hwnd, ""))
        return false
    WorkspaceOffset(&dx, &dy)
    wp := Placement(hwnd)
    NumPut("uint", 0, "uint", showCmd, wp, 4)  ; flags 0: restore to normal, not maximized
    NumPut("int", r.x - i.l - dx, "int", r.y - i.t - dy, "int", r.x + r.w + i.r - dx, "int", r.y + r.h + i.b - dy, wp, 28)
    return DllCall("SetWindowPlacement", "ptr", hwnd, "ptr", wp)
}

; The visible frame a minimized window gets when restored, or "" when it is restored maximized.
NormalFrame(hwnd) {
    wp := Placement(hwnd)
    if NumGet(wp, 4, "uint") & 2  ; WPF_RESTORETOMAXIMIZED
        return ""
    WorkspaceOffset(&dx, &dy)
    i := frameInsets.Get(hwnd, {l: 0, t: 0, r: 0, b: 0})  ; without them, MATCH_TOLERANCE covers the borders
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
