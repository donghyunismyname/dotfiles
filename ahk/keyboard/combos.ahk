; Combos: pressing both keys of a pair together (the second within COMBO_MS of the first) starts one.
; A shift combo holds its Shift until either key is released; a mode combo sets the input mode.
; The other key is then ignored until it is released too.
; A lone combo key is held back until its partner, another key, its own release or COMBO_MS decides.
; Skipped while a modifier is already down, so Ctrl+D or a Shift-held J goes out at once.
class ComboKeys {
    static combos := []
    static byKey := Map()    ; vk -> its combo
    static pressed := Map()  ; combo keys physically down
    static ignored := Map()  ; combo keys ignored until released, after their combo ended
    static heldBack := ""    ; the combo key waiting for its partner: {vk, sc}
    static timeout := ObjBindMethod(this, "LetHeldBackGo")

    static Init(pairs) {
        this.combos := pairs
        for c in pairs {
            c.active := false
            this.byKey[c.keys[1]] := c, this.byKey[c.keys[2]] := c
        }
    }

    static OnKey(key) {
        vk := key.vk
        if !c := this.byKey.Get(vk, 0) {
            if !this.heldBack
                return PASS
            ; Another key decides it: the held-back key goes first, then this one.
            k := this.TakeHeldBack()
            SendKeys(Down(k.vk, k.sc), AsInput(key))
            return SWALLOW
        }
        repeat := key.down && this.pressed.Has(vk)
        if key.down
            this.pressed[vk] := true
        else
            this.pressed.Delete(vk)
        if this.ignored.Has(vk) {
            if !key.down
                this.ignored.Delete(vk)
            return SWALLOW
        }
        partner := c.keys[1] = vk ? c.keys[2] : c.keys[1]
        if c.active {
            if !key.down
                this.End(c, partner)
            return SWALLOW
        }
        if this.IsHeldBack(vk) {
            if !repeat {  ; released before its partner came: a tap
                this.TakeHeldBack()
                SendKeys(Down(vk, key.sc), Up(vk, key.sc))
            }
            return SWALLOW
        }
        if this.IsHeldBack(partner) && key.down {
            this.TakeHeldBack()
            this.Start(c)
            return SWALLOW
        }
        this.LetHeldBackGo()  ; a key of another combo: the held-back key goes first, alone
        if key.down && !repeat && !this.pressed.Has(partner) && !AnyModifierDown() {
            this.heldBack := {vk: vk, sc: key.sc}
            SetTimer(this.timeout, -COMBO_MS)
            return SWALLOW
        }
        return PASS
    }

    static Start(c) {
        c.active := true
        if c.HasProp("shift")
            SendKeys(Down(c.shift))
        else
            SetTimer(ObjBindMethod(this, "SetInputMode", c.hangul), -1)  ; out of the hook, which must return quickly
    }

    static End(c, partner := 0) {
        c.active := false
        if c.HasProp("shift")
            SendKeys(Up(c.shift))
        if this.pressed.Has(partner)
            this.ignored[partner] := true
    }

    ; Ends the combos still on, on exit, so no Shift stays down.
    static EndAll() {
        for c in this.combos
            if c.active
                this.End(c)
    }

    ; The held-back key goes down as itself: on timeout, or before a key that came after it.
    static LetHeldBackGo() {
        Critical
        if k := this.TakeHeldBack()
            SendKeys(Down(k.vk, k.sc))
    }

    ; Stops waiting for the held-back key's partner and returns the key, or "" when there is none.
    static TakeHeldBack() {
        k := this.heldBack, this.heldBack := ""
        SetTimer(this.timeout, 0)
        return k
    }

    static IsHeldBack(vk) => this.heldBack && this.heldBack.vk = vk

    ; Presses 한/영 when the focused control's mode differs; the IME then finishes the syllable being
    ; composed first, as on a real press, which SetHangul would not.
    static SetInputMode(hangul) {
        if (focus := FocusedControl()) && IsHangul(focus) != hangul
            PressHangulKey()
    }
}
