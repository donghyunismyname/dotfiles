; Sending keys built with keys.ahk; main.test.ahk records them instead.

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
