; Panes as screen rectangles, and moving windows into them.

restoring := 0  ; a minimized window Place is restoring, so autoplace doesn't move it to HOME_TILE

; Puts the window in the target pane, on top of the windows there. Moved from another tile, it swaps
; with the target tile's top window. A window that appeared on its own (auto) has no old tile, only
; where its app put it.
Place(hwnd, target, auto := false) {
    global restoring
    try {
        src := PaneOf(hwnd)
        if !auto && IsTile(src) && IsTile(target) && src != target && (other := TopWindowIn(target, hwnd))
            MoveTo(other, PaneRect(src))
        if WinGetMinMax(hwnd) = -1
            restoring := hwnd
        MoveTo(hwnd, PaneRect(target))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window`n" e.Message, "panes")
    }
}

; Fits the windows already in a pane to its current rectangle, e.g. after MARGIN changed.
; Maximized windows are left alone, though they match the whole-monitor panes.
SnapToPanes() {
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) = 0 && (z := PaneOf(hwnd))
                MoveTo(hwnd, PaneRect(z))
        }
}

IsTile(z) {
    for t in TILES
        if t == z
            return true
    return false
}

; Minimizes every window whose center is in the pane, so a whole-monitor pane clears that monitor.
MinimizePane(pane) {
    r := PaneRect(pane)
    for hwnd in Windows()
        try {
            f := FrameRect(hwnd)
            if InRect(r, f.x + f.w // 2, f.y + f.h // 2)
                WinMinimize(hwnd)
        }
}

; Smallest pane containing the point, so a half wins over the whole monitor around it.
PaneAt(x, y) {
    best := "", bestArea := 0
    for z in Connected(PANES) {
        r := PaneRect(z)
        if InRect(r, x, y) && (!best || r.w * r.h < bestArea)
            best := z, bestArea := r.w * r.h
    }
    return best
}

TopWindowIn(pane, exclude) {
    for hwnd in Windows()
        if hwnd != exclude && PaneOf(hwnd) == pane
            return hwnd
    return 0
}

PaneOf(hwnd) {
    f := FrameRect(hwnd)
    for z in Connected(PANES) {
        r := PaneRect(z)
        if Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE
            && Abs(f.w - r.w) <= MATCH_TOLERANCE && Abs(f.h - r.h) <= MATCH_TOLERANCE
            return z
    }
    return ""
}

; The panes whose monitor is connected.
Connected(panes) {
    list := []
    for z in panes
        if z.mon <= MonitorGetCount()
            list.Push(z)
    return list
}

; The pane's area of the work area, inset by MARGIN at the work area's edges and by half of it at an
; edge inside, which the neighboring pane insets by the other half.
PaneRect(z) {
    MonitorGetWorkArea(z.mon, &l, &t, &r, &b)
    x1 := l + Round(z.x * (r - l)), y1 := t + Round(z.y * (b - t))
    x2 := l + Round((z.x + z.w) * (r - l)), y2 := t + Round((z.y + z.h) * (b - t))
    half := MARGIN // 2
    x1 += (x1 = l ? MARGIN : half), y1 += (y1 = t ? MARGIN : half)
    x2 -= (x2 = r ? MARGIN : MARGIN - half), y2 -= (y2 = b ? MARGIN : MARGIN - half)
    return {x: x1, y: y1, w: x2 - x1, h: y2 - y1}
}

InRect(r, x, y) => x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
Encloses(a, b) => a.x <= b.x && a.y <= b.y && a.x + a.w >= b.x + b.w && a.y + a.h >= b.y + b.h
