; Select layer: L is held back for SELECT_LAYER_MS. A J pressed meanwhile, before L is released, turns
; the layer on, and until L is released every J or K press or key repeat is Shift+Left / Shift+Right.
; Otherwise L goes out as the letter, so a typed "lk" (walk, milk) stays letters.
; Modifiers pressed in between pass and keep the wait, so L, Ctrl, J is Ctrl+Shift+Left (a word).
; Skipped while a modifier is already down, so Ctrl+L goes out at once.
class SelectLayer {
    static state := ""            ; "" off, "waiting" for J while L is held back, "on"
    static triggerSc := 0
    static triggerDown := false   ; L physically down, to tell its key repeats from a new press
    static arrowKeys := Map()     ; J / K pressed as arrows, ignored until released
    static timeout := ObjBindMethod(this, "LetTriggerGo")

    static OnKey(key) {
        vk := key.vk
        if vk = SELECT_LAYER_KEY
            return this.OnTrigger(key)
        if key.down && (this.state = "on" && SELECT_LAYER_ARROWS.Has(vk) || this.state = "waiting" && vk = SELECT_LAYER_START) {
            this.SetState("on")
            arrow := SELECT_LAYER_ARROWS[vk], this.arrowKeys[vk] := true
            SendKeys(Down(VK_LSHIFT), Down(arrow, , true), Up(arrow, , true), Up(VK_LSHIFT))
            return SWALLOW
        }
        if this.arrowKeys.Has(vk) {  ; its release, or a repeat after L was released
            if !key.down
                this.arrowKeys.Delete(vk)
            return SWALLOW
        }
        if key.down && this.state = "waiting" && !IsModifier(vk)  ; another key first: L was the letter, still held
            this.LetTriggerGo()
        return NEXT
    }

    static OnTrigger(key) {
        repeat := key.down && this.triggerDown
        this.triggerDown := key.down
        if !this.state {
            if !key.down || repeat || AnyModifierDown()  ; Ctrl+L and the like, or an L already let go
                return PASS
            ComboKeys.LetHeldBackGo()  ; a held-back combo key goes first
            this.SetState("waiting"), this.triggerSc := key.sc
            SetTimer(this.timeout, -SELECT_LAYER_MS)
            return SWALLOW
        }
        if repeat
            return SWALLOW
        if this.state = "waiting"  ; released before J: the letter
            SendKeys(Down(key.vk, key.sc), Up(key.vk, key.sc))
        this.SetState("")
        return SWALLOW
    }

    ; No J within SELECT_LAYER_MS, or another key came first: the held-back L goes down as itself.
    static LetTriggerGo() {
        Critical
        if this.state = "waiting" {
            SendKeys(Down(SELECT_LAYER_KEY, this.triggerSc))
            this.SetState("")
        }
    }

    ; Any change ends the wait for J.
    static SetState(state) {
        this.state := state
        SetTimer(this.timeout, 0)
    }
}
