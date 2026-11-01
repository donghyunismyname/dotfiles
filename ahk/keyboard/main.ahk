#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\ime.ahk
#Include %A_LineFile%\..\keys.ahk
#Include %A_LineFile%\..\send.ahk
#Include %A_LineFile%\..\config.ahk
#Include %A_LineFile%\..\remap.ahk

; Key remapping (remap.ahk) through one low-level keyboard hook of its own instead of hotkeys, so every
; physical key event is seen in order and a held-back key can be sent before the key that came after it.

A_IconTip := "keyboard"
module := DllCall("GetModuleHandle", "ptr", 0, "ptr")
keyboardHook := DllCall("SetWindowsHookEx", "int", 13, "ptr", CallbackCreate(KeyboardProc), "ptr", module, "uint", 0, "ptr")  ; WH_KEYBOARD_LL
OnExit(Cleanup)

KeyboardProc(nCode, wParam, lParam) {
    Critical
    flags := NumGet(lParam, 8, "uint")
    if nCode >= 0 && OnKey({vk: NumGet(lParam, 0, "uint"), sc: NumGet(lParam, 4, "uint"),
            ext: flags & 1, down: !(flags & 0x80), injected: flags & 0x10})  ; LLKHF_EXTENDED, _UP, _INJECTED
        return 1
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam, "ptr")
}

Cleanup(*) {
    DllCall("UnhookWindowsHookEx", "ptr", keyboardHook)
    ComboKeys.EndAll()
}
