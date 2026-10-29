; Fitting windows to panes, and moving the windows in the way out.

; Where the windows on the grid are: {grids, panes: window -> pane}.
Snapshot() {
    grids := MonitorGrids(), panes := Map()
    for hwnd in Windows()
        try {
            if p := PaneOf(hwnd, grids)
                panes[hwnd] := p
        }
    return {grids: grids, panes: panes}
}

; Cells taken by the panes of windows other than the given ones, as a map of CellKeys.
TakenCells(snap, except) {
    taken := Map()
    for hwnd, p in snap.panes
        if !HasItem(except, hwnd)
            for k in CellKeys(p)
                taken[k] := true
    return taken
}

HasItem(list, v) {
    for e in list
        if e = v
            return true
    return false
}

; Fits the window to pane p. The windows in the way move out:
; - when the window comes from a pane of p's shape apart from p, and they all lie inside p, they move
;   there keeping their places, so a layout swaps as a whole
; - when there is one and the window comes from a pane apart from p, it takes that pane
; - otherwise each, in cell order, goes to the first free pane of its size, else the first free cell,
;   else is minimized.
PlaceInPane(hwnd, p, snap := Snapshot()) {
    try {
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
                MoveTo(w, PaneRect(Pane(old.grid, old.r1 + q.r1 - p.r1, old.c1 + q.c1 - p.c1,
                    old.r1 + q.r2 - p.r1, old.c1 + q.c2 - p.c1)))
            }
        } else if apart && inWay.Length = 1 {
            MoveTo(inWay[1], PaneRect(old))
        } else {
            taken := TakenCells(snap, [hwnd, inWay*])
            for k in CellKeys(p)
                taken[k] := true
            for w in inWay
                MoveToFree(w, snap.panes[w], snap.grids, taken) || WinMinimize(w)
        }
        MoveTo(hwnd, PaneRect(p))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window`n" e.Message, "panes")
    }
}

; Moves the window to the first free pane the size of `size`, else the first free cell, and marks
; that pane taken. Returns false when no cell is free.
MoveToFree(hwnd, size, grids, taken) {
    if !(p := FirstFree(grids, taken, size.r2 - size.r1 + 1, size.c2 - size.c1 + 1)) && !(p := FirstFree(grids, taken, 1, 1))
        return false
    for k in CellKeys(p)
        taken[k] := true
    MoveTo(hwnd, PaneRect(p))
    return true
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

; Swaps two windows' places and sizes. A maximized one passes being maximized on to the other.
SwapWindows(a, b) {
    try {
        ra := FrameRect(a), rb := FrameRect(b), ma := WinGetMinMax(a), mb := WinGetMinMax(b)
        MoveTo(a, rb), MoveTo(b, ra)
        if mb = 1
            WinMaximize(a)
        if ma = 1
            WinMaximize(b)
        WinActivate(a)
    } catch as e {
        TrayTip("Could not swap the windows`n" e.Message, "panes")
    }
}

; Fits windows already close to a pane to it exactly, e.g. after MARGIN changed.
SnapToGrid() {
    grids := MonitorGrids()
    for hwnd in Windows()
        try {
            if p := PaneOf(hwnd, grids)
                MoveTo(hwnd, PaneRect(p))
        }
}

InRect(r, x, y) => x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
