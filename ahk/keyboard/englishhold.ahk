; English hold: while ENGLISH_HOLD_KEY is down the input mode is English, and on release it goes back to
; Hangul if it was Hangul before. The mode is read and set inside the hook, so a letter typed right after
; the press already comes in English. Keys held back by the other handlers go out first, in the old mode.
class EnglishHold {
    static held := false
    static restore := false  ; it was Hangul before the press

    static OnKey(key) {
        if key.vk != ENGLISH_HOLD_KEY
            return NEXT
        if key.down && !this.held {
            this.held := true
            ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
            focus := FocusedControl()
            this.restore := focus && IsHangul(focus)
            if this.restore
                PressHangulKey()
        } else if !key.down {
            this.held := false
            if this.restore && (focus := FocusedControl()) && !IsHangul(focus)
                PressHangulKey()
        }
        return SWALLOW
    }
}
