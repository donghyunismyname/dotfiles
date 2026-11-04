#Requires AutoHotkey v2.0
#Warn All, StdOut
; Tests of the key remapping (remap.ahk) on made-up key events; SendKeys records instead of sending, so
; no key reaches any app, and the input mode is a made-up one that a sent 한/영 flips.
; Modifier checks read the real keyboard, so keep hands off Shift / Ctrl / Alt / Win while it runs.
; Run: AutoHotkey64.exe /ErrorStdOut=UTF-8 main.test.ahk  (prints a line per check; exit code = failures)
#Include %A_LineFile%\..\keys.ahk
#Include %A_LineFile%\..\config.ahk
#Include %A_LineFile%\..\remap.ahk

RECORD := ""
HANGUL := false  ; the made-up input mode
FAILURES := 0
OnError((e, *) => (FileAppend("ERROR " e.Message " at " e.File ":" e.Line "`n", "*", "UTF-8"), ExitApp(99)))

; Each step is a key name pressed ("D"), released ("^D"), or a number of ms to wait. Sent keys are
; written plainly, keys let through to the app in parentheses.
Check("combo key tapped", Keys("D", "^D"), "d ^d")
Check("combo key held past COMBO_MS", Keys("D", 80, "^D"), "d (^d)")
Check("combo key then another key", Keys("D", "A", "^A", "^D"), "d a (^a) (^d)")
Check("D+F holds Left Shift", Keys("D", "F", "^F", "^D"), "lshift ^lshift")
Check("D+F with a letter", Keys("D", "F", "A", "^A", "^F", "^D"), "lshift (a) (^a) ^lshift")
Check("L tapped", Keys("L", "^L"), "l ^l")
Check("L held past SELECT_LAYER_MS", Keys("L", SELECT_LAYER_MS + 50, "^L"), "l (^l)")
Check("L then another key", Keys("L", "E", "^E", "^L"), "l (e) (^e) (^l)")
Check("L+K is typed lk", Keys("L", "K", "^K", "^L"), "l k ^k (^l)")
Check("L+J then K selects", Keys("L", "J", "^J", "K", "^K", "^L"), SelLeft() " " SelRight())
Check("J repeats while L is held", Keys("L", "J", "J", "^J", "^L"), SelLeft() " " SelLeft())
Check("J held on after L is released", Keys("L", "J", "^L", "J", "^J"), SelLeft())
Check("Ctrl after L makes it the letter", Keys("L", "LCtrl", "^LCtrl", "^L"), "l (lcontrol) (^lcontrol) (^l)")
Check("Ctrl before L and J", Keys("LCtrl", "L", "J", "^J", "^L", "^LCtrl"), "(lcontrol) " SelLeft() " (^lcontrol)")
Check("Ctrl before L alone is Ctrl+L", Keys("LCtrl", "L", "^L", "^LCtrl"), "(lcontrol) l ^l (^lcontrol)")
Check("Ctrl inside the layer", Keys("L", "J", "^J", "LCtrl", "K", "^K", "^LCtrl", "^L"),
    SelLeft() " (lcontrol) " SelRight() " (^lcontrol)")
Check("Left Shift tapped", Keys("LShift", "^LShift"), "(lshift) (^lshift) vk15 ^vk15")
Check("Left Shift with a letter", Keys("LShift", "A", "^A", "^LShift"), "(lshift) (a) (^a) (^lshift)")
Check("F13 held in Hangul", Keys("hangul", "F13", "A", "^A", "^F13"), HangulKey() " (a) (^a) " HangulKey())
Check("F13 held in English", Keys("english", "F13", "A", "^A", "^F13"), HangulKey() " (a) (^a) " HangulKey())
Check("F13 lets a held-back key go first", Keys("hangul", "D", "F13", "^F13", "^D"), "d " HangulKey() " " HangulKey() " (^d)")
Check("F13 tapped goes back", Keys("hangul", "F13", "^F13"), HangulKey() " " HangulKey())
Check("F13 keeps digits", Keys("english", "F13", "1", "^1", "^F13"), Toggled("(1) (^1)"))
Check("F13+Esc is a backtick", Keys("english", "F13", "Esc", "^Esc", "^F13"), Toggled("`` ^``"))
Check("F13+Tab is a tilde", Keys("english", "F13", "Tab", "^Tab", "^F13"), Toggled("lshift `` ^`` ^lshift"))
Check("F13 keeps letters", Keys("english", "F13", "H", "^H", "^F13"), Toggled("(h) (^h)"))
Check("F13+Space holds Shift", Keys("english", "F13", "Space", "H", "^H", "Space", "^Space", "^F13"),
    Toggled("lshift (h) (^h) ^lshift"))
Check("Space held on after F13 is released", Keys("english", "F13", "Space", "^F13", "^Space"),
    HangulKey() " lshift " HangulKey() " ^lshift")
Check("Esc held on after F13 is released", Keys("english", "F13", "Esc", "^F13", "Esc", "^Esc"), HangulKey() " `` ^`` " HangulKey())
Check("Right Shift tapped is just Shift", Keys("RShift", "^RShift"), "(rshift) (^rshift)")
ExitApp(FAILURES)

SelLeft() => "lshift left ^left ^lshift"
SelRight() => "lshift right ^right ^lshift"
HangulKey() => "vk15 ^vk15"
Toggled(inner) => HangulKey() " " inner " " HangulKey()  ; between the mode layer's two 한/영 presses

; Steps may also be "hangul" or "english", to set the made-up mode.
Keys(steps*) {
    global RECORD, HANGUL
    RECORD := ""
    for step in steps {
        if step is Integer {  ; not IsNumber: the key "1" is a string
            Critical("Off"), Sleep(step)  ; the handlers' Critical lasts for the thread, which would hold off timers
            continue
        }
        if step = "hangul" || step = "english" {
            HANGUL := step = "hangul"
            continue
        }
        Press(step)
    }
    Critical("Off"), Sleep(SELECT_LAYER_MS + 50)  ; let the timers run out
    return Trim(RECORD)
}

Press(step) {
    global RECORD
    release := SubStr(step, 1, 1) = "^", name := LTrim(step, "^")
    if !OnKey({vk: GetKeyVK(name), sc: GetKeySC(name), ext: false, down: !release, injected: false})
        RECORD .= "(" KeyText(GetKeyVK(name), release) ") "
}

; Stand in for send.ahk and lib/ime.ahk. Sent keys come back to OnKey as injected, as from the system.
SendKeys(keys*) {
    global RECORD, HANGUL
    for k in keys {
        RECORD .= KeyText(k[1], k[3]) " "
        if k[1] = VK_HANGUL && !k[3]
            HANGUL := !HANGUL
        OnKey({vk: k[1], sc: k[2], ext: k[4], down: !k[3], injected: true})
    }
}
FocusedControl() => 1
IsHangul(hwnd) => HANGUL
HangulKeyPresses(hwnd) => 1

KeyText(vk, up) => (up ? "^" : "") StrLower(GetKeyName(Format("vk{:x}", vk)) || Format("vk{:x}", vk))

Check(name, got, want) {
    global FAILURES
    ok := got == want
    FAILURES += !ok
    FileAppend((ok ? "ok    " : "FAIL  ") name (ok ? "" : ": got " got ", want " want) "`n", "*", "UTF-8")
}
