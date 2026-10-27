#Requires AutoHotkey v2.0
; Single-instance is handled below: a non-admin instance cannot close an elevated one,
; so #SingleInstance Force would get stuck asking whether to keep waiting.
#SingleInstance Off

; Relaunch elevated so admin windows (e.g. an elevated terminal) can be moved too.
; If the UAC prompt is declined, keep running without admin; /restart prevents a relaunch loop.
if !A_IsAdmin && !InStr(DllCall("GetCommandLine", "str"), " /restart") {
    try {
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp()
    }
}

; Replace any older instance of this script.
DetectHiddenWindows(true)
for hwnd in WinGetList(A_ScriptFullPath " - AutoHotkey ahk_class AutoHotkey")
    if (pid := WinGetPID(hwnd)) != ProcessExist()
        try ProcessClose(pid)
DetectHiddenWindows(false)

; Zone-based window placement.
;   tap Left Shift    every zone shows a tile per open window; click a tile to put that window there,
;                     or the first tile to minimize every window in that zone. Esc (or any key) cancels
;   Ctrl+Shift+Space  move the active window to MAIN_ZONE
; Zones are fractions of a monitor's work area and may overlap (Left, Right, and the whole monitor).
; Placing a window swaps it with the top window of the target zone when the two zones are disjoint;
; otherwise (overlapping zones, window not in any zone) the target's windows just stay behind.

; ---- Config ----
ZONES := [
    {name: "Left",   mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},
    {name: "Right",  mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},
    {name: "Top",    mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},
    {name: "Bottom", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},
    {name: "Wide",   mon: 1, x: 0,   y: 0,   w: 1,   h: 1},
    {name: "Tall",   mon: 2, x: 0,   y: 0,   w: 1,   h: 1},
]
MAIN_ZONE := ZONES[1]
KEY_PICK := "LShift"     ; tapped alone
TAP_MAX_MS := 300        ; a longer press is not a tap
KEY_PROMOTE := "^+Space"
GAP := 6                 ; px between a zone edge and its window
MATCH_TOLERANCE := 16    ; px of slack when deciding which zone a window is in
ICON_SIZE := 32
TILE_W := 110            ; px per window tile: icon with its title below
TILE_H := 84
; Colors, RGB hex
ACCENT_COLOR := "1E4AA0" ; focus border and zone bands
BACK_COLOR := "1F1F1F"   ; zone overlays
TEXT_COLOR := "E6E6E6"
BORDER_WIDTH := 4
BORDER_POLL_MS := 100

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
A_IconTip := "zones"
InstallMouseHook()  ; so Shift+click is not taken for a tap
Hotkey("~" KEY_PICK, OnPickKey)
Hotkey(KEY_PROMOTE, (*) => PromoteActive())

; Focus border: four click-through bars just inside the active window's visible frame.
borderBars := []
loop 4 {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020")  ; layered + transparent: clicks pass through
    g.BackColor := ACCENT_COLOR
    WinSetTransparent(255, g)
    borderBars.Push(g)
}
SetTimer(UpdateBorder, BORDER_POLL_MS)

OnPickKey(*) {
    KeyWait(KEY_PICK)
    if A_PriorKey != KEY_PICK || A_TimeSinceThisHotkey > TAP_MAX_MS
        return
    PickAndPlace()  ; taps while it runs are ignored: a hotkey runs one thread at a time
}

PickAndPlace() {
    if !(pick := PickZoneAndWindow())
        return
    if pick.hwnd
        Place(pick.hwnd, pick.zone)
    else
        MinimizeZone(pick.zone)
}

PromoteActive() {
    if (hwnd := WinExist("A")) && IsAppWindow(hwnd)
        Place(hwnd, MAIN_ZONE)
}

; ---- Placement ----

Place(hwnd, target) {
    src := ZoneOf(hwnd)
    ; Windows of elevated (admin) apps refuse moves from a non-admin script.
    try {
        if src && src != target && !Intersects(ZoneRect(src), ZoneRect(target))
            if top := TopWindowIn(target, hwnd)
                MoveTo(top, ZoneRect(src))
        MoveTo(hwnd, ZoneRect(target))
        WinActivate(hwnd)
    } catch as e {
        TrayTip("Could not move the window (admin app?)`n" e.Message, "zones")
    }
}

