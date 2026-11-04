; Keys as SendKeys (send.ahk) takes them: [vk, sc, up, extended].

VK_LSHIFT := 0xA0, VK_RSHIFT := 0xA1, VK_HANGUL := 0x15, VK_LEFT := 0x25, VK_RIGHT := 0x27
VK_OEM_3 := 0xC0  ; `~
VK_ESC := 0x1B, VK_TAB := 0x09, VK_SPACE := 0x20, VK_F13 := 0x7C

Down(vk, sc := 0, ext := false) => [vk, sc || ScanCode(vk), false, ext]
Up(vk, sc := 0, ext := false) => [vk, sc || ScanCode(vk), true, ext]
; A key event from the hook, sent on as it came.
AsInput(key) => [key.vk, key.sc, !key.down, key.ext]

ScanCode(vk) => DllCall("MapVirtualKey", "uint", vk, "uint", 0, "uint")  ; MAPVK_VK_TO_VSC

PressHangulKey() => SendKeys(Down(VK_HANGUL), Up(VK_HANGUL))

; Presses 한/영 as often as it takes to reach the other input mode (HangulKeyPresses).
ToggleInputMode(focus := 0) {
    if focus := focus || FocusedControl()
        loop HangulKeyPresses(focus)
            PressHangulKey()
}

AnyModifierDown() => GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt") || WinKeyDown()
WinKeyDown() => GetKeyState("LWin") || GetKeyState("RWin")
