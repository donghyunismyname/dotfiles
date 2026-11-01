; Hangul tap: a physical Left Shift released within HANGUL_TAP_MS, with no other key pressed meanwhile,
; presses 한/영. The Shift of a combo is injected, so it never counts.
class HangulTap {
    static downAt := 0     ; when Left Shift went down, while it is down
    static alone := false  ; no other key pressed since then

    static Watch(key) {
        if key.vk != VK_LSHIFT {
            if key.down
                this.alone := false
        } else if key.down {
            if !this.downAt  ; not a repeat
                this.downAt := A_TickCount, this.alone := true
        } else {
            if this.alone && A_TickCount - this.downAt < HANGUL_TAP_MS
                SetTimer(PressHangulKey, -1)  ; out of the hook, after the Shift release goes out
            this.downAt := 0
        }
    }
}
