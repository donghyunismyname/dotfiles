; Zone overlay: every zone shows a tile per open window, to pick a zone and a window with one click.

cancelOverlay := ""  ; set while the overlay is open; closes it without a pick

; Shows every zone with a tile per open window. Returns {zone, hwnd} for a clicked tile,
; {zone, background} for a click on a zone's background, or "" when cancelled by right-click or any key.
PickZoneAndWindow() {
    global cancelOverlay
    state := {pick: ""}
    ih := InputHook("L1 T30", "{Esc}")
    shown := Connected(ZONES)  ; not "zones": AHK names ignore case, so it would hide ZONES
    items := WindowItems()
    items.InsertAt(1, {hwnd: 0, title: "Minimize all"})  ; hwnd 0: minimize the zone's windows
    overlays := []
    for z in shown
        overlays.Push(ShowZoneOverlay(z, shown, items))
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

; Every click lands on a backdrop, since the layer with the tiles is click-through.
; A click inside the tile grid picks that tile; anywhere else is a click on the zone's background.
OverlayClicked(overlays, items, state, ih, wParam, lParam, msg, hwnd) {
    for o in overlays
        if hwnd = o.back.Hwnd {
            x := lParam & 0xFFFF, y := lParam >> 16 & 0xFFFF
            col := (x - o.x0) // TILE_W, row := (y - o.y0) // TILE_H, i := row * o.cols + col + 1
            if x >= o.x0 && y >= o.y0 && col < o.cols && i <= items.Length
                state.pick := {zone: o.zone, hwnd: items[i].hwnd}
            else
                state.pick := {zone: o.zone, background: true}
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
            return {x: r.x, y: r.y + BandHeight(c.w, n) + MARGIN, w: r.w, h: r.h - BandHeight(c.w, n) - MARGIN}
    return r
}

TileColumns(w) => Max(1, (w - 24) // TILE_W)
BandHeight(w, n) => 56 + Ceil(n / TileColumns(w)) * TILE_H

; Draws the zone as a translucent backdrop with a click-through layer on top holding the opaque
; tiles; that layer's background color is keyed out. Returns both windows and the tile grid layout.
ShowZoneOverlay(z, zones, items) {
    r := OverlayRect(z, zones, items.Length), h := r.h
    band := IsContainer(z, zones)
    back := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    back.BackColor := BACK_COLOR
    WinSetTransparent(BACK_ALPHA, back)
    back.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +Owner" back.Hwnd)  ; owned: stays above its backdrop
    g.BackColor := KEY_COLOR
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
        } else {
            g.SetFont("s20", "Segoe MDL2 Assets")
            g.AddText("x" x " y" y " w" TILE_W " h" ICON_SIZE " Center", Chr(0xE921))  ; minimize glyph
            g.SetFont("s9", "Segoe UI")
        }
        g.AddText("x" x " y" y + ICON_SIZE + 4 " w" TILE_W " r2 Center", item.title)
    }
    g.Show("NA x" r.x " y" r.y " w" r.w " h" h)
    WinSetTransColor(KEY_COLOR, g)
    return {zone: z, back: back, front: g, x0: x0, y0: y0, cols: cols}
}
