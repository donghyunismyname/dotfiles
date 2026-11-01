; Last word: the letters typed since the last other key, and the spaces right after them, so that Convert
; can retype them in the other input mode: dkssud becomes 안녕, ㅗ디ㅣㅐ becomes hello, and a second Convert
; turns it back. Any other key starts over, Backspace too (what it removes cannot be told from the keys),
; and so do a mouse click and another focused control, so Convert never erases text somewhere else.
; It sees the keys that reach the app: passed physical ones and injected ones, its own retyping included.
class LastWord {
    static letters := []  ; {vk, sc, shift}
    static spaces := 0    ; typed after the letters
    static focus := 0     ; the control they went to

    static See(key) {
        vk := key.vk
        if !key.down || vk = VK_LSHIFT || vk = VK_RSHIFT
            return
        if vk = VK_SPACE {
            if this.letters.Length
                this.spaces += 1
            return
        }
        if vk < Ord("A") || vk > Ord("Z") || CtrlAltWinDown() {
            this.Reset()
            return
        }
        focus := FocusedControl()
        if this.spaces || focus != this.focus  ; a new word
            this.Reset(), this.focus := focus
        this.letters.Push({vk: vk, sc: key.sc, shift: GetKeyState("Shift")})
    }

    static Reset() {
        this.letters := [], this.spaces := 0
    }

    ; 한/영 first: it finishes the syllable being composed, so each Backspace then erases one character.
    static Convert() {
        Critical
        if !this.letters.Length || FocusedControl() != this.focus
            return
        typed := (IsHangul(this.focus) ? HangulLength(this.letters) : this.letters.Length) + this.spaces
        sequence := []
        loop HangulKeyPresses(this.focus)
            sequence.Push(Down(VK_HANGUL), Up(VK_HANGUL))
        loop typed
            sequence.Push(Down(VK_BACK), Up(VK_BACK))
        for k in this.letters {
            if k.shift
                sequence.Push(Down(VK_LSHIFT))
            sequence.Push(Down(k.vk, k.sc), Up(k.vk, k.sc))
            if k.shift
                sequence.Push(Up(VK_LSHIFT))
        }
        loop this.spaces
            sequence.Push(Down(VK_SPACE), Up(VK_SPACE))
        SendKeys(sequence*)
    }
}

CtrlAltWinDown() => GetKeyState("Ctrl") || GetKeyState("Alt") || WinKeyDown()

; How many characters letter keys come out as in 2-set Hangul input, as the IME composes them: an initial
; consonant, a vowel (ㅗ+ㅏ makes ㅘ) and a final (ㄹ+ㄱ makes ㄺ) share one character, a final moves on to
; the next syllable when a vowel follows, and a lone ㄱ+ㅅ makes one ㄳ.
HangulLength(letters) {
    static jamo := Map("Q", "ㅂ", "W", "ㅈ", "E", "ㄷ", "R", "ㄱ", "T", "ㅅ", "Y", "ㅛ", "U", "ㅕ", "I", "ㅑ",
        "O", "ㅐ", "P", "ㅔ", "A", "ㅁ", "S", "ㄴ", "D", "ㅇ", "F", "ㄹ", "G", "ㅎ", "H", "ㅗ", "J", "ㅓ",
        "K", "ㅏ", "L", "ㅣ", "Z", "ㅋ", "X", "ㅌ", "C", "ㅊ", "V", "ㅍ", "B", "ㅠ", "N", "ㅜ", "M", "ㅡ")
    static shifted := Map("Q", "ㅃ", "W", "ㅉ", "E", "ㄸ", "R", "ㄲ", "T", "ㅆ", "O", "ㅒ", "P", "ㅖ")
    static vowelPairs := "ㅗㅏ ㅗㅐ ㅗㅣ ㅜㅓ ㅜㅔ ㅜㅣ ㅡㅣ"
    static consonantPairs := "ㄱㅅ ㄴㅈ ㄴㅎ ㄹㄱ ㄹㅁ ㄹㅂ ㄹㅅ ㄹㅌ ㄹㅍ ㄹㅎ ㅂㅅ"
    Pairs(pairs, a, b) => InStr(" " pairs " ", " " a b " ")
    ; state: "" none, "C" lone consonant, "CC" lone pair, "V" lone vowel, "CV" syllable, "CVF" with a
    ; final, "CVFF" with a final pair. last: the vowel or consonant the next one may pair with.
    count := 0, state := "", last := ""
    for k in letters {
        name := Chr(k.vk), j := k.shift && shifted.Has(name) ? shifted[name] : jamo[name]
        if InStr("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅛㅜㅠㅡㅣ", j) {
            switch state {
                case "C": state := "CV"
                case "CC", "CVF", "CVFF": count += 1, state := "CV"  ; the last consonant starts a syllable
                case "V", "CV":
                    if Pairs(vowelPairs, last, j)
                        j := "+"  ; a pair takes no further vowel
                    else
                        count += 1, state := "V"
                default: count += 1, state := "V"
            }
        } else {
            switch state {
                case "C":
                    if Pairs(consonantPairs, last, j)
                        state := "CC"
                    else
                        count += 1
                case "CV":
                    if InStr("ㄸㅃㅉ", j)  ; not a final
                        count += 1, state := "C"
                    else
                        state := "CVF"
                case "CVF":
                    if Pairs(consonantPairs, last, j)
                        state := "CVFF"
                    else
                        count += 1, state := "C"
                default: count += 1, state := "C"
            }
        }
        last := j
    }
    return count
}
