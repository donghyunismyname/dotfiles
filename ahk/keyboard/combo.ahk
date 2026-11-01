#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Combos: pressing both keys of a pair together (the second within COMBO_MS of the first) holds its
; modifier until either key is released; the other key is then ignored until it is released too.
; A lone combo key is held back until its partner, another key, its own release or COMBO_MS decides.
; Skipped while a modifier is already down, so Ctrl+D or a Shift-held J goes out at once.
; Uses its own low-level keyboard hook instead of hotkeys, so every key event is seen in order and a
; held-back key can be sent before the key that came after it. Injected input (Send, other scripts)
; passes through untouched.
; Also: tapping Left Shift alone (released within SHIFT_TAP_MS, no other key meanwhile) presses 한/영.
; Only a physical press counts, so the Left Shift of D+F does not.
; And: Shift+Space presses 한/영 for one word; the next Space presses it again before typing the space.

; ---- Config ----
COMBO_MS := 50
SHIFT_TAP_MS := 250
COMBOS := [
    {keys: [0x44, 0x46], out: 0xA0},  ; D+F: Left Shift
    {keys: [0x4A, 0x4B], out: 0xA1},  ; J+K: Right Shift
]

A_IconTip := "combo"
comboOf := Map()    ; vk -> its combo
for c in COMBOS {
    c.sc := DllCall("MapVirtualKey", "uint", c.out, "uint", 0, "uint"), c.active := false
    comboOf[c.keys[1]] := c, comboOf[c.keys[2]] := c
}
held := Map()       ; combo keys physically down
pending := 0        ; combo key held back, waiting for its partner
pendingSc := 0
swallow := Map()    ; combo keys ignored until released, after their combo ended
shiftAt := 0        ; when Left Shift went down, while it is down
shiftAlone := false ; no other key pressed since then
oneWord := false    ; 한/영 pressed by Shift+Space, to press again at the next Space
spaceHeld := false  ; the Space of Shift+Space, swallowed with its repeats until released
HANGUL_SC := DllCall("MapVirtualKey", "uint", 0x15, "uint", 0, "uint")

hook := DllCall("SetWindowsHookEx", "int", 13, "ptr", CallbackCreate(KeyboardProc), ; WH_KEYBOARD_LL
    "ptr", DllCall("GetModuleHandle", "ptr", 0, "ptr"), "uint", 0, "ptr")
OnExit(Cleanup)

KeyboardProc(nCode, wParam, lParam) {
    Critical
    flags := NumGet(lParam, 8, "uint")
    if nCode >= 0 && !(flags & 0x10)  ; LLKHF_INJECTED
        && OnKey(NumGet(lParam, 0, "uint"), NumGet(lParam, 4, "uint"), flags & 1, !(flags & 0x80))  ; LLKHF_EXTENDED, LLKHF_UP
        return 1
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam, "ptr")
}

; Returns true to swallow the event.
OnKey(vk, sc, ext, down) {
    global pending, pendingSc, shiftAt, shiftAlone, oneWord, spaceHeld
    if vk = 0xA0 {  ; VK_LSHIFT
        if down && !shiftAt  ; not a repeat
            shiftAt := A_TickCount, shiftAlone := true
        else if !down {
            if shiftAlone && A_TickCount - shiftAt < SHIFT_TAP_MS
                oneWord := false, SetTimer(PressHangulKey, -1)  ; out of the hook, after the Shift release goes out
            shiftAt := 0
        }
    } else if down
        shiftAlone := false
    if vk = 0x15 && down  ; a real 한/영 press sets the mode for good
        oneWord := false
    if vk = 0x20 {  ; VK_SPACE
        if spaceHeld {
            if !down
                spaceHeld := false
            return true
        }
        shift := GetKeyState("Shift") && !(GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("LWin") || GetKeyState("RWin"))
        if down && (shift || oneWord) {
            if pending
                Expire()
            ; Shift+Space again before a Space only switches back.
            oneWord := shift && !oneWord, spaceHeld := shift
            keys := [[0x15, HANGUL_SC, false], [0x15, HANGUL_SC, true]]
            if !shift
                keys.Push([vk, sc, false])  ; the space goes out after the switch back
            SendKeys(keys*)
            return true
        }
    }
    if !c := comboOf.Get(vk, 0) {
        if !pending
            return false
        ; Another key decides it: send the held-back key first, then this one.
        vkPending := pending, pending := 0, SetTimer(Expire, 0)
        SendKeys([vkPending, pendingSc, false], [vk, sc, !down, ext])
        return true
    }
    repeat := down && held.Has(vk)
    down ? held[vk] := true : held.Delete(vk)
    if swallow.Has(vk) {
        if !down
            swallow.Delete(vk)
        return true
    }
    partner := c.keys[1] = vk ? c.keys[2] : c.keys[1]
    if c.active {
        if !down {
            c.active := false
            SendKeys([c.out, c.sc, true])
            if held.Has(partner)
                swallow[partner] := true
        }
        return true
    }
    if pending = vk {
        if repeat
            return true
        ; Released before its partner came: a tap.
        pending := 0, SetTimer(Expire, 0)
        SendKeys([vk, sc, false], [vk, sc, true])
        return true
    }
    if pending = partner && down {
        pending := 0, SetTimer(Expire, 0)
        c.active := true
        SendKeys([c.out, c.sc, false])
        return true
    }
    if pending
        Expire()  ; a key of another combo: the held-back key goes first, alone
    if down && !repeat && !held.Has(partner) && !ModifierDown() {
        pending := vk, pendingSc := sc
        SetTimer(Expire, -COMBO_MS)
        return true
    }
    return false
}

ModifierDown() => GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt")
    || GetKeyState("LWin") || GetKeyState("RWin")

; No partner within COMBO_MS: the held-back key goes down as itself.
Expire() {
    global pending
    Critical
    if !pending
        return
    vk := pending, pending := 0
    SetTimer(Expire, 0)
    SendKeys([vk, pendingSc, false])
}

; SendLevel 1, so ime/main.ahk's 한/영 hotkey sees it and updates its tip.
PressHangulKey() {
    SendLevel(1)
    Send("{vk15}")
}

; Each key is [vk, sc, up, extended?]; sent in one SendInput call so nothing lands in between.
SendKeys(keys*) {
    inputs := Buffer(40 * keys.Length, 0)  ; sizeof(INPUT) on x64
    for i, k in keys {
        p := 40 * (i - 1)
        NumPut("uint", 1, inputs, p)  ; INPUT_KEYBOARD
        NumPut("ushort", k[1], "ushort", k[2], "uint", (k[3] ? 2 : 0) | (k.Length > 3 && k[4] ? 1 : 0), inputs, p + 8)
    }
    DllCall("SendInput", "uint", keys.Length, "ptr", inputs, "int", 40)
}

Cleanup(*) {
    DllCall("UnhookWindowsHookEx", "ptr", hook)
    for c in COMBOS
        if c.active
            SendKeys([c.out, c.sc, true])
}
