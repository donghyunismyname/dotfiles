; Windows that appear on their own go on the grid: ones restored from minimized, and newly opened app
; windows. Dialogs, popups and other owned or fixed-size windows stay where their app puts them.
; Minimized windows are kept aimed at where they will come back (see AimMinimized), so they are
; restored straight there.

newWindows := Map()  ; top-level windows created but not shown yet
lastActive := Map()  ; window -> A_TickCount when it last became active
minimized := Map()   ; minimized window -> {home: the pane it was minimized from or "", aim: PaneKey}

StartAutoPlace() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND], OnMinimizeEvent)
    HookWinEvents([EVENT_SYSTEM_MOVESIZEEND], (*) => ScheduleAim())  ; moved or resized by hand
    HookWinEvents([EVENT_SYSTEM_FOREGROUND], (event, hwnd, *) => lastActive[hwnd] := A_TickCount)
    HookWinEvents([EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY, EVENT_OBJECT_SHOW], OnWindowLifecycle)
    AimMinimized()
}

OnMinimizeEvent(event, hwnd, *) {
    if event = EVENT_SYSTEM_MINIMIZESTART
        return ScheduleAim()
    Forget(minimized, hwnd)
    SetTimer(PlaceArrived.Bind(hwnd, false), -RESTORE_DELAY_MS)
}

; A window is new when it is shown for the first time after being created; a hidden window shown
; again (e.g. an app coming back from the tray) is not.
OnWindowLifecycle(event, hwnd, idObject) {
    if idObject != OBJID_WINDOW
        return
    if event = EVENT_OBJECT_DESTROY {
        wasActive := Forget(lastActive, hwnd)
        if Forget(minimized, hwnd) || wasActive
            ScheduleAim()  ; an app window closed, so its pane is free now
    }
    if event = EVENT_OBJECT_CREATE {
        if DllCall("GetAncestor", "ptr", hwnd, "uint", 1, "ptr") = DllCall("GetDesktopWindow", "ptr")  ; GA_PARENT: top-level
            newWindows[hwnd] := true
    } else if newWindows.Has(hwnd) {
        newWindows.Delete(hwnd)
        if event = EVENT_OBJECT_SHOW
            SetTimer(PlaceNew.Bind(hwnd), -NEW_WINDOW_DELAY_MS)
    }
}

; Deletes the key; returns whether it was there.
Forget(dict, key) => dict.Has(key) && (dict.Delete(key), true)

PlaceNew(hwnd) {
    try {
        if WinGetStyle(hwnd) & 0x40000  ; WS_THICKFRAME: resizable
            PlaceArrived(hwnd, true)
    }
}

PlaceArrived(hwnd, isNew) {
    try {
        if IsAppWindow(hwnd) && WinGetMinMax(hwnd) != -1
            ApplyPlan(PlanArrived(hwnd, isNew, Snapshot()), false)
    }
}

; A restored window comes back where it was aimed, and stays when that pane is free; one off the grid
; (maximized or another size) stays as it is. Otherwise the window goes to the first free pane of its
; size, a new window to the first free cell. With no cell free, it takes the pane of the least
; recently active window, which is minimized.
PlanArrived(hwnd, isNew, snap) {
    p := snap.panes.Get(hwnd, "")
    if !p && !isNew
        return []
    taken := TakenCells(snap, [hwnd])
    if p && IsFree(p, taken)
        return []
    if q := p ? TakeFree(snap.grids, taken, PaneRows(p), PaneCols(p)) : TakeFree(snap.grids, taken)
        return [Move(hwnd, PaneRect(q))]
    if v := LeastRecent(snap, hwnd)
        return [Move(hwnd, PaneRect(snap.panes[v])), Move(v, "")]
    return []
}

LeastRecent(snap, except) {
    least := 0
    for w in snap.panes
        if w != except && (!least || lastActive.Get(w, 0) < lastActive.Get(least, 0))
            least := w
    return least
}

; After the layout changes, once it has settled.
ScheduleAim() => SetTimer(AimMinimized, -AIM_DELAY_MS)

; Points each minimized window's restore position at its home when that is free, else at the first
; free pane of its size, else the first free cell, so it comes back where PlanArrived would put it.
; With no cell free it is left as it is, and PlanArrived makes room when it comes back. The home is
; read from the restore position before that is first aimed elsewhere; minimized windows earlier in
; z-order get their pick first.
AimMinimized() {
    snap := Snapshot(), taken := TakenCells(snap, [])
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) != -1
                continue
            if !minimized.Has(hwnd)
                minimized[hwnd] := {home: (f := NormalFrame(hwnd)) ? RectPane(f, snap.grids) : "", aim: ""}
            m := minimized[hwnd]
            if !m.home
                continue
            if IsFree(m.home, taken)
                Take(taken, p := m.home)
            else if !(p := TakeFree(snap.grids, taken, PaneRows(m.home), PaneCols(m.home)))
                continue
            if m.aim != PaneKey(p) && SetNormalRect(hwnd, PaneRect(p), 7)  ; SW_SHOWMINNOACTIVE: stay minimized
                m.aim := PaneKey(p)
        }
}
