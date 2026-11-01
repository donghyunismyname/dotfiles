#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\ime.ahk

; Combos: pressing both keys of a pair together (the second within COMBO_MS of the first) starts it.
; A shift combo holds its Shift until either key is released; a mode combo sets the input mode.
; The other key is then ignored until it is released too.
; A lone combo key is held back until its partner, another key, its own release or COMBO_MS decides.
; Skipped while a modifier is already down, so Ctrl+D or a Shift-held J goes out at once.
; Tapping Left Shift alone (released within SHIFT_TAP_MS, no other key meanwhile) presses 한/영.
; L is held back for LAYER_MS: a J pressed meanwhile (before L is released) is Shift+Left, and from then on
; until L is released every J or K press or key repeat is Shift+Left / Shift+Right. Otherwise L goes out
; as the letter, so a typed "lk" (walk, milk) stays letters.
; Uses its own low-level keyboard hook instead of hotkeys, so every key event is seen in order and a
; held-back key can be sent before the key that came after it. Injected input (Send, other scripts,
; the Shift of a combo) passes through untouched, so a combo's Shift is never a tap.

; ---- Config ----
COMBO_MS := 50
SHIFT_TAP_MS := 250
LAYER_KEY := 0x4C                                 ; L
LAYER_MS := 100
LAYER_START := 0x4A                               ; J
LAYER_ARROWS := Map(0x4A, 0x25, 0x4B, 0x27)       ; J: Shift+Left, K: Shift+Right
COMBOS := [
    {keys: [0x44, 0x46], shift: 0xA0},    ; D+F: Left Shift
    {keys: [0x4A, 0x4B], shift: 0xA1},    ; J+K: Right Shift
    {keys: [0x58, 0x43], hangul: false},  ; X+C: English
    {keys: [0xBC, 0xBE], hangul: true},   ; ,+.: Hangul
]

VK_LSHIFT := 0xA0, VK_HANGUL := 0x15
A_IconTip := "combo"
comboOf := Map()      ; vk -> its combo
for c in COMBOS {
    c.active := false
    if c.HasProp("shift")
        c.sc := ScanCode(c.shift)
    comboOf[c.keys[1]] := c, comboOf[c.keys[2]] := c
}
held := Map()         ; combo keys physically down
swallow := Map()      ; combo keys ignored until released, after their combo ended
pending := ""         ; {vk, sc} of the combo key held back, waiting for its partner
shiftDownAt := 0      ; when Left Shift went down, while it is down
shiftAlone := false   ; no other key pressed since then
layer := ""           ; "" off, "maybe" while L is held back, "on" once J came in time
layerSc := 0
layerKeyDown := false ; L physically down, to tell its key repeats from a new press
layerOwned := Map()   ; J / K pressed as arrows, swallowed until released

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
    global pending
    WatchShiftTap(vk, down)
    if layer || vk = LAYER_KEY || layerOwned.Has(vk)
        if (r := OnLayerKey(vk, sc, ext, down)) != ""
            return r
    if !c := comboOf.Get(vk, 0) {
        if !pending
            return false
        ; Another key decides it: send the held-back key first, then this one.
        p := TakePending()
        SendKeys([p.vk, p.sc, false], [vk, sc, !down, ext])
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
        if !down
            EndCombo(c, partner)
        return true
    }
    if pending && pending.vk = vk {
        if !repeat {  ; released before its partner came: a tap
            TakePending()
            SendKeys([vk, sc, false], [vk, sc, true])
        }
        return true
    }
    if pending && pending.vk = partner && down {
        TakePending()
        StartCombo(c)
        return true
    }
    if pending
        Expire()  ; a key of another combo: the held-back key goes first, alone
    if down && !repeat && !held.Has(partner) && !ModifierDown() {
        pending := {vk: vk, sc: sc}
        SetTimer(Expire, -COMBO_MS)
        return true
    }
    return false
}

StartCombo(c) {
    c.active := true
    if c.HasProp("shift")
        SendKeys([c.shift, c.sc, false])
    else
        SetTimer(SetMode.Bind(c.hangul), -1)  ; out of the hook, which must return quickly
}

