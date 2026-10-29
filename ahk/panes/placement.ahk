; Plans for putting windows in panes, and carrying them out. A plan is an array of moves, the window
; being placed first: {hwnd, rect, pane, maximize}, where pane is the one rect fills or "", and rect ""
; minimizes the window. A plan is worked out apart from carrying it out, so a preview (ShowPlan) shows
; exactly what will happen.

Move(hwnd, rect, pane := "", maximize := false) => {hwnd: hwnd, rect: rect, pane: pane, maximize: maximize}
MoveToPane(hwnd, p) => Move(hwnd, PaneRect(p), p)

; The layout: {grids, stack: app windows topmost first, panes: window -> the pane it is in, firm:
; windows in the pane they want, claimed: the cells of those}. Windows are claimed top-down, so of two
; windows wanting the same cells only the higher one is firm.
Snapshot() {
    grids := MonitorGrids(), stack := Windows(), panes := Map(), firm := Map(), claimed := Map()
    for hwnd in stack
        try {
            if !(p := CurrentPane(hwnd, grids))
                continue
            panes[hwnd] := p
            if (wanted := Want(hwnd, grids)) && PaneKey(wanted) = PaneKey(p) && IsFree(p, claimed)
                firm[hwnd] := true, Take(claimed, p)
        }
    return {grids: grids, stack: stack, panes: panes, firm: firm, claimed: claimed}
}

; The pane the window is in: the one its frame fills, or the one the script put it in while its top-left
; corner is still there. "" when it is minimized, maximized or otherwise off the grid.
CurrentPane(hwnd, grids) {
    if WinGetMinMax(hwnd) != 0
        return ""
    f := FrameRect(hwnd)
    if p := RectPane(f, grids)
        return p
    p := PlacedAt(hwnd, grids)
    return p && Abs((r := PaneRect(p)).x - f.x) <= MATCH_TOLERANCE && Abs(r.y - f.y) <= MATCH_TOLERANCE ? p : ""
}

; The pane the window fills, or for a minimized one would fill when restored; "" when off the grid.
FilledPane(hwnd, grids) {
    switch WinGetMinMax(hwnd) {
        case 0: return RectPane(FrameRect(hwnd), grids)
        case -1: return (f := NormalFrame(hwnd)) ? RectPane(f, grids) : ""
    }
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
            plan.Push((free := TakeFree(snap.grids, taken, PaneRows(q), PaneCols(q))) ? MoveToPane(w, free) : Move(w, ""))
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

; Carries out the plan, the placed window last so it ends on top. A plan the user made also sets where
; that window wants to be, and activates it. A window minimized to make room is marked, so Settle brings
; it back.
ApplyPlan(plan, byUser := false) {
    try {
        loop plan.Length {
            m := plan[plan.Length - A_Index + 1]
            if !m.rect {
                SetEvicted(m.hwnd, true), WinMinimize(m.hwnd)
                continue
            }
            MoveTo(m.hwnd, m.rect, byUser)
            if m.maximize
                WinMaximize(m.hwnd)
            SetPlacedAt(m.hwnd, m.pane)
        }
        if byUser && plan.Length
            SetWant(plan[1].hwnd, plan[1].pane), WinActivate(plan[1].hwnd)
    } catch as e {
        TrayTip("Could not move the windows`n" e.Message, "panes")
    }
    ScheduleSettle()
}
