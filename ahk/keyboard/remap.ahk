; Deciding what each physical key event becomes. Needs keys.ahk, send.ahk (or a stand-in) and config.ahk.
;   combos.ahk       two keys pressed together: Shift (D+F, J+K) or an input mode (X+C, ,+.)
;   selectlayer.ahk  L then J: J / K select a character at a time while L is held
;   hangultap.ahk    a Left Shift tap presses 한/영
;   englishhold.ahk  English while F13 is held
#Include %A_LineFile%\..\combos.ahk
#Include %A_LineFile%\..\selectlayer.ahk
#Include %A_LineFile%\..\hangultap.ahk
#Include %A_LineFile%\..\englishhold.ahk

; What a handler's OnKey decides about a key event; NEXT leaves it to the next handler.
PASS := 0, SWALLOW := 1, NEXT := 2

ComboKeys.Init(COMBOS)

; key: {vk, sc, ext, down}. Returns true to swallow the event. The English hold goes first, as it lets
; the others' held-back keys go itself; the select layer goes before the combos, since J and K are in both.
OnKey(key) {
    static handlers := [EnglishHold, SelectLayer, ComboKeys]
    HangulTap.Watch(key)
    for handler in handlers
        if (decision := handler.OnKey(key)) != NEXT
            return decision = SWALLOW
    return false
}