EndCombo(c, partner) {
    c.active := false
    if c.HasProp("shift")
        SendKeys([c.shift, c.sc, true])
    if held.Has(partner)
        swallow[partner] := true
}

; The L layer's part of OnKey: true or false as OnKey returns, or "" to go on to the combos.
OnLayerKey(vk, sc, ext, down) {
    global layer, layerSc, layerKeyDown
    static shiftSc := ScanCode(VK_LSHIFT)
    if vk = LAYER_KEY {
        repeat := down && layerKeyDown
        layerKeyDown := down
        if !layer {
            if !down || repeat || ModifierDown()  ; Ctrl+L and the like, or an L already let out
                return false
            if pending
                Expire()  ; the held-back combo key goes first
            layer := "maybe", layerSc := sc
            SetTimer(LayerExpire, -LAYER_MS)
            return true
        }
        if repeat
            return true
        if layer = "maybe"  ; released before J: the letter
            SendKeys([vk, sc, false], [vk, sc, true])
        EndLayer()
        return true
    }
    if down && (layer = "on" && LAYER_ARROWS.Has(vk) || layer = "maybe" && vk = LAYER_START) {
        layer := "on", SetTimer(LayerExpire, 0)
        arrow := LAYER_ARROWS[vk], arrowSc := ScanCode(arrow), layerOwned[vk] := true
        SendKeys([VK_LSHIFT, shiftSc, false], [arrow, arrowSc, false, true], [arrow, arrowSc, true, true],
            [VK_LSHIFT, shiftSc, true])
        return true
    }
    if layerOwned.Has(vk) {  ; its release, or a repeat after L was released
        if !down
            layerOwned.Delete(vk)
        return true
    }
    if down && layer = "maybe"  ; another key first: L was the letter, still held
        LayerExpire()
    return ""
}

; No J within LAYER_MS: the held-back L goes down as itself.
LayerExpire() {
    Critical
    if layer = "maybe" {
        SendKeys([LAYER_KEY, layerSc, false])
        EndLayer()
    }
}

EndLayer() {
    global layer
    layer := ""
    SetTimer(LayerExpire, 0)
}

; A physical Left Shift released within SHIFT_TAP_MS with no other key pressed meanwhile presses 한/영.
WatchShiftTap(vk, down) {
    global shiftDownAt, shiftAlone
    if vk != VK_LSHIFT {
        if down
            shiftAlone := false
    } else if down {
        if !shiftDownAt  ; not a repeat
            shiftDownAt := A_TickCount, shiftAlone := true
    } else {
        if shiftAlone && A_TickCount - shiftDownAt < SHIFT_TAP_MS
            SetTimer(PressHangulKey, -1)  ; out of the hook, after the Shift release goes out
        shiftDownAt := 0
    }
}

ModifierDown() => GetKeyState("Shift") || GetKeyState("Ctrl") || GetKeyState("Alt")
    || GetKeyState("LWin") || GetKeyState("RWin")

; No partner within COMBO_MS: the held-back key goes down as itself.
Expire() {
    Critical
    if p := TakePending()
        SendKeys([p.vk, p.sc, false])
}

; Stops waiting for the held-back key's partner and returns the key, or "" when there is none.
TakePending() {
    global pending
    p := pending, pending := ""
    SetTimer(Expire, 0)
    return p
}

; Presses 한/영 when the focused control's mode differs; the IME then finishes the syllable being
; composed first, as on a real press, which SetHangul would not.
SetMode(hangul) {
    if (focus := FocusedControl()) && IsHangul(focus) != hangul
        PressHangulKey()
}

; ime/main.ahk's 한/영 hotkey sees it, since it is not sent by AutoHotkey's Send.
PressHangulKey() {
    static sc := ScanCode(VK_HANGUL)
    SendKeys([VK_HANGUL, sc, false], [VK_HANGUL, sc, true])
}

ScanCode(vk) => DllCall("MapVirtualKey", "uint", vk, "uint", 0, "uint")  ; MAPVK_VK_TO_VSC

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
            EndCombo(c, 0)
}
