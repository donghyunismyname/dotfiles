; Overlay: every target shows a button per open window, to pick a target and a window with one click.

cancelOverlay := ""  ; set while the overlay is open; closes it without a pick

; Shows every target with a button per open window. Returns {target, hwnd} for a clicked button,
; {target, background} for a click on a target's background, or "" when cancelled by right-click or any key.
PickTargetAndWindow() {
    global cancelOverlay
    state := {pick: ""}
    ih := InputHook("L1 T30", "{Esc}")
    shown := Connected(TARGETS)  ; not "targets": AHK names ignore case, so it would hide TARGETS
    items := WindowItems()
    items.InsertAt(1, {hwnd: 0, title: "Minimize all"})  ; hwnd 0: minimize the target's windows
    overlays := []
    for t in shown
        overlays.Push(ShowTargetOverlay(t, shown, items))
    leftClick := OverlayClicked.Bind(overlays, items, state, ih)
    OnMessage(0x201, leftClick)  ; WM_LBUTTONDOWN
    cancelOverlay := () => ih.Stop()
    ih.Start()
    ih.Wait()
    OnMessage(0x201, leftClick, 0)
    cancelOverlay := ""
    for o in overlays
        o.front.Destroy(), o.back.Destroy()
    return state.pick
}

; Every click lands on a backdrop, since the layer with the buttons is click-through.
; A click inside the button grid picks that button; anywhere else is a click on the target's background.
OverlayClicked(overlays, items, state, ih, wParam, lParam, msg, hwnd) {
    for o in overlays
        if hwnd = o.back.Hwnd {
            x := lParam & 0xFFFF, y := lParam >> 16 & 0xFFFF
            col := (x - o.x0) // BUTTON_W, row := (y - o.y0) // BUTTON_H, i := row * o.cols + col + 1
            if x >= o.x0 && y >= o.y0 && col < o.cols && i <= items.Length
                state.pick := {target: o.target, hwnd: items[i].hwnd}
            else
                state.pick := {target: o.target, background: true}
            ih.Stop()
        }
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
    static iid := Guid("{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}")  ; IPropertyStore
    if DllCall("shell32\SHGetPropertyStoreForWindow", "ptr", hwnd, "ptr", iid, "ptr*", &store := 0)
        return ""
    key := Buffer(20)  ; PROPERTYKEY PKEY_AppUserModel_ID: format GUID, then property id 5
    DllCall("ole32\CLSIDFromString", "str", "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", "ptr", key)
    NumPut("uint", 5, key, 16)
    pv := Buffer(24, 0)
    ComCall(5, store, "ptr", key, "ptr", pv)  ; IPropertyStore::GetValue
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

IsContainer(t, targets) {
    r := TargetRect(t)
    for other in targets
        if other != t && Encloses(r, TargetRect(other))
            return true
    return false
}

; Overlays never overlap: a target that contains other targets gets a band at its top, tall enough for
; n buttons, and a target inside it that starts at the same top edge gets the area below the band.
OverlayRect(t, targets, n) {
    r := TargetRect(t)
    if IsContainer(t, targets)
        return {x: r.x, y: r.y, w: r.w, h: BandHeight(r.w, n)}
    for other in targets
        if other != t && Encloses(c := TargetRect(other), r) && c.y = r.y
            return {x: r.x, y: r.y + BandHeight(c.w, n) + MARGIN, w: r.w, h: r.h - BandHeight(c.w, n) - MARGIN}
    return r
}

ButtonColumns(w) => Max(1, (w - 24) // BUTTON_W)
BandHeight(w, n) => 56 + Ceil(n / ButtonColumns(w)) * BUTTON_H

; Draws the target as a translucent backdrop with a click-through layer on top holding the opaque
; buttons; that layer's background color is keyed out. Returns both windows and the button grid layout.
ShowTargetOverlay(t, targets, items) {
    r := OverlayRect(t, targets, items.Length), h := r.h
    band := IsContainer(t, targets)
    back := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    back.BackColor := BACK_COLOR
    WinSetTransparent(BACK_ALPHA, back)
    back.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +Owner" back.Hwnd)  ; owned: stays above its backdrop
    g.BackColor := KEY_COLOR
    ; A band starts its button grid below the target name; other targets center it.
    cols := ButtonColumns(r.w)
    rows := Ceil(items.Length / cols)
    x0 := Max(12, (r.w - Min(items.Length, cols) * BUTTON_W) // 2)
    y0 := band ? 44 : (h - rows * BUTTON_H) // 2
    g.SetFont("s16 bold c" TEXT_COLOR, "Segoe UI")
    g.AddText("x" x0 " y" y0 - 40, t.name)
    g.SetFont("s9 norm c" TEXT_COLOR)
    for i, item in items {
        x := x0 + Mod(i - 1, cols) * BUTTON_W, y := y0 + (i - 1) // cols * BUTTON_H
        if item.hwnd {
            try g.AddPicture("x" x + (BUTTON_W - ICON_SIZE) // 2 " y" y " w" ICON_SIZE " h" ICON_SIZE, item.icon)
        } else {
            g.SetFont("s20", "Segoe MDL2 Assets")
            g.AddText("x" x " y" y " w" BUTTON_W " h" ICON_SIZE " Center", Chr(0xE921))  ; minimize glyph
            g.SetFont("s9", "Segoe UI")
        }
        g.AddText("x" x " y" y + ICON_SIZE + 4 " w" BUTTON_W " r2 Center", item.title)
    }
    g.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    WinSetTransColor(KEY_COLOR, g)
    return {target: t, back: back, front: g, x0: x0, y0: y0, cols: cols}
}
