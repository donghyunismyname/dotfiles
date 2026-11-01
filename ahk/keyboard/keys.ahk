; Sending keys, as SendKeys input: [vk, sc, up, extended].

VK_LSHIFT := 0xA0, VK_RSHIFT := 0xA1, VK_HANGUL := 0x15, VK_LEFT := 0x25, VK_RIGHT := 0x27
VK_OEM_COMMA := 0xBC, VK_OEM_PERIOD := 0xBE

Down(vk, sc := 0, ext := false) => [vk, sc || ScanCode(vk), false, ext]
Up(vk, sc := 0, ext := false) => [vk, sc || ScanCode(vk), true, ext]
; A key event from the hook, sent on as it came.
AsInput(key) => [key.vk, key.sc, !key.down, key.ext]

ScanCode(vk) => DllCall("MapVirtualKey", "uint", vk, "uint", 0, "uint")  ; MAPVK_VK_TO_VSC

; Sent in one SendInput call, so nothing lands in between. Not marked as AutoHotkey's input, so the
; hotkeys of other scripts (ime/main.ahk's 한/영) see it.
SendKeys(keys*) {
    inputs := Buffer(40 * keys.Length, 0)  ; sizeof(INPUT) on x64
    for i, k in keys {
        p := 40 * (i - 1)
        NumPut("uint", 1, inputs, p)  ; INPUT_KEYBOARD
        NumPut("ushort", k[1], "ushort", k[2], "uint", (k[3] ? 2 : 0) | (k[4] ? 1 : 0), inputs, p + 8)  ; KEYEVENTF_KEYUP, _EXTENDEDKEY
    }
    DllCall("SendInput", "uint", keys.Length, "ptr", inputs, "int", 40)
}

PressHangulKey() => SendKeys(Down(VK_HANGUL), Up(VK_HANGUL))

IsModifier(vk) => vk >= 0x10 && vk <= 0x12 || vk >= 0xA0 && vk <= 0xA5 || vk = 0x5B || vk = 0x5C  ; Shift, Ctrl, Alt, Win

AnyModifierDown() => GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt")
    || GetKeyState("LWin") || GetKeyState("RWin")