MinimizeZone(zone) {
    for hwnd in Windows()
        if ZoneOf(hwnd) == zone
            try WinMinimize(hwnd)
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

Intersects(a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
Encloses(a, b) => a.x <= b.x && a.y <= b.y && a.x + a.w >= b.x + b.w && a.y + a.h >= b.y + b.h

; ---- Windows ----

; Top-level app windows in z-order, topmost first.
Windows() {
    list := []
    for hwnd in WinGetList()
        if IsAppWindow(hwnd)
            list.Push(hwnd)
    return list
}

IsAppWindow(hwnd) {
    try {
        if WinGetTitle(hwnd) = "" || WinGetPID(hwnd) = ProcessExist()
            return false
        if WinGetExStyle(hwnd) & 0x80 || DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")  ; tool window or owned window
            return false
        cloaked := 0  ; e.g. suspended UWP apps and windows on other virtual desktops
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "int*", &cloaked, "uint", 4)
        return !cloaked && !(WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_(Secondary)?TrayWnd)$")
    }
    return false
}

; Visible frame, without the invisible resize borders that WinGetPos includes.
FrameRect(hwnd) {
    buf := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", buf, "uint", 16) {
        WinGetPos(&x, &y, &w, &h, hwnd)
        return {x: x, y: y, w: w, h: h}
    }
    l := NumGet(buf, 0, "int"), t := NumGet(buf, 4, "int")
    return {x: l, y: t, w: NumGet(buf, 8, "int") - l, h: NumGet(buf, 12, "int") - t}
}

; Moves the window so its visible frame fills r.
MoveTo(hwnd, r) {
    if WinGetMinMax(hwnd) != 0
        WinRestore(hwnd)
    WinGetPos(&x, &y, &w, &h, hwnd)
    f := FrameRect(hwnd)
    WinMove(r.x - (f.x - x), r.y - (f.y - y), r.w + (w - f.w), r.h + (h - f.h), hwnd)
}

; ---- Zone overlay ----

; Shows every zone with a tile per open window; returns {zone, hwnd} for the clicked tile, or "".
; Any key (e.g. Esc) cancels.
PickZoneAndWindow() {
    state := {pick: ""}
    ih := InputHook("L1 T30", "{Esc}")
    zones := ConnectedZones()
    items := WindowItems()
    items.InsertAt(1, {hwnd: 0, title: "Minimize all"})  ; hwnd 0: minimize the zone's windows
    guis := []
    for z in zones
        guis.Push(ShowZoneOverlay(z, zones, items, TileClicked.Bind(state, ih, z)))
    ih.Start()
    ih.Wait()
    for g in guis
        g.Destroy()
    return state.pick
}

TileClicked(state, ih, z, hwnd, *) {
    state.pick := {zone: z, hwnd: hwnd}
    ih.Stop()
}

; Open windows sorted by process name, then taskbar group ID (separate per Chrome profile and web app);
; windows of the same group keep a fixed order by handle.
WindowItems() {
    list := Windows(), lines := ""
    for i, hwnd in list
        try lines .= WinGetProcessName(hwnd) " " AppId(hwnd) " " Format("{:012}", hwnd) "`t" i "`n"
    items := []
    for line in StrSplit(Sort(RTrim(lines, "`n")), "`n") {
        hwnd := list[Integer(StrSplit(line, "`t")[2])]
        try items.Push({hwnd: hwnd, title: WinGetTitle(hwnd), icon: WindowIcon(hwnd)})
    }
    return items
}

; Taskbar grouping ID (AppUserModelID) of a window, or "" when it has none of its own.
AppId(hwnd) {
    iid := Buffer(16), pkey := Buffer(20)
    DllCall("ole32\CLSIDFromString", "str", "{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}", "ptr", iid)  ; IPropertyStore
    DllCall("ole32\CLSIDFromString", "str", "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", "ptr", pkey)
    NumPut("uint", 5, pkey, 16)  ; PKEY_AppUserModel_ID
    if DllCall("shell32\SHGetPropertyStoreForWindow", "ptr", hwnd, "ptr", iid, "ptr*", &store := 0)
        return ""
    pv := Buffer(24, 0)
    ComCall(5, store, "ptr", pkey, "ptr", pv)  ; IPropertyStore::GetValue
    id := NumGet(pv, 0, "ushort") = 31 ? StrGet(NumGet(pv, 8, "ptr")) : ""  ; VT_LPWSTR
    DllCall("ole32\PropVariantClear", "ptr", pv), ObjRelease(store)
    return id
}

