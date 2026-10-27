#Requires AutoHotkey v2.0
#SingleInstance Force

; Relaunch elevated so admin windows (e.g. an elevated terminal) can be moved too.
; If the UAC prompt is declined, keep running without admin; /restart prevents a relaunch loop.
if !A_IsAdmin && !InStr(DllCall("GetCommandLine", "str"), " /restart") {
    try {
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp()
    }
}

; Zone-based window placement.
;   Ctrl+Space        choose a zone on the overlay (number key or click), then a window or app in the picker
;   Ctrl+Shift+Space  move the active window to MAIN_ZONE
; Zones are fractions of a monitor's work area and may overlap (Left, Right, and the whole monitor).
; Placing a window swaps it with the top window of the target zone when the two zones are disjoint;
; otherwise (overlapping zones, new app, window not in any zone) the target's windows just stay behind.

; ---- Config ----
ZONES := [
    {key: "1", name: "Left",   mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},
    {key: "2", name: "Right",  mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},
    {key: "3", name: "Top",    mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},
    {key: "4", name: "Bottom", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},
    {key: "5", name: "Wide",   mon: 1, x: 0,   y: 0,   w: 1,   h: 1},
    {key: "6", name: "Tall",   mon: 2, x: 0,   y: 0,   w: 1,   h: 1},
]
MAIN_ZONE := ZONES[1]
APPS := [
    {name: "Chrome",   cmd: "chrome.exe --new-window"},
    {name: "Terminal", cmd: "wt.exe"},
    {name: "Explorer", cmd: "explorer.exe"},
    {name: "Notepad",  cmd: "notepad.exe"},
]
KEY_PICK := "^Space"
KEY_PROMOTE := "^+Space"
GAP := 6                 ; px between a zone edge and its window
MATCH_TOLERANCE := 16    ; px of slack when deciding which zone a window is in
OVERLAY_ALPHA := 170
BAND_HEIGHT := 90        ; a zone that contains other zones is drawn as a band at its top edge
LAUNCH_TIMEOUT_MS := 10000
PICKER_TITLE := "zones-picker"

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
A_IconTip := "zones"
Hotkey(KEY_PICK, (*) => PickAndPlace())
Hotkey(KEY_PROMOTE, (*) => PromoteActive())

#HotIf WinActive(PICKER_TITLE " ahk_class AutoHotkeyGUI")
Up::MovePickerSelection(-1)
Down::MovePickerSelection(1)
#HotIf

PickAndPlace() {
    if !(zone := PickZone())
        return
    if !(item := PickItem(zone))
        return
    if item.HasOwnProp("hwnd")
        Place(item.hwnd, zone)
    else
        Launch(item.app, zone)
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

; Runs the app and places the first new window that appears.
Launch(app, zone) {
    before := Map()
    for hwnd in Windows()
        before[hwnd] := true
    try {
        Run(app.cmd)
    } catch as e {
        MsgBox("Could not run " app.cmd "`n" e.Message, "zones")
        return
    }
    deadline := A_TickCount + LAUNCH_TIMEOUT_MS
    while A_TickCount < deadline {
        Sleep(100)
        for hwnd in Windows()
            if !before.Has(hwnd) {
                Sleep(300)  ; let the app finish restoring its own size first
                return Place(hwnd, zone)
            }
    }
    TrayTip("No new window from " app.name, "zones")
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

; Shows every zone as a labeled overlay; returns the zone chosen by key or click, or "".
PickZone() {
    state := {zone: ""}
    ih := InputHook("L1 T15", "{Esc}")
    zones := ConnectedZones()
    ; Draw containing zones last, as a band, so the zones inside them stay visible and clickable.
    guis := []
    for band in [false, true]
        for z in zones
            if IsContainer(z, zones) = band
                guis.Push(ShowZoneOverlay(z, band, ZoneClicked.Bind(state, ih, z)))
    ih.Start()
    ih.Wait()
    for g in guis
        g.Destroy()
    if state.zone
        return state.zone
    if ih.EndReason = "Max"
        for z in zones
            if z.key = ih.Input
                return z
    return ""
}

ZoneClicked(state, ih, z, *) {
    state.zone := z
    ih.Stop()
}

IsContainer(z, zones) {
    r := ZoneRect(z)
    for other in zones
        if other != z && Encloses(r, ZoneRect(other))
            return true
    return false
}

ShowZoneOverlay(z, band, onClick) {
    r := ZoneRect(z)
    h := band ? BAND_HEIGHT : r.h
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    g.BackColor := band ? "8A3FD1" : "2D6CDF"
    g.SetFont("s24 bold cWhite", "Segoe UI")
    g.AddText("x0 y0 w" r.w " h" h " Center 0x200", z.key "  " z.name).OnEvent("Click", onClick)  ; 0x200: center vertically
    g.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    WinSetTransparent(OVERLAY_ALPHA, g)
    return g
}

; ---- Picker ----

; Lists open windows and launchable apps, filtered by the typed text; returns the chosen item or "".
PickItem(zone) {
    global pickerList
    items := []
    for hwnd in Windows() {
        z := ZoneOf(hwnd)
        try items.Push({hwnd: hwnd, label: WinGetTitle(hwnd) "  ·  " WinGetProcessName(hwnd), where: z ? z.name : ""})
    }
    for app in APPS
        items.Push({app: app, label: "Open " app.name, where: "new"})

    state := {shown: [], choice: ""}
    g := Gui("+AlwaysOnTop -Caption +Border", PICKER_TITLE)
    g.SetFont("s11", "Segoe UI")
    g.AddText("w640", "Put into " zone.name)
    query := g.AddEdit("w640")
    pickerList := g.AddListView("w640 r15 -Hdr -Multi +0x8", ["Name", "Zone"])  ; 0x8: keep selection visible
    pickerList.ModifyCol(1, 520)
    pickerList.ModifyCol(2, 100)
    query.OnEvent("Change", (*) => FillPicker(pickerList, items, query.Value, state))
    pickerList.OnEvent("DoubleClick", (*) => SubmitPicker(g, pickerList, state))
    g.AddButton("Default Hidden", "OK").OnEvent("Click", (*) => SubmitPicker(g, pickerList, state))
    g.OnEvent("Escape", (*) => g.Destroy())
    FillPicker(pickerList, items, "", state)
    g.Show()
    WinWaitClose(g)
    return state.choice
}

FillPicker(lv, items, text, state) {
    lv.Delete()
    state.shown := []
    for item in items
        if Matches(item.label, text) {
            state.shown.Push(item)
            lv.Add(, item.label, item.where)
        }
    if state.shown.Length
        lv.Modify(1, "Select Focus Vis")
}

; Every space-separated term must appear in the label.
Matches(label, text) {
    for term in StrSplit(Trim(text), " ")
        if term != "" && !InStr(label, term)
            return false
    return true
}

SubmitPicker(g, lv, state) {
    if row := lv.GetNext()
        state.choice := state.shown[row]
    g.Destroy()
}

MovePickerSelection(delta) {
    if !(n := pickerList.GetCount())
        return
    row := Max(1, Min(n, pickerList.GetNext() + delta))
    pickerList.Modify(0, "-Select")
    pickerList.Modify(row, "Select Focus Vis")
}
