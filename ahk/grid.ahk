#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\lib\admin.ahk

; Keyboard mouse jump.
;   Ctrl+Space  covers MONITOR with a grid of keys laid out like the keyboard (ROWS);
;               pressing a key moves the cursor to the center of its cell. Any other key cancels.
; Keys are read by their physical position (virtual key), so the Hangul input mode does not matter,
; and Ctrl may still be held from the hotkey.

; ---- Config ----
MONITOR := 1             ; the landscape monitor, as in zones.ahk
ROWS := ["qweruiop", "asdfjkl;", "zxcvm,./"]
KEY_SHOW := "^Space"
TIMEOUT_S := 10
FONT_SIZE := 28
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
    cw := (r - l) / StrLen(ROWS[1]), ch := (b - t) / ROWS.Length
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")  ; click-through once layered
    g.BackColor := LINE_COLOR
    g.SetFont("s" FONT_SIZE " bold c" TEXT_COLOR, "Segoe UI")
    cells := Map()
    for i, row in ROWS
        for j, key in StrSplit(row) {
            x1 := Round((j - 1) * cw), x2 := Round(j * cw), y1 := Round((i - 1) * ch), y2 := Round(i * ch)
            g.AddText("x" x1 + 1 " y" y1 + 1 " w" x2 - x1 - 1 " h" y2 - y1 - 1 " Center 0x200 Background" BACK_COLOR, StrUpper(key))  ; 0x200: vertically centered
            cells[key] := {x: l + (x1 + x2) // 2, y: t + (y1 + y2) // 2}
        }
    g.Show("NA x" l " y" t " w" r - l " h" b - t)
    WinSetTransparent(BACK_ALPHA, g)

    state := {pick: ""}
    ih := InputHook("T" TIMEOUT_S)
    ih.KeyOpt("{All}", "NS")  ; every key down is reported and blocked
    ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-NS")  ; modifiers pass, so a held Ctrl does not cancel
    ih.OnKeyDown := (ih, vk, sc) => (state.pick := cells.Get(GetKeyName(Format("vk{:x}sc{:x}", vk, sc)), ""), ih.Stop())
    ih.Start()
    ih.Wait()
    g.Destroy()
    if state.pick
        MouseMove(state.pick.x, state.pick.y, 0)
}
