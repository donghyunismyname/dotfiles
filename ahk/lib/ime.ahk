; Reading and setting the Hangul input mode of another app's window.

; The control with the keyboard focus in the foreground window, or 0. Unlike ControlGetFocus("A"), this
; also works in the Claude desktop app, where AutoHotkey fails to find the active window.
FocusedControl() {
    info := Buffer(72, 0)  ; GUITHREADINFO
    NumPut("uint", 72, info)
    return DllCall("GetGUIThreadInfo", "uint", 0, "ptr", info) ? NumGet(info, 16, "ptr") : 0
}

; Sets the focused control's mode by pressing the 한/영 key when it differs, rather than with SetHangul,
; so the syllable being composed is finished first as on a real press. SendLevel 1, so ime/main.ahk's
; 한/영 hotkey sees it.
SwitchHangul(on) {
    if !(focus := FocusedControl()) || IsHangul(focus) = on
        return
    SendLevel(1)
    Send("{vk15}")
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
