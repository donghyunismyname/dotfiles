#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\lib\admin.ahk

; Keyboard mouse jump.
;   Ctrl+Space  covers MONITOR with a grid of keys laid out like the keyboard (ROWS).
;               A key moves the cursor to the center of its cell and splits that cell into the same grid,
;               so each key narrows the target. A CLICKS key clicks where the cursor is; any other key stops.
; Keys are read by their physical position (virtual key), so the Hangul input mode does not matter,
; and Ctrl may still be held from the hotkey.

; ---- Config ----
MONITOR := 1             ; the landscape monitor, as in zones.ahk
ROWS := ["qweruiop", "asdfjkl;", "zxcvm,./"]
CLICKS := Map("Space", "Left", "Enter", "Right")  ; key -> mouse button
KEY_SHOW := "^Space"
TIMEOUT_S := 10
FONT_SIZE := 28          ; shrinks to fit smaller cells
; Colors, RGB hex
LINE_COLOR := "5A5A5A"   ; 1px grid lines: the gaps between cells
BACK_COLOR := "1F1F1F"
TEXT_COLOR := "E6E6E6"
BACK_ALPHA := 150        ; overlay opacity, 0-255

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")
A_IconTip := "grid"
Hotkey(KEY_SHOW, (*) => Jump())

Jump() {
    MonitorGet(MONITOR, &l, &t, &r, &b)
    area := {l: l, t: t, r: r, b: b}
    loop {
        cells := Map()
        g := ShowGrid(area, cells)
        key := ReadKey()
        g.Destroy()
        if !cells.Has(key)
            break
        area := cells[key]
        MouseMove((area.l + area.r) // 2, (area.t + area.b) // 2, 0)
    }
    if CLICKS.Has(key)
        Click(CLICKS[key])
}

; Shows the ROWS grid over area and fills cells with key -> cell rectangle in screen pixels.
ShowGrid(area, cells) {
    w := area.r - area.l, h := area.b - area.t
    cw := w / StrLen(ROWS[1]), ch := h / ROWS.Length
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")  ; click-through once layered
    g.BackColor := LINE_COLOR
    g.SetFont("s" Max(1, Min(FONT_SIZE, Round(Min(cw, ch) * 36 / A_ScreenDPI))) " bold c" TEXT_COLOR, "Segoe UI")  ; about half the cell
    for i, row in ROWS
        for j, key in StrSplit(row) {
            x1 := Round((j - 1) * cw), x2 := Round(j * cw), y1 := Round((i - 1) * ch), y2 := Round(i * ch)
            g.AddText("x" x1 + 1 " y" y1 + 1 " w" Max(1, x2 - x1 - 1) " h" Max(1, y2 - y1 - 1) " Center 0x200 Background" BACK_COLOR, StrUpper(key))  ; 0x200: vertically centered
            cells[key] := {l: area.l + x1, t: area.t + y1, r: area.l + x2, b: area.t + y2}
        }
    g.Show("NA x" area.l " y" area.t " w" w " h" h)
    WinSetTransparent(BACK_ALPHA, g)
    return g
}

; Waits for one key down, blocking it from the app; returns its name, or "" on timeout.
ReadKey() {
    state := {key: ""}
    ih := InputHook("T" TIMEOUT_S)
    ih.KeyOpt("{All}", "NS")  ; every key down is reported and blocked
    ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-NS")  ; modifiers pass, so a held Ctrl does not cancel
    ih.OnKeyDown := (ih, vk, sc) => (state.key := GetKeyName(Format("vk{:x}sc{:x}", vk, sc)), ih.Stop())
    ih.Start()
    ih.Wait()
    return state.key
}
