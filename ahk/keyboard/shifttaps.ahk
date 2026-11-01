; Shift taps: a physical Shift released within SHIFT_TAP_MS, with no other key pressed meanwhile, the other
; Shift included, runs its action in SHIFT_TAPS. The Shift of a combo is injected, so it never counts.
class ShiftTaps {
    static downAt := Map()  ; Shift vk -> when it went down, while it is down
    static alone := false   ; no other key pressed since the Shift press

    static Watch(key) {
        vk := key.vk
        if !SHIFT_TAPS.Has(vk) {
            if key.down
                this.alone := false
        } else if key.down {
            if !this.downAt.Has(vk)  ; not a repeat
                this.alone := !this.downAt.Count, this.downAt[vk] := A_TickCount
        } else if this.downAt.Has(vk) {
            heldMs := A_TickCount - this.downAt.Delete(vk)
            if this.alone && heldMs < SHIFT_TAP_MS
                SetTimer(SHIFT_TAPS[vk], -1)  ; out of the hook, after the Shift release goes out
            this.alone := false
        }
    }
}
