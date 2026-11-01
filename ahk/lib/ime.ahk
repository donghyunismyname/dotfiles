; Reading and setting the Hangul input mode of another app's window. Needs util.ahk.

; The control with the keyboard focus in the foreground window, or 0. Unlike ControlGetFocus("A"), this
; also works in the Claude desktop app, where AutoHotkey fails to find the active window.
FocusedControl() {
    info := GuiThreadInfo()
    return info ? NumGet(info, 16, "ptr") : 0
}

; Hangul mode of the window's IME: bit 0 (native) of its conversion mode.
IsHangul(hwnd) => ImeControl(hwnd, 1) & 1  ; IMC_GETCONVERSIONMODE

; Returns the mode afterwards, since an app may ignore the change.
SetHangul(hwnd, on) {
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
