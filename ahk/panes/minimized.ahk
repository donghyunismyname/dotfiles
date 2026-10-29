; Minimized windows. Each remembers its home, the pane it was minimized from, and after every layout
; change (see UpdateMinimized):
; - a window the script minimized to make room comes back by itself, without taking the focus, once
;   its home or a free pane of that size is free again
; - any other is aimed at where it will come back, so it is restored straight there.

minimized := Map()  ; minimized window -> {home: pane or "", aim: PaneKey or "", evicted: A_TickCount or 0}

MinimizeToMakeRoom(hwnd, home) {
    minimized[hwnd] := {home: home, aim: "", evicted: A_TickCount}
    WinMinimize(hwnd)
}

; Once the layout has settled.
ScheduleMinimized() => SetTimer(UpdateMinimized, -LAYOUT_SETTLE_MS)

; Windows minimized to make room claim free panes first, the earliest first; the rest follow in z-order.
; One of those is aimed at its home when free, else at the first free pane of its size, else the first
; free cell; with no cell free it is left as it is, and PlanArrived makes room when it comes back.
UpdateMinimized() {
    snap := Snapshot(), taken := TakenCells(snap, [])
    for hwnd in MinimizedInTurn(snap.grids)
        try {
            m := minimized[hwnd], rows := PaneRows(m.home), cols := PaneCols(m.home)
            if IsFree(m.home, taken)
                p := m.home
            else if m.evicted  ; comes back only at its own size
                p := FirstFree(snap.grids, taken, rows, cols)
            else
                p := FirstFree(snap.grids, taken, rows, cols) || FirstFree(snap.grids, taken, 1, 1)
            if !p
                continue
            Take(taken, p)
            placed[hwnd] := p  ; so it counts as in p when back, even if its minimum size overflows p
            if m.evicted
                SetNormalRect(hwnd, PaneRect(p), 4)  ; SW_SHOWNOACTIVATE: restore without the focus
            else if m.aim != PaneKey(p) && SetNormalRect(hwnd, PaneRect(p), 7)  ; SW_SHOWMINNOACTIVE: stay minimized
                m.aim := PaneKey(p)
        }
}

; The minimized windows with a home: those minimized to make room first, the earliest first, then the
; others in z-order. A window seen minimized for the first time gets its home from its restore position,
; before that is aimed elsewhere.
MinimizedInTurn(grids) {
    evicted := [], others := []
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) != -1
                continue
            if !minimized.Has(hwnd)
                minimized[hwnd] := {home: (f := NormalFrame(hwnd)) ? FramePane(hwnd, f, grids) : "", aim: "", evicted: 0}
            m := minimized[hwnd]
            if !m.home
                continue
            if !m.evicted {
                others.Push(hwnd)
                continue
            }
            i := evicted.Length + 1
            while i > 1 && minimized[evicted[i - 1]].evicted > m.evicted
                i--
            evicted.InsertAt(i, hwnd)
        }
    evicted.Push(others*)
    return evicted
}
