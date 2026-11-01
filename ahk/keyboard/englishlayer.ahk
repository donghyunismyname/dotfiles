; English layer: while ENGLISH_LAYER_KEY is down the input mode is English, and on release it goes back to
; Hangul if it was Hangul before. Meanwhile the keys of ENGLISH_LAYER_MAP send what it maps them to, once
; per press or key repeat, with any modifier held; letters stay letters, so English can be typed through it.
; The mode is read and set inside the hook, so a letter typed right after the press already comes in
; English. Keys held back by the other handlers go out first, in the old mode.
class EnglishLayer {
    static held := false
    static restore := false     ; it was Hangul before the press
    static mappedKeys := Map()  ; keys pressed as their mapping, ignored until released

    static OnKey(key) {
        vk := key.vk
        if vk = ENGLISH_LAYER_KEY {
            if key.down && !this.held
                this.Start()
            else if !key.down
                this.End()
            return SWALLOW
        }
        if this.held && key.down && ENGLISH_LAYER_MAP.Has(vk) {
            ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
            this.mappedKeys[vk] := true
            out := ENGLISH_LAYER_MAP[vk], sequence := [Down(out.vk), Up(out.vk)]
            if out.HasProp("shift")
                sequence.InsertAt(1, Down(VK_LSHIFT)), sequence.Push(Up(VK_LSHIFT))
            SendKeys(sequence*)
            return SWALLOW
        }
        if this.mappedKeys.Has(vk) {  ; its release, or a repeat after the layer key was released
            if !key.down
                this.mappedKeys.Delete(vk)
            return SWALLOW
        }
        return NEXT
    }

    static Start() {
        this.held := true
        ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
        focus := FocusedControl()
        this.restore := focus && IsHangul(focus)
        if this.restore
            PressHangulKey()
    }

    static End() {
        this.held := false
        if this.restore && (focus := FocusedControl()) && !IsHangul(focus)
            PressHangulKey()
    }
}
