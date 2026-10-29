; Keeping windows where the user wants them. Every app window carries the pane it wants (props.ahk): the
; one the user last put it in, or for a new window the one it first got. After any change to the layout,
; once things are quiet, Settle moves windows back toward the panes they want.

StartSettle() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZEEND], (event, hwnd, idObject) => (SetEvicted(hwnd, false), ScheduleSettle()))
    HookWinEvents([EVENT_SYSTEM_MOVESIZEEND], (event, hwnd, idObject) => SetTimer(MovedByHand.Bind(hwnd), -1))
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART, EVENT_OBJECT_DESTROY], (event, hwnd, idObject) => idObject = OBJID_WINDOW && ScheduleSettle())
    HookWinEvents([EVENT_OBJECT_HIDE], (event, hwnd, idObject) => idObject = OBJID_WINDOW && IsKnown(hwnd) && ScheduleSettle())
    HookWinEvents([EVENT_OBJECT_SHOW], (event, hwnd, idObject) => idObject = OBJID_WINDOW && IsTopLevel(hwnd)
        && SetTimer(Shown.Bind(hwnd), -NEW_WINDOW_DELAY_MS))
    grids := MonitorGrids()
    for hwnd in Windows()  ; windows from before the script: where they are now is where they want to be
        try IsKnown(hwnd) || SetWant(hwnd, FilledPane(hwnd, grids))
    Settle()
}

IsTopLevel(hwnd) => DllCall("GetAncestor", "ptr", hwnd, "uint", 1, "ptr") = DllCall("GetDesktopWindow", "ptr")  ; GA_PARENT

ScheduleSettle() => SetTimer(Settle, -LAYOUT_SETTLE_MS)

; Moved or resized by hand: where it ends up is where it wants to be, on the grid or off it.
MovedByHand(hwnd) {
    try {
        if !IsAppWindow(hwnd)
            return
        p := FilledPane(hwnd, MonitorGrids())
        SetWant(hwnd, p), SetPlacedAt(hwnd, p)
        ScheduleSettle()
    }
}

; A window shown for the first time gets a pane; one shown again (e.g. back from the tray) may now be in
; another's way.
Shown(hwnd) {
    try {
        if !IsAppWindow(hwnd)
            return
        if !IsKnown(hwnd)
            PlaceNew(hwnd)
        ScheduleSettle()
    }
}

; A new app window goes to the first free cell, else takes the pane of the lowest window in z-order (the
; least recently active), which is minimized to make room. Fixed-size windows stay off the grid.
PlaceNew(hwnd) {
    snap := Snapshot()
    if WinGetMinMax(hwnd) = -1 || !(WinGetStyle(hwnd) & 0x40000)  ; WS_THICKFRAME: resizable
        || !(p := FirstFree(snap.grids, TakenCells(snap, [hwnd]), 1, 1) || LowestPane(snap, hwnd))
        return SetWant(hwnd, "")
    ApplyPlan(PlanPane(hwnd, p, snap))
    SetWant(hwnd, p)
}

LowestPane(snap, except) {
    loop snap.stack.Length {
        w := snap.stack[snap.stack.Length - A_Index + 1]
        if w != except && snap.panes.Has(w)
            return snap.panes[w]
    }
    return ""
}

; One step toward where windows want to be; a step that moves windows schedules the next. In turn:
; - windows a few pixels off their pane are fitted to it
; - a firm window (see Snapshot) pushes out the windows on its pane that are not firm, e.g. after it was
;   restored onto one moved there to make room
; - a window away from the pane it wants, or minimized to make room, goes back once no firm window is
;   there, topmost first
; - a window the user minimized is aimed at where it would come back
; Each step adds a firm window or clears one's pane, so the layout comes to rest.
Settle() {
    if right.held  ; mid-gesture; after it
        return ScheduleSettle()
    snap := Snapshot()
    FitToPanes(snap)
    if plan := ClearFirmPane(snap) || ReturnPlan(snap)
        return ApplyPlan(plan)
    AimMinimized(snap)
}

; Windows a few pixels off their pane, e.g. restored with a guessed border width, are fitted to it.
; Windows kept larger by an app's minimum size are left so.
FitToPanes(snap) {
    for hwnd, p in snap.panes
        try {
            f := FrameRect(hwnd), r := PaneRect(p)
            if f.x != r.x || f.y != r.y || f.w != r.w || f.h != r.h
                CloseTo(f, r) && MoveTo(hwnd, r, false)
        }
}

; A plan for the first firm window, topmost first, whose pane has other windows on it: pushing them out.
ClearFirmPane(snap) {
    for hwnd in snap.stack
        if snap.firm.Has(hwnd)
            for w, q in snap.panes
                if w != hwnd && Overlaps(q, snap.panes[hwnd])
                    return PlanPane(hwnd, snap.panes[hwnd], snap)
    return ""
}

; A plan for the first window, topmost first, that sits in a pane other than the one it wants, or is
; minimized to make room, and can go back: no firm window is on that pane. Windows off the grid are left
; be, so a window moved or snapped by other means is not pulled back.
ReturnPlan(snap) {
    for hwnd in snap.stack
        try {
            if snap.firm.Has(hwnd) || !(wanted := Want(hwnd, snap.grids)) || !IsFree(wanted, snap.claimed)
                continue
            if snap.panes.Has(hwnd) || WinGetMinMax(hwnd) = -1 && IsEvicted(hwnd)
                return PlanPane(hwnd, wanted, snap)
        }
    return ""
}

; Points the restore position of each window the user minimized at where it would come back: the pane it
; wants when no firm window is there, else the first free pane of that size, else the first free cell.
; With no cell free it is left be: restored onto a firm window's pane, it is the higher of the two and
; pushes that one out.
AimMinimized(snap) {
    taken := TakenCells(snap, [])
    for hwnd in snap.stack
        try {
            if WinGetMinMax(hwnd) != -1 || IsEvicted(hwnd) || !(wanted := Want(hwnd, snap.grids))
                continue
            if IsFree(wanted, snap.claimed)
                p := wanted
            else if !(p := FirstFree(snap.grids, taken, PaneRows(wanted), PaneCols(wanted)) || FirstFree(snap.grids, taken, 1, 1))
                continue
            Take(taken, p)
            if !((now := FilledPane(hwnd, snap.grids)) && PaneKey(now) = PaneKey(p))
                SetNormalRect(hwnd, PaneRect(p), 7), SetPlacedAt(hwnd, p)  ; SW_SHOWMINNOACTIVE: stay minimized
        }
}
