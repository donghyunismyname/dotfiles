; Deciding what each key event becomes. Needs keys.ahk, send.ahk (or a stand-in) and config.ahk.
;   combos.ahk       two keys pressed together: Shift (D+F, J+K) or an input mode (X+C, ,+.)
;   selectlayer.ahk  L then J: J / K select a character at a time while L is held
;   shifttaps.ahk    a Left Shift tap presses 한/영, a Right Shift tap converts the last word
;   modelayer.ahk    the other input mode while F13 is held, with F1-F12 on the number row, ` on Esc, ~ on Tab
;   lastword.ahk     the last word typed, to retype in the other input mode
#Include %A_LineFile%\..\combos.ahk
#Include %A_LineFile%\..\selectlayer.ahk
#Include %A_LineFile%\..\shifttaps.ahk
#Include %A_LineFile%\..\modelayer.ahk
#Include %A_LineFile%\..\lastword.ahk

; What a handler's OnKey decides about a key event; NEXT leaves it to the next handler.
PASS := 0, SWALLOW := 1, NEXT := 2

ComboKeys.Init(COMBOS)

; key: {vk, sc, ext, down, injected}. Returns true to swallow the event. Injected events (Send, other
; scripts, the keys sent here) pass untouched. The mode layer goes first, as it lets the others' held-back
; keys go itself; the select layer goes before the combos, since J and K are in both.
OnKey(key) {
    static handlers := [ModeLayer, SelectLayer, ComboKeys]
    if key.injected {
        LastWord.See(key)
        return false
    }
    ShiftTaps.Watch(key)
    for handler in handlers
        if (decision := handler.OnKey(key)) != NEXT {
            if decision = PASS
                LastWord.See(key)
            return decision = SWALLOW
        }
    LastWord.See(key)
    return false
}

; A click may move the caret, so the last word is no longer right before it.
OnMouseDown() => LastWord.Reset()
