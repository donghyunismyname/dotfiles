; Windows that appear on their own go on the grid: ones restored from minimized, and newly opened app
; windows. Dialogs, popups and other owned or fixed-size windows stay where their app puts them.

newWindows := Map()  ; top-level windows created but not shown yet
lastActive := Map()  ; window -> A_TickCount when it last became active

StartAutoPlace() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND], OnMinimizeEvent)
    HookWinEvents([EVENT_SYSTEM_MOVESIZEEND], (*) => ScheduleMinimized())  ; moved or resized by hand
    HookWinEvents([EVENT_SYSTEM_FOREGROUND], (event, hwnd, *) => lastActive[hwnd] := A_TickCount)
    HookWinEvents([EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY, EVENT_OBJECT_SHOW], OnWindowLifecycle)
    UpdateMinimized()
}

OnMinimizeEvent(event, hwnd, *) {
    if event = EVENT_SYSTEM_MINIMIZESTART
        return ScheduleMinimized()
    Forget(minimized, hwnd)
    SetTimer(PlaceArrived.Bind(hwnd, false), -RESTORE_DELAY_MS)
}

; A window is new when it is shown for the first time after being created; a hidden window shown
; again (e.g. an app coming back from the tray) is not.
OnWindowLifecycle(event, hwnd, idObject) {
    if idObject != OBJID_WINDOW
        return
    if event = EVENT_OBJECT_DESTROY {
        Forget(placed, hwnd)
        wasActive := Forget(lastActive, hwnd)
        if Forget(minimized, hwnd) || wasActive
            ScheduleMinimized()  ; an app window closed, so its pane is free now
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

; A restored window comes back where it was aimed (see UpdateMinimized), and stays when that pane is
; free; one off the grid (maximized or another size) stays as it is. Otherwise the window goes to the
; first free pane of its size, a new window to the first free cell. With no cell free, it takes the
; pane of the least recently active window, which is minimized to make room.
PlanArrived(hwnd, isNew, snap) {
    p := snap.panes.Get(hwnd, "")
    if !p && !isNew
        return []
    taken := TakenCells(snap, [hwnd])
    if p && IsFree(p, taken)
        return []
    if q := p ? TakeFree(snap.grids, taken, PaneRows(p), PaneCols(p)) : TakeFree(snap.grids, taken)
        return [MoveToPane(hwnd, q)]
    if v := LeastRecent(snap, hwnd)
        return [MoveToPane(hwnd, snap.panes[v]), MinimizeFrom(v, snap.panes[v])]
    return []
}

LeastRecent(snap, except) {
    least := 0
    for w in snap.panes
        if w != except && (!least || lastActive.Get(w, 0) < lastActive.Get(least, 0))
            least := w
    return least
}
