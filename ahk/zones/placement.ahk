; Zones as screen rectangles, and moving windows into them. A tile holds one window.

restoring := 0  ; a minimized window Place is restoring, so the restore is not taken for the user's

; Puts the window in the target zone. A tile's window moves out: to the placed window's old tile,
; else to the first empty tile, else it is minimized.
Place(hwnd, target) {
    global restoring
    src := ZoneOf(hwnd)
    try {
        if IsTile(target) && (other := TopWindowIn(target, hwnd)) {
            if src && src != target && IsTile(src)
                MoveTo(other, ZoneRect(src))
            else if empty := FirstEmptyTile(hwnd)
                MoveTo(other, ZoneRect(empty))
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

; A window restored from minimized comes back in RESTORED_TILE.
StartRestorePlacement() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART], (event, hwnd, *) => SetTimer(AimRestore.Bind(hwnd), -RESTORE_DELAY_MS))
    HookWinEvents([EVENT_SYSTEM_MINIMIZEEND], (event, hwnd, *) => SetTimer(PlaceRestored.Bind(hwnd), -RESTORE_DELAY_MS))
}

; Points a minimized window's restore position at RESTORED_TILE, so Windows brings it back there
; instead of where it was. Needs the window's border widths, measured while it was shown.
AimRestore(hwnd) {
    try {
        if IsAppWindow(hwnd) && WinGetMinMax(hwnd) = -1
            SetNormalRect(hwnd, ZoneRect(RESTORED_TILE), 7)  ; SW_SHOWMINNOACTIVE: stay minimized
    }
}

; Moves the tile's window out, as placing does; also places the window when AimRestore could not.
PlaceRestored(hwnd) {
    global restoring
    if hwnd = restoring
        return restoring := 0
    try {
        if IsAppWindow(hwnd) && WinGetMinMax(hwnd) != -1
            Place(hwnd, RESTORED_TILE)
    }
}

IsTile(z) {
    for t in TILES
        if t == z
            return true
    return false
}

; First tile, in TILES order, with no window other than exclude.
FirstEmptyTile(exclude) {
    for t in Connected(TILES)
        if !TopWindowIn(t, exclude)
            return t
    return ""
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
