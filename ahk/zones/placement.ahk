; Zones as screen rectangles, and moving windows into them.

Place(hwnd, target) {
    src := ZoneOf(hwnd)
    try {
        if src && src != target && !Intersects(ZoneRect(src), ZoneRect(target))
            if top := TopWindowIn(target, hwnd)
                MoveTo(top, ZoneRect(src))
        MoveTo(hwnd, ZoneRect(target))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window`n" e.Message, "zones")
    }
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
    for z in ConnectedZones() {
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
    for z in ConnectedZones() {
        r := ZoneRect(z)
        if Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE
            && Abs(f.w - r.w) <= MATCH_TOLERANCE && Abs(f.h - r.h) <= MATCH_TOLERANCE
            return z
    }
    return ""
}

ConnectedZones() {
    list := []
    for z in ZONES
        if z.mon <= MonitorGetCount()
            list.Push(z)
    return list
}

ZoneRect(z) {
    MonitorGetWorkArea(z.mon, &l, &t, &r, &b)
    x := l + Round(z.x * (r - l)), y := t + Round(z.y * (b - t))
    w := Round(z.w * (r - l)), h := Round(z.h * (b - t))
    return {x: x + GAP, y: y + GAP, w: w - 2 * GAP, h: h - 2 * GAP}
}

InRect(r, x, y) => x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
Intersects(a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
Encloses(a, b) => a.x <= b.x && a.y <= b.y && a.x + a.w >= b.x + b.w && a.y + a.h >= b.y + b.h
