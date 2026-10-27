#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\lib\admin.ahk

; Keyboard mouse jump.
;   Ctrl+Space  labels each of AREAS with its key. A key moves the cursor to the center of its cell and
;               splits that cell into the ROWS grid, so each key narrows the target.
;               A CLICKS key clicks where the cursor is; any other key stops.
; Keys are read by their physical position (virtual key), so the Hangul input mode does not matter,
; and Ctrl may still be held from the hotkey.

; ---- Config ----
AREAS := [  ; the first pick, as the disjoint zones in zones.ahk; fractions of the whole monitor
    {key: "j", mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},    ; landscape, left half
    {key: "k", mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},    ; landscape, right half
    {key: "l", mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},  ; portrait, top half
    {key: ";", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},  ; portrait, bottom half
]
ROWS := ["uio", "jkl", "m,."]  ; every later pick splits the cell into this grid
CLICKS := Map("Space", "Left", "Enter", "Right")  ; key -> mouse button
KEY_SHOW := "^Space"
TIMEOUT_S := 10
FONT_SIZE := 28          ; shrinks to fit smaller cells
; Colors, RGB hex
BACK_COLOR := "1F1F1F"
TEXT_COLOR := "E6E6E6"
BACK_ALPHA := 150        ; overlay opacity, 0-255

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")
A_IconTip := "grid"
Hotkey(KEY_SHOW, (*) => Jump())

Jump() {
    cells := Map()
    for a in AREAS
        if a.mon <= MonitorGetCount() {
            MonitorGet(a.mon, &l, &t, &r, &b)
            w := r - l, h := b - t
            cells[a.key] := {l: l + Round(a.x * w), t: t + Round(a.y * h), r: l + Round((a.x + a.w) * w), b: t + Round((a.y + a.h) * h)}
        }
    loop {
        guis := ShowCells(cells)
        key := ReadKey()
        for g in guis
            g.Destroy()
        if !cells.Has(key)
            break
        c := cells[key]
        MouseMove((c.l + c.r) // 2, (c.t + c.b) // 2, 0)
        cells := Split(c)
    }
    if CLICKS.Has(key)
        Click(CLICKS[key])
}

; Splits a cell into the ROWS grid: key -> cell rectangle in screen pixels.
Split(c) {
    cells := Map(), cw := (c.r - c.l) / StrLen(ROWS[1]), ch := (c.b - c.t) / ROWS.Length
    for i, row in ROWS
        for j, key in StrSplit(row)
            cells[key] := {l: c.l + Round((j - 1) * cw), t: c.t + Round((i - 1) * ch), r: c.l + Round(j * cw), b: c.t + Round(i * ch)}
    return cells
}

; One translucent, click-through window per cell, inset 1px so the screen shows between cells.
ShowCells(cells) {
    guis := []
    for key, c in cells {
        w := Max(1, c.r - c.l - 2), h := Max(1, c.b - c.t - 2)
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")  ; click-through once layered
        g.BackColor := BACK_COLOR
        g.SetFont("s" Max(1, Min(FONT_SIZE, Round(Min(w, h) * 36 / A_ScreenDPI))) " bold c" TEXT_COLOR, "Segoe UI")  ; about half the cell
        g.AddText("x0 y0 w" w " h" h " Center 0x200", StrUpper(key))  ; 0x200: vertically centered
        g.Show("NA x" c.l + 1 " y" c.t + 1 " w" w " h" h)
        WinSetTransparent(BACK_ALPHA, g)
        guis.Push(g)
    }
    return guis
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
