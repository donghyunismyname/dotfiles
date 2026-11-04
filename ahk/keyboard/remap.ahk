; Deciding what each key event becomes. Needs keys.ahk, send.ahk (or a stand-in) and config.ahk.
;   combos.ahk       two keys pressed together hold Shift (D+F, J+K)
;   selectlayer.ahk  L then J: J / K select a character at a time while L is held
;   shifttaps.ahk    a Left Shift tap presses 한/영
;   modelayer.ahk    the other input mode while F13 is held, with ` on Esc, ~ on Tab and Shift on Space
#Include %A_LineFile%\..\combos.ahk
#Include %A_LineFile%\..\selectlayer.ahk
#Include %A_LineFile%\..\shifttaps.ahk
#Include %A_LineFile%\..\modelayer.ahk

; What a handler's OnKey decides about a key event; NEXT leaves it to the next handler.
PASS := 0, SWALLOW := 1, NEXT := 2

ComboKeys.Init(COMBOS)

; key: {vk, sc, ext, down, injected}. Returns true to swallow the event. Injected events (Send, other
; scripts, the keys sent here) pass untouched. The mode layer goes first, as it lets the others' held-back
; keys go itself; the select layer goes before the combos, since J and K are in both.
OnKey(key) {
    static handlers := [ModeLayer, SelectLayer, ComboKeys]
    if key.injected
        return false
    ShiftTaps.Watch(key)
    for handler in handlers
        if (decision := handler.OnKey(key)) != NEXT
            return decision = SWALLOW
    return false
}
