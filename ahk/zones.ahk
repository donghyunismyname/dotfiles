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
;   Ctrl+Space        choose a zone on the overlay (number key or click), then a window in the picker
;   Ctrl+Shift+Space  move the active window to MAIN_ZONE
; Zones are fractions of a monitor's work area and may overlap (Left, Right, and the whole monitor).
; Placing a window swaps it with the top window of the target zone when the two zones are disjoint;
; otherwise (overlapping zones, window not in any zone) the target's windows just stay behind.

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
KEY_PICK := "^Space"
KEY_PROMOTE := "^+Space"
GAP := 6                 ; px between a zone edge and its window
MATCH_TOLERANCE := 16    ; px of slack when deciding which zone a window is in
OVERLAY_ALPHA := 210
BAND_HEIGHT := 90        ; a zone that contains other zones is drawn as a band at its top edge
PICKER_TITLE := "zones-picker"
PICKER_WIDTH := 640
PICKER_ROWS := 10        ; max visible rows before the list scrolls

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
    if hwnd := PickWindow(zone)
        Place(hwnd, zone)
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
    g.BackColor := band ? "2D6CDF" : "1F1F1F"
    g.SetFont("s24 bold cWhite", "Segoe UI")
    g.AddText("x0 y0 w" r.w " h" h " Center 0x200", z.key "  " z.name).OnEvent("Click", onClick)  ; 0x200: center vertically
    g.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    WinSetTransparent(OVERLAY_ALPHA, g)
    return g
}

; ---- Picker ----

; Lists open windows with their icons, filtered by the typed text; returns the chosen window or 0.
PickWindow(zone) {
    global pickerList
    icons := IL_Create(10, 10, true)  ; large (32 px) icons
    items := []
    for hwnd in Windows() {
        z := ZoneOf(hwnd)
        try items.Push({hwnd: hwnd, title: WinGetTitle(hwnd), exe: WinGetProcessName(hwnd)
            , where: z ? z.name : "", icon: AddWindowIcon(icons, hwnd)})
    }

    state := {shown: [], choice: 0}
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", PICKER_TITLE)
    g.BackColor := "1F1F1F"
    g.MarginX := 14, g.MarginY := 12
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", g.Hwnd, "uint", 33, "int*", 2, "uint", 4)  ; rounded corners (Win11)
    g.SetFont("s10 c9A9A9A", "Segoe UI")
    g.AddText("w" PICKER_WIDTH, "Put into " zone.name)
    g.SetFont("s13 cF0F0F0")
    query := g.AddEdit("w" PICKER_WIDTH " -E0x200 Background2B2B2B")
    SendMessage(0x1501, true, StrPtr("Type to filter windows"), query)  ; EM_SETCUEBANNER
    SendMessage(0xD3, 3, 10 | 10 << 16, query)  ; EM_SETMARGINS: 10 px left and right
    g.SetFont("s11 cE6E6E6")
    ; LV0x10000: double buffering against flicker.
    pickerList := g.AddListView("w" PICKER_WIDTH " -Hdr -Multi -E0x200 +LV0x10000 Background1F1F1F", ["Window"])
    pickerList.SetImageList(icons, 1)
    DllCall("uxtheme\SetWindowTheme", "ptr", pickerList.Hwnd, "str", "DarkMode_Explorer", "ptr", 0)
    refill := (*) => FillPicker(pickerList, items, query.Value, state)
    query.OnEvent("Change", refill)
    pickerList.OnEvent("Click", (*) => SubmitPicker(g, pickerList, state))
    g.AddButton("Default Hidden", "OK").OnEvent("Click", (*) => SubmitPicker(g, pickerList, state))
    g.OnEvent("Escape", (*) => g.Destroy())
    refill()
    SendMessage(0x127, 0x10001, 0, pickerList)  ; WM_CHANGEUISTATE: hide the dotted focus rectangle

    ; The list keeps focus so its selection is clearly highlighted; typed characters go to the filter box.
    onChar := (wParam, lParam, msg, hwnd) => hwnd = pickerList.Hwnd ? ForwardChar(query, wParam, refill) : ""
    OnMessage(0x102, onChar)  ; WM_CHAR

    ; Row heights are only known once the window exists; then fit the list and center on the target zone.
    g.Show("Hide")
    FitListHeight(pickerList, items.Length)
    g.Show("AutoSize Hide")
    WinGetPos(, , &w, &h, g)
    r := ZoneRect(zone)
    WinMove(r.x + (r.w - w) // 2, r.y + (r.h - h) // 2, , , g)
    g.Show()
    pickerList.Focus()
    WinWaitClose(g)
    OnMessage(0x102, onChar, 0)
    return state.choice
}

; Sizes the list to its rows, up to PICKER_ROWS.
FitListHeight(lv, count) {
    rect := Buffer(16, 0)  ; LVIR_BOUNDS
    SendMessage(0x100E, 0, rect, lv)  ; LVM_GETITEMRECT of the first row
    rowHeight := NumGet(rect, 12, "int") - NumGet(rect, 4, "int")
    lv.Move(, , , Max(1, Min(count, PICKER_ROWS)) * rowHeight + 4)
    lv.ModifyCol(1, "AutoHdr")
}

ForwardChar(query, char, refill) {
    if char = 8  ; Backspace
        query.Value := SubStr(query.Value, 1, -1)
    else if char >= 32
        query.Value .= Chr(char)
    else
        return ""  ; let Enter and Esc through
    refill()
    return 0
}

; Adds the window's own icon (the one the taskbar shows) to the image list; returns its 1-based index.
AddWindowIcon(il, hwnd) {
    for size in [1, 2, 0] {  ; WM_GETICON: ICON_BIG, ICON_SMALL2, ICON_SMALL
        h := 0
        try h := SendMessage(0x7F, size, 0, , hwnd, , , , 200)
        if h
            return DllCall("comctl32\ImageList_ReplaceIcon", "ptr", il, "int", -1, "ptr", h) + 1
    }
    if h := DllCall("GetClassLongPtr", "ptr", hwnd, "int", -14, "ptr")  ; GCLP_HICON
        return DllCall("comctl32\ImageList_ReplaceIcon", "ptr", il, "int", -1, "ptr", h) + 1
    try return IL_Add(il, WinGetProcessPath(hwnd))
    return 0
}

FillPicker(lv, items, text, state) {
    lv.Delete()
    state.shown := []
    for item in items
        if Matches(item.title " " item.exe, text) {
            state.shown.Push(item)
            lv.Add("Icon" item.icon, item.where ? item.title "   ·   " item.where : item.title)
        }
    if state.shown.Length
        lv.Modify(1, "Select Focus Vis")
    lv.ModifyCol(1, "AutoHdr")  ; fill the width left by the scrollbar, if any
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
        state.choice := state.shown[row].hwnd
    g.Destroy()
}

MovePickerSelection(delta) {
    if !(n := pickerList.GetCount())
        return
    row := Max(1, Min(n, pickerList.GetNext() + delta))
    pickerList.Modify(0, "-Select")
    pickerList.Modify(row, "Select Focus Vis")
}
