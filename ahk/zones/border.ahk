; Focus border: four click-through bars just inside the active window's visible frame,
; moved on window events instead of polling.

StartBorder() {
    HookWinEvents([EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND,
        EVENT_OBJECT_LOCATIONCHANGE], OnBorderEvent)
    UpdateBorder()
}

; Location changes come from every window and the cursor; only the active window's own matter.
OnBorderEvent(event, hwnd, idObject) {
    if event != EVENT_OBJECT_LOCATIONCHANGE || idObject = OBJID_WINDOW && hwnd = DllCall("GetForegroundWindow", "ptr")
        SetTimer(UpdateBorder, -1)
}

UpdateBorder() {
    static bars := [], last := ""
    if !bars.Length
        loop 4
            bars.Push(ClickThroughGui(BORDER_COLOR))
    r := ""
    try {
        hwnd := WinExist("A")
        if hwnd && IsAppWindow(hwnd) && WinGetMinMax(hwnd) != -1
            r := FrameRect(hwnd)
    }
    key := r ? r.x "," r.y "," r.w "," r.h : ""
    if key = last
        return
    last := key
    if !r {
        for g in bars
            g.Hide()
        return
    }
    t := BORDER_WIDTH
    for i, b in [[r.x, r.y, r.w, t], [r.x, r.y + r.h - t, r.w, t], [r.x, r.y, t, r.h], [r.x + r.w - t, r.y, t, r.h]]
        bars[i].Show("NA x" b[1] " y" b[2] " w" b[3] " h" b[4])
}
