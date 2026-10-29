#Requires AutoHotkey v2.0
#SingleInstance Force

; Keyboard mouse jump.
;   Ctrl+Space  splits each of AREAS into 3x3 BLOCKS of 3x3 cells (ROWS), each labeled with three keys:
;               area, block, cell. Typing a label moves the cursor to the center of its cell.
;               A key that fits no label cancels.
; Keys are read by their physical position (virtual key), so the Hangul input mode does not matter,
; and Ctrl may still be held from the hotkey.

; ---- Config ----
AREAS := [  ; first key, as the disjoint panes in panes.ahk; fractions of the whole monitor
    {key: "j", mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},    ; landscape, left half
    {key: "k", mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},    ; landscape, right half
    {key: "l", mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},  ; portrait, top half
    {key: ";", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},  ; portrait, bottom half
]
BLOCKS := ["wer", "sdf", "xcv"]  ; second key: a block of the area
ROWS := ["uio", "jkl", "m,."]    ; third key: a cell of the block
KEY_SHOW := "^Space"
TIMEOUT_S := 10
FONT_SIZE := 28          ; shrinks to fit smaller cells
; Colors, RGB hex
LINE_COLOR := "5A5A5A"   ; 1px grid lines: the gaps between cells
BACK_COLOR := "1F1F1F"
BACK_ALT_COLOR := "383838"  ; every other block, so blocks stand apart
TEXT_COLOR := "E6E6E6"
BACK_ALPHA := 170        ; overlay opacity, 0-255

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")
A_IconTip := "grid"
Hotkey(KEY_SHOW, (*) => Jump())

Jump() {
    cells := StartCells(), guis := ShowCells(cells), typed := ""
    while StrLen(typed) < 3 && (key := ReadKey()) != "" && StartsAny(cells, typed key)  ; 3: area, block, cell
        typed .= key
    for g in guis
        g.Destroy()
    if cells.Has(typed)
        c := cells[typed], MouseMove((c.l + c.r) // 2, (c.t + c.b) // 2, 0)
}

; Label -> cell rectangle in screen pixels, for every cell of every connected area.
StartCells() {
    cells := Map()
    for a in AREAS
        if a.mon <= MonitorGetCount() {
            MonitorGet(a.mon, &l, &t, &r, &b)
            w := r - l, h := b - t
            area := {l: l + Round(a.x * w), t: t + Round(a.y * h), r: l + Round((a.x + a.w) * w), b: t + Round((a.y + a.h) * h), mon: a.mon}
            for i, block in Split(area, BLOCKS, a.key)
                for c in Split(block, ROWS, block.label, Mod(i, 2) ? BACK_COLOR : BACK_ALT_COLOR)
                    cells[c.label] := c
        }
    return cells
}

; Splits rectangle r into the rows grid: cells labeled prefix + key.
Split(r, rows, prefix, back := BACK_COLOR) {
    cells := [], cw := (r.r - r.l) / StrLen(rows[1]), ch := (r.b - r.t) / rows.Length
    for i, row in rows
        for j, key in StrSplit(row)
            cells.Push({label: prefix key, back: back, mon: r.mon,
                l: r.l + Round((j - 1) * cw), t: r.t + Round((i - 1) * ch), r: r.l + Round(j * cw), b: r.t + Round(i * ch)})
    return cells
}

StartsAny(cells, prefix) {
    for label in cells
        if InStr(label, prefix) = 1
            return true
    return false
}

; One translucent, click-through window per monitor, labeling every cell.
ShowCells(cells) {
    groups := Map()
    for label, c in cells
        groups.Has(c.mon) ? groups[c.mon].Push(c) : (groups[c.mon] := [c])
    guis := []
    for mon, list in groups {
        l := t := 1e9, r := b := -1e9
        for c in list
            l := Min(l, c.l), t := Min(t, c.t), r := Max(r, c.r), b := Max(b, c.b)
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")  ; click-through once layered
        g.BackColor := LINE_COLOR
        c := list[1], px := Min((c.b - c.t) * 0.5, (c.r - c.l) / (0.8 * StrLen(c.label)))  ; text height that fits a cell
        g.SetFont("s" Max(1, Min(FONT_SIZE, Round(px * 72 / A_ScreenDPI))) " bold c" TEXT_COLOR, "Segoe UI")
        for c in list
            g.AddText("x" c.l - l + 1 " y" c.t - t + 1 " w" c.r - c.l - 1 " h" c.b - c.t - 1
                " Center 0x200 Background" c.back, StrUpper(c.label))  ; 0x200: vertically centered
        g.Show("NA x" l " y" t " w" r - l " h" b - t)
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