; The window's own icon (the one the taskbar shows) as a Picture source, falling back to its executable.
WindowIcon(hwnd) {
    for size in [1, 2, 0] {  ; WM_GETICON: ICON_BIG, ICON_SMALL2, ICON_SMALL
        h := 0
        try h := SendMessage(0x7F, size, 0, , hwnd, , , , 200)
        if h
            return "HICON:*" h  ; *: the window owns the icon, so don't destroy it
    }
    if h := DllCall("GetClassLongPtr", "ptr", hwnd, "int", -14, "ptr")  ; GCLP_HICON
        return "HICON:*" h
    return WinGetProcessPath(hwnd)
}

IsContainer(z, zones) {
    r := ZoneRect(z)
    for other in zones
        if other != z && Encloses(r, ZoneRect(other))
            return true
    return false
}

; Overlays never overlap: a zone that contains other zones gets a band at its top, tall enough for
; n tiles, and a zone inside it that starts at the same top edge gets the area below the band.
OverlayRect(z, zones, n) {
    r := ZoneRect(z)
    if IsContainer(z, zones)
        return {x: r.x, y: r.y, w: r.w, h: BandHeight(r.w, n)}
    for other in zones
        if other != z && Encloses(c := ZoneRect(other), r) && c.y = r.y
            return {x: r.x, y: r.y + BandHeight(c.w, n) + GAP, w: r.w, h: r.h - BandHeight(c.w, n) - GAP}
    return r
}

TileColumns(w) => Max(1, (w - 24) // TILE_W)
BandHeight(w, n) => 56 + Ceil(n / TileColumns(w)) * TILE_H

ShowZoneOverlay(z, zones, items, onClick) {
    r := OverlayRect(z, zones, items.Length), h := r.h
    band := IsContainer(z, zones)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    g.BackColor := band ? ACCENT_COLOR : BACK_COLOR
    ; A band starts its tile grid below the zone name; other zones center it.
    cols := TileColumns(r.w)
    rows := Ceil(items.Length / cols)
    x0 := Max(12, (r.w - Min(items.Length, cols) * TILE_W) // 2)
    y0 := band ? 44 : (h - rows * TILE_H) // 2
    g.SetFont("s16 bold c" TEXT_COLOR, "Segoe UI")
    g.AddText("x" x0 " y" y0 - 40, z.name)
    g.SetFont("s9 norm c" TEXT_COLOR)
    for i, item in items {
        x := x0 + Mod(i - 1, cols) * TILE_W, y := y0 + (i - 1) // cols * TILE_H
        if item.hwnd {
            try g.AddPicture("x" x + (TILE_W - ICON_SIZE) // 2 " y" y " w" ICON_SIZE " h" ICON_SIZE, item.icon)
                .OnEvent("Click", onClick.Bind(item.hwnd))
        } else {
            g.SetFont("s20", "Segoe MDL2 Assets")
            g.AddText("x" x " y" y " w" TILE_W " h" ICON_SIZE " Center", Chr(0xE921))  ; minimize glyph
                .OnEvent("Click", onClick.Bind(0))
            g.SetFont("s9", "Segoe UI")
        }
        g.AddText("x" x " y" y + ICON_SIZE + 4 " w" TILE_W " r2 Center", item.title)
            .OnEvent("Click", onClick.Bind(item.hwnd))
    }
    g.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    return g
}

; ---- Focus border ----

UpdateBorder() {
    static last := ""
    r := ""
    try {
        hwnd := WinExist("A")
        if hwnd && IsAppWindow(hwnd) && WinGetMinMax(hwnd) != -1
            r := FrameRect(hwnd)
    }
    key := r ? r.x "," r.y "," r.w "," r.h : ""
    if key = last
        return
    last := key
    if !r {
        for g in borderBars
            g.Hide()
        return
    }
    t := BORDER_WIDTH
    for i, b in [[r.x, r.y, r.w, t], [r.x, r.y + r.h - t, r.w, t], [r.x, r.y, t, r.h], [r.x + r.w - t, r.y, t, r.h]]
        borderBars[i].Show("NA x" b[1] " y" b[2] " w" b[3] " h" b[4])
}
