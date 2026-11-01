; Reading and setting the Hangul input mode of another app's window. Needs util.ahk.

; The control with the keyboard focus in the foreground window, or 0. Unlike ControlGetFocus("A"), this
; also works in the Claude desktop app, where AutoHotkey fails to find the active window.
FocusedControl() {
    info := GuiThreadInfo()
    return info ? NumGet(info, 16, "ptr") : 0
}

; Hangul mode of the window's IME: open, and bit 0 (native) of its conversion mode set. A closed IME types
; English whatever that bit says, as a new window's often is until 한/영 is first pressed.
IsHangul(hwnd) => ImeControl(hwnd, 5) && ImeControl(hwnd, 1) & 1  ; IMC_GETOPENSTATUS, IMC_GETCONVERSIONMODE

; 한/영 presses that reach the other mode: the first press on a closed IME only opens it, keeping the
; conversion mode, so from closed with that mode English it takes two.
HangulKeyPresses(hwnd) => !ImeControl(hwnd, 5) && !(ImeControl(hwnd, 1) & 1) ? 2 : 1

; Returns the mode afterwards, since an app may ignore the change.
SetHangul(hwnd, on) {
    if on
        ImeControl(hwnd, 6, 1)  ; IMC_SETOPENSTATUS
    ImeControl(hwnd, 2, ImeControl(hwnd, 1) & ~1 | on)  ; IMC_SETCONVERSIONMODE
    return IsHangul(hwnd)
}

; WM_IME_CONTROL to the window's default IME window; SMTO_ABORTIFHUNG, so a hung app cannot block the script.
ImeControl(hwnd, cmd, arg := 0) {
    ime := DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr")
    result := 0
    DllCall("SendMessageTimeoutW", "ptr", ime, "uint", 0x283, "ptr", cmd, "ptr", arg, "uint", 2, "uint", 100, "ptr*", &result)
    return result
}
