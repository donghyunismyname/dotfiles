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
; Injected input (Send, other scripts, the keys this script sends) passes through untouched.

A_IconTip := "keyboard"
hook := DllCall("SetWindowsHookEx", "int", 13, "ptr", CallbackCreate(KeyboardProc), ; WH_KEYBOARD_LL
    "ptr", DllCall("GetModuleHandle", "ptr", 0, "ptr"), "uint", 0, "ptr")
OnExit(Cleanup)

KeyboardProc(nCode, wParam, lParam) {
    Critical
    flags := NumGet(lParam, 8, "uint")
    if nCode >= 0 && !(flags & 0x10)  ; LLKHF_INJECTED
        && OnKey({vk: NumGet(lParam, 0, "uint"), sc: NumGet(lParam, 4, "uint"), ext: flags & 1, down: !(flags & 0x80)})  ; LLKHF_EXTENDED, LLKHF_UP
        return 1
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam, "ptr")
}

Cleanup(*) {
    DllCall("UnhookWindowsHookEx", "ptr", hook)
    ComboKeys.EndAll()
}
