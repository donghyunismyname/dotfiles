; Zones as screen rectangles, and moving windows into them. A tile holds one window.

restoring := 0  ; a minimized window Place is restoring, so autoplace doesn't move it to HOME_TILE

; Puts the window in the target zone. A tile's window swaps to the placed window's old tile, or is
; minimized when there is none. A window that appeared on its own (auto) has no old tile, only
; where its app put it.
Place(hwnd, target, auto := false) {
    global restoring
    try {
        src := ZoneOf(hwnd)
        if IsTile(target) && (other := TopWindowIn(target, hwnd)) {
            if !auto && src && src != target && IsTile(src)
                MoveTo(other, ZoneRect(src))
            else
                WinMinimize(other)
        }
        if WinGetMinMax(hwnd) = -1
            restoring := hwnd
        MoveTo(hwnd, ZoneRect(target))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window`n" e.Message, "zones")
    }
}

; Fits the windows already in a zone to its current rectangle, e.g. after MARGIN changed.
; Maximized windows are left alone, though they match the whole-monitor zones.
SnapToZones() {
    for hwnd in Windows()
        try {
            if WinGetMinMax(hwnd) = 0 && (z := ZoneOf(hwnd))
                MoveTo(hwnd, ZoneRect(z))
        }
}

IsTile(z) {
    for t in TILES
        if t == z
            return true
    return false
}

; Minimizes every window whose center is in the zone, so a whole-monitor zone clears that monitor.
MinimizeZone(zone) {
    r := ZoneRect(zone)
    for hwnd in Windows()
        try {
            f := FrameRect(hwnd)
            if InRect(r, f.x + f.w // 2, f.y + f.h // 2)
                WinMinimize(hwnd)
        }
}

; Smallest zone containing the point, so a half wins over the whole monitor around it.
ZoneAt(x, y) {
    best := "", bestArea := 0
    for z in Connected(ZONES) {
        r := ZoneRect(z)
        if InRect(r, x, y) && (!best || r.w * r.h < bestArea)
            best := z, bestArea := r.w * r.h
    }
    return best
}

TopWindowIn(zone, exclude) {
    for hwnd in Windows()
        if hwnd != exclude && ZoneOf(hwnd) == zone
            return hwnd
    return 0
}

ZoneOf(hwnd) {
    f := FrameRect(hwnd)
    for z in Connected(ZONES) {
        r := ZoneRect(z)
        if Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE
            && Abs(f.w - r.w) <= MATCH_TOLERANCE && Abs(f.h - r.h) <= MATCH_TOLERANCE
            return z
    }
    return ""
}

; The zones whose monitor is connected.
Connected(zones) {
    list := []
    for z in zones
        if z.mon <= MonitorGetCount()
            list.Push(z)
    return list
}

; The zone's area of the work area, inset by MARGIN at the work area's edges and by half of it at an
; edge inside, which the neighboring zone insets by the other half.
ZoneRect(z) {
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
