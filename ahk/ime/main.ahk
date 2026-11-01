#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\winevent.ahk
#Include %A_LineFile%\..\..\lib\ime.ahk
#Include %A_LineFile%\..\caret.ahk

; Input mode: a small "가" / "A" box just below the text caret and another by the mouse cursor show it,
; and it is kept the same across windows (Windows keeps one per window).
; Kept apart from panes/main.ahk: its calls into other apps can block for a while, and AHK has one thread,
; so inside it they would stall the mouse hook.
; The caret's box is updated on window events (caret moved, text changed, focus or foreground changed) and
; the 한/영 key; the mouse's box follows the cursor by polling, showing the mode last seen at a caret.

; ---- Config ----
HANGUL_COLOR := "2A5CC8"  ; RGB hex
ENGLISH_COLOR := "4A4A4A"
TEXT_COLOR := "E6E6E6"
UPDATE_DELAY_MS := 30     ; after an event, so a burst of events causes one update
EMPTY_LINE_H := 24        ; px; an empty field has no text to measure a line by
MOUSE_POLL_MS := 15
MOUSE_TIP_DX := 16        ; px from the cursor's hotspot to the box, clear of the arrow
MOUSE_TIP_DY := 24

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
A_IconTip := "ime"
caretTip := ImeTip(), mouseTip := ImeTip()
imeMode := -1  ; 1 Hangul, 0 English, -1 not seen yet
HookWinEvents([EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_MOVESIZEEND, EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE,
    EVENT_OBJECT_FOCUS, EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_TEXTSELECTIONCHANGED,
    IA2_EVENT_TEXT_CARET_MOVED, IA2_EVENT_TEXT_INSERTED, IA2_EVENT_TEXT_REMOVED], OnImeEvent)
Hotkey("~vk15", (*) => SetTimer(UpdateImeTip, -UPDATE_DELAY_MS))  ; 한/영 key, also sent by keyboard/combo.ahk
UpdateImeTip()
SetTimer(UpdateMouseTip, MOUSE_POLL_MS)

; Location changes come from every window and the cursor; only the caret's matter.
OnImeEvent(event, hwnd, idObject) {
    if event != EVENT_OBJECT_LOCATIONCHANGE || idObject = OBJID_CARET
        SetTimer(UpdateImeTip, -UPDATE_DELAY_MS)
}

UpdateImeTip() {
    static last := ""
    key := ""
    try {
        if c := FocusCaret()
            hangul := SyncHangul(c.focus), key := c.x "," c.y "," c.h "," hangul
    }
    if key = last
        return
    last := key
    if !key
        return caretTip.gui.Hide()
    ShowTip(caretTip, hangul, c.x, c.y + c.h + 2)
}

; Hidden while the cursor is (some apps hide it while typing) and until a mode has been seen.
UpdateMouseTip() {
    static last := "", ci := Buffer(24, 0)  ; CURSORINFO
    NumPut("uint", 24, ci)
    shown := imeMode >= 0 && DllCall("GetCursorInfo", "ptr", ci) && NumGet(ci, 4, "uint") & 1  ; CURSOR_SHOWING
    x := NumGet(ci, 16, "int") + MOUSE_TIP_DX, y := NumGet(ci, 20, "int") + MOUSE_TIP_DY
    key := shown ? x "," y "," imeMode : ""
    if key = last
        return
    last := key
    if !shown
        return mouseTip.gui.Hide()
    ShowTip(mouseTip, imeMode, x, y)
}

; A box with a label, hidden until shown.
ImeTip() {
    g := ClickThroughGui(ENGLISH_COLOR)
    g.SetFont("s9 bold c" TEXT_COLOR, "Segoe UI")
    return {gui: g, label: g.AddText("x0 y0 w20 h18 Center 0x200", ""), hangul: -1}  ; 0x200: vertically centered
}

ShowTip(tip, hangul, x, y) {
    if tip.hangul != hangul {
        tip.hangul := hangul
        tip.gui.BackColor := hangul ? HANGUL_COLOR : ENGLISH_COLOR
        tip.label.Text := hangul ? "가" : "A"
    }
    tip.gui.Show("NA x" x " y" y " w20 h18")
}

; One mode for all windows: a newly focused control takes the mode last used, and a change made in
; the focused control becomes the mode to keep. Returns the focused control's mode.
SyncHangul(focus) {
    global imeMode
    static lastFocus := 0
    hangul := IsHangul(focus)
    if focus != lastFocus && imeMode >= 0 && hangul != imeMode
        hangul := SetHangul(focus, imeMode)
    lastFocus := focus, imeMode := hangul
    return hangul
}
