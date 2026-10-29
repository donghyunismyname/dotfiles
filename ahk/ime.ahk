#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\lib\util.ahk
#Include %A_LineFile%\..\lib\winevent.ahk
#Include %A_LineFile%\..\ime\caret.ahk

; Input mode: a small "한" / "A" box just below the text caret shows it, and it is kept the same
; across windows (Windows keeps one per window).
; Kept apart from panes/main.ahk: its calls into other apps can block for a while, and AHK has one thread,
; so inside it they would stall the mouse hook.
; Updated on window events (caret moved, text changed, focus or foreground changed) and the 한/영 key.

; ---- Config ----
HANGUL_COLOR := "2A5CC8"  ; RGB hex
ENGLISH_COLOR := "4A4A4A"
TEXT_COLOR := "E6E6E6"
UPDATE_DELAY_MS := 30     ; after an event, so a burst of events causes one update
EMPTY_LINE_H := 24        ; px; an empty field has no text to measure a line by

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
A_IconTip := "ime"
imeTip := ClickThroughGui(ENGLISH_COLOR)
imeTip.SetFont("s9 bold c" TEXT_COLOR, "Segoe UI")
imeLabel := imeTip.AddText("x0 y0 w20 h18 Center 0x200", "")  ; 0x200: vertically centered
HookWinEvents([EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_MOVESIZEEND, EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE,
    EVENT_OBJECT_FOCUS, EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_TEXTSELECTIONCHANGED,
    IA2_EVENT_TEXT_CARET_MOVED, IA2_EVENT_TEXT_INSERTED, IA2_EVENT_TEXT_REMOVED], OnImeEvent)
Hotkey("~vk15", (*) => SetTimer(UpdateImeTip, -UPDATE_DELAY_MS))  ; 한/영 key
UpdateImeTip()

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
        return imeTip.Hide()
    imeTip.BackColor := hangul ? HANGUL_COLOR : ENGLISH_COLOR
    imeLabel.Text := hangul ? "한" : "A"
    imeTip.Show("NA x" c.x " y" c.y + c.h + 2 " w20 h18")
}

; One mode for all windows: a newly focused control takes the mode last used, and a change made in
; the focused control becomes the mode to keep. Returns the focused control's mode.
SyncHangul(focus) {
    static lastFocus := 0, mode := -1
    hangul := IsHangul(focus)
    if focus != lastFocus && mode >= 0 && hangul != mode
        hangul := SetHangul(focus, mode)
    lastFocus := focus, mode := hangul
    return hangul
}

; Hangul mode of the window's IME: bit 0 (native) of its conversion mode.
IsHangul(hwnd) => ImeControl(hwnd, 1) & 1  ; IMC_GETCONVERSIONMODE

; Returns the mode afterwards, since an app may ignore the change.
SetHangul(hwnd, on) {
    ImeControl(hwnd, 2, ImeControl(hwnd, 1) & ~1 | on)  ; IMC_SETCONVERSIONMODE
    return IsHangul(hwnd)
}

; WM_IME_CONTROL to the window's default IME window; SMTO_ABORTIFHUNG, so a hung app cannot block this script.
ImeControl(hwnd, cmd, arg := 0) {
    ime := DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr")
    result := 0
    DllCall("SendMessageTimeoutW", "ptr", ime, "uint", 0x283, "ptr", cmd, "ptr", arg, "uint", 2, "uint", 100, "ptr*", &result)
    return result
}
