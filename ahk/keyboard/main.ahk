#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\ime.ahk
#Include %A_LineFile%\..\keys.ahk
#Include %A_LineFile%\..\combos.ahk
#Include %A_LineFile%\..\selectlayer.ahk
#Include %A_LineFile%\..\hangultap.ahk

; Key remapping through one low-level keyboard hook of its own instead of hotkeys, so every physical key
; event is seen in order and a held-back key can be sent before the key that came after it. Injected input
; (Send, other scripts, the keys this script sends) passes through untouched.
;   combos.ahk       two keys pressed together: Shift (D+F, J+K) or an input mode (X+C, ,+.)
;   selectlayer.ahk  L then J: J / K select a character at a time while L is held
;   hangultap.ahk    a Left Shift tap presses 한/영

; ---- Config ----
COMBO_MS := 50
COMBOS := [
    {keys: [Ord("D"), Ord("F")], shift: VK_LSHIFT},
    {keys: [Ord("J"), Ord("K")], shift: VK_RSHIFT},
    {keys: [Ord("X"), Ord("C")], hangul: false},  ; English
    {keys: [VK_OEM_COMMA, VK_OEM_PERIOD], hangul: true},
]
SELECT_LAYER_KEY := Ord("L")
SELECT_LAYER_START := Ord("J")  ; the key that turns the layer on
SELECT_LAYER_MS := 100
SELECT_LAYER_ARROWS := Map(Ord("J"), VK_LEFT, Ord("K"), VK_RIGHT)  ; sent with Shift
HANGUL_TAP_MS := 250

; What a handler's OnKey decides about a key event; NEXT leaves it to the next handler.
PASS := 0, SWALLOW := 1, NEXT := 2

A_IconTip := "keyboard"
ComboKeys.Init(COMBOS)
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

; Returns true to swallow the event. The select layer goes before the combos, since J and K are in both.
OnKey(key) {
    static handlers := [SelectLayer, ComboKeys]
    HangulTap.Watch(key)
    for handler in handlers
        if (decision := handler.OnKey(key)) != NEXT
            return decision = SWALLOW
    return false
}

Cleanup(*) {
    DllCall("UnhookWindowsHookEx", "ptr", hook)
    ComboKeys.EndAll()
}
