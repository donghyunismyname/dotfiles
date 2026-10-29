; Plans for putting windows in panes, and carrying them out. A plan is an array of moves, the window
; being placed first: {hwnd, rect, pane, maximize}. rect "" minimizes the window, and pane is where it
; goes, or for a minimized one where it was. A plan is worked out apart from carrying it out, so a
; preview (ShowPlan) shows exactly what will happen.

placed := Map()  ; window -> the pane it was last put in

Move(hwnd, rect, pane := "", maximize := false) => {hwnd: hwnd, rect: rect, pane: pane, maximize: maximize}
MoveToPane(hwnd, p) => Move(hwnd, PaneRect(p), p)
MinimizeFrom(hwnd, p) => Move(hwnd, "", p)

; Where the windows on the grid are: {grids, panes: window -> pane}.
Snapshot() {
    grids := MonitorGrids(), panes := Map()
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) = 0 && (p := FramePane(hwnd, FrameRect(hwnd), grids))
                panes[hwnd] := p
        }
    return {grids: grids, panes: panes}
}

; The pane a window with that frame is in: the one the frame fills, or else the one the window was
; put in, as long as its top-left corner is still there; an app's minimum size can keep a window
; larger than its pane. "" when it is off the grid.
FramePane(hwnd, f, grids) {
    if p := RectPane(f, grids)
        return p
    if (p := placed.Get(hwnd, "")) && Abs((r := PaneRect(p)).x - f.x) <= MATCH_TOLERANCE && Abs(r.y - f.y) <= MATCH_TOLERANCE
        return p
    return ""
}

; Cells taken by the panes of windows other than the given ones, as a map of CellKeys.
TakenCells(snap, except) {
    taken := Map()
    for hwnd, p in snap.panes
        if !HasItem(except, hwnd)
            Take(taken, p)
    return taken
}

HasItem(list, v) {
    for e in list
        if e = v
            return true
    return false
}

; Puts the window in pane p. The windows in the way move out:
; - when the window comes from a pane of p's shape apart from p, and they all lie inside p, they move
;   there keeping their places, so a layout swaps as a whole
; - when there is one and the window comes from a pane apart from p, it takes that pane
; - otherwise each, in cell order, goes to the first free pane of its size, else the first free cell,
;   else is minimized.
PlanPane(hwnd, p, snap) {
    plan := [MoveToPane(hwnd, p)]
    old := snap.panes.Get(hwnd, "")
    inWay := []
    for w, q in snap.panes
        if w != hwnd && Overlaps(q, p)
            inWay.Push(w)
    SortByCell(inWay, snap.panes)
    apart := old && !Overlaps(old, p)
    if apart && SameShape(old, p) && AllInside(inWay, snap.panes, p) {
        for w in inWay {
            q := snap.panes[w]
            plan.Push(MoveToPane(w, Pane(old.grid, old.r1 + q.r1 - p.r1, old.c1 + q.c1 - p.c1,
                old.r1 + q.r2 - p.r1, old.c1 + q.c2 - p.c1)))
        }
    } else if apart && inWay.Length = 1 {
        plan.Push(MoveToPane(inWay[1], old))
    } else {
        taken := TakenCells(snap, [hwnd, inWay*])
        Take(taken, p)
        for w in inWay {
            q := snap.panes[w]
            plan.Push((free := TakeFree(snap.grids, taken, PaneRows(q), PaneCols(q))) ? MoveToPane(w, free) : MinimizeFrom(w, q))
        }
    }
    return plan
}

; Swaps two windows' places and sizes, and their panes; a maximized one passes being maximized on to
; the other.
PlanSwap(a, b, snap) => [Move(a, FrameRect(b), snap.panes.Get(b, ""), WinGetMinMax(b) = 1),
    Move(b, FrameRect(a), snap.panes.Get(a, ""), WinGetMinMax(a) = 1)]

; Drops the window at the point: over another app window the two swap, over the desktop the window
; goes to the cell there, and over anything else nothing happens.
PlanDrop(hwnd, x, y) {
    under := WindowAt(x, y)
    if under != hwnd && IsAppWindow(under)
        return PlanSwap(hwnd, under, Snapshot())
    if !IsDesktop(under)
        return []
    snap := Snapshot()
    return PlanPane(hwnd, CellAt(GridAt(snap.grids, x, y), x, y), snap)
}

AllInside(list, panes, p) {
    for w in list
        if !Inside(panes[w], p)
            return false
    return true
}

; Sorts the windows in place by the first cell of their panes.
SortByCell(list, panes) {
    loop list.Length - 1 {
        i := A_Index + 1, w := list[i]
        while i > 1 && CellOrder(panes[list[i - 1]]) > CellOrder(panes[w])
            list[i] := list[i - 1], i--
        list[i] := w
    }
}

; Carries out the plan, the placed window last so it ends on top, and activates it when asked.
; A window minimized to make room comes back once there is room again (see UpdateMinimized).
ApplyPlan(plan, activate := true) {
    try {
        loop plan.Length {
            m := plan[plan.Length - A_Index + 1]
            if !m.rect {
                MinimizeToMakeRoom(m.hwnd, m.pane)
                continue
            }
            MoveTo(m.hwnd, m.rect)
            if m.maximize
                WinMaximize(m.hwnd)
            if m.pane
                placed[m.hwnd] := m.pane
            else
                Forget(placed, m.hwnd)
        }
        if activate && plan.Length
            WinActivate(plan[1].hwnd)
    } catch as e {
        TrayTip("Could not move the windows`n" e.Message, "panes")
    }
    ScheduleMinimized()
}

; Fits windows already close to a pane to it exactly, e.g. after MARGIN changed.
SnapToGrid() {
    grids := MonitorGrids()
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) = 0 && (p := RectPane(FrameRect(hwnd), grids))
                MoveTo(hwnd, PaneRect(p))
        }
}

; Deletes the key; returns whether it was there.
Forget(dict, key) => dict.Has(key) && (dict.Delete(key), true)
