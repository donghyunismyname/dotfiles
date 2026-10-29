; Targets (panes and monitors) as screen rectangles, and moving windows into them.

restoring := 0  ; a minimized window Place is restoring, so autoplace doesn't move it to HOME_PANE

; Puts the window in the target, on top of the windows there. Moved from one pane to another, it
; swaps with that pane's top window. A window that appeared on its own (auto) has no old pane, only
; where its app put it.
Place(hwnd, target, auto := false) {
    global restoring
    try {
        src := TargetOf(hwnd)
        if !auto && IsPane(src) && IsPane(target) && src != target && (other := TopWindowIn(target, hwnd))
            MoveTo(other, TargetRect(src))
        if WinGetMinMax(hwnd) = -1
            restoring := hwnd
        MoveTo(hwnd, TargetRect(target))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window`n" e.Message, "panes")
    }
}

; Fits the windows already in a target to its current rectangle, e.g. after MARGIN changed.
; Maximized windows are left alone, though they match the monitor targets.
SnapToTargets() {
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) = 0 && (t := TargetOf(hwnd))
                MoveTo(hwnd, TargetRect(t))
        }
}

IsPane(t) {
    for p in PANES
        if p == t
            return true
    return false
}

; Minimizes every window whose center is in the target, so a monitor target clears that monitor.
MinimizeWindowsIn(target) {
    r := TargetRect(target)
    for hwnd in Windows()
        try {
            f := FrameRect(hwnd)
            if InRect(r, f.x + f.w // 2, f.y + f.h // 2)
                WinMinimize(hwnd)
        }
}

; Smallest target containing the point, so a pane wins over the monitor around it.
TargetAt(x, y) {
    best := "", bestArea := 0
    for t in Connected(TARGETS) {
        r := TargetRect(t)
        if InRect(r, x, y) && (!best || r.w * r.h < bestArea)
            best := t, bestArea := r.w * r.h
    }
    return best
}

TopWindowIn(target, exclude) {
    for hwnd in Windows()
        if hwnd != exclude && TargetOf(hwnd) == target
            return hwnd
    return 0
}

TargetOf(hwnd) {
    f := FrameRect(hwnd)
    for t in Connected(TARGETS) {
        r := TargetRect(t)
        if Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE
            && Abs(f.w - r.w) <= MATCH_TOLERANCE && Abs(f.h - r.h) <= MATCH_TOLERANCE
            return t
    }
    return ""
}

; The targets whose monitor is connected.
Connected(targets) {
    list := []
    for t in targets
        if t.mon <= MonitorGetCount()
            list.Push(t)
    return list
}

; The target's area of the work area, inset by MARGIN at the work area's edges and by half of it at an
; edge inside, which the neighboring target insets by the other half.
TargetRect(target) {
    MonitorGetWorkArea(target.mon, &l, &t, &r, &b)
    x1 := l + Round(target.x * (r - l)), y1 := t + Round(target.y * (b - t))
    x2 := l + Round((target.x + target.w) * (r - l)), y2 := t + Round((target.y + target.h) * (b - t))
    half := MARGIN // 2
    x1 += (x1 = l ? MARGIN : half), y1 += (y1 = t ? MARGIN : half)
    x2 -= (x2 = r ? MARGIN : MARGIN - half), y2 -= (y2 = b ? MARGIN : MARGIN - half)
    return {x: x1, y: y1, w: x2 - x1, h: y2 - y1}
}

InRect(r, x, y) => x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
Encloses(a, b) => a.x <= b.x && a.y <= b.y && a.x + a.w >= b.x + b.w && a.y + a.h >= b.y + b.h
