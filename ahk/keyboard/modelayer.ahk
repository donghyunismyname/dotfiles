; Mode layer: while MODE_LAYER_KEY is down the input mode is the other one (Hangul <-> English), and on
; release it goes back to the mode from before the press. A tap (released within MODE_LAYER_TAP_MS, no
; other key pressed meanwhile) keeps the other mode instead, so it toggles. Meanwhile the keys of
; MODE_LAYER_MAP send what it maps them to, once per press or key repeat, with any modifier held, and
; MODE_LAYER_SHIFT_KEY holds Shift until it is released; letters stay letters.
; The mode is read and set inside the hook, so a letter typed right after the press already comes in the
; other mode. Keys held back by the other handlers go out first, in the old mode.
class ModeLayer {
    static held := false
    static wasHangul := false   ; the mode before the press
    static pressedAt := 0
    static alone := false       ; no other key pressed since the press
    static mappedKeys := Map()  ; keys pressed as their mapping, ignored until released

    static OnKey(key) {
        vk := key.vk
        if vk = MODE_LAYER_KEY {
            if key.down && !this.held
                this.Start()
            else if !key.down
                this.End()
            return SWALLOW
        }
        if key.down
            this.alone := false
        if this.held && key.down && vk = MODE_LAYER_SHIFT_KEY {
            if !this.mappedKeys.Has(vk) {  ; not a repeat
                ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
                this.mappedKeys[vk] := true
                SendKeys(Down(VK_LSHIFT))
            }
            return SWALLOW
        }
        if this.held && key.down && MODE_LAYER_MAP.Has(vk) {
            ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
            this.mappedKeys[vk] := true
            out := MODE_LAYER_MAP[vk], sequence := [Down(out.vk), Up(out.vk)]
            if out.HasProp("shift")
                sequence.InsertAt(1, Down(VK_LSHIFT)), sequence.Push(Up(VK_LSHIFT))
            SendKeys(sequence*)
            return SWALLOW
        }
        if this.mappedKeys.Has(vk) {  ; its release, or a repeat after the layer key was released
            if !key.down {
                this.mappedKeys.Delete(vk)
                if vk = MODE_LAYER_SHIFT_KEY
                    SendKeys(Up(VK_LSHIFT))
            }
            return SWALLOW
        }
        return NEXT
    }

    static Start() {
        this.held := true, this.pressedAt := A_TickCount, this.alone := true
        ComboKeys.LetHeldBackGo(), SelectLayer.LetTriggerGo()
        focus := FocusedControl()
        this.wasHangul := focus && IsHangul(focus)
        ToggleInputMode(focus)
    }

    ; Leaves the mode alone when it is already back, as when 한/영 was pressed meanwhile.
    static End() {
        this.held := false
        if this.alone && A_TickCount - this.pressedAt < MODE_LAYER_TAP_MS  ; a tap: the switch stays
            return
        if (focus := FocusedControl()) && IsHangul(focus) != this.wasHangul
            ToggleInputMode(focus)
    }
}
