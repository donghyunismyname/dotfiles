#Requires AutoHotkey v2.0
#Warn All, StdOut
; Tests of the key remapping (remap.ahk) on made-up key events; SendKeys records instead of sending, so
; no key reaches any app. Mode combos (X+C, ,+.) are left out: they read the real focused window's mode.
; Modifier checks read the real keyboard, so keep hands off Shift / Ctrl / Alt / Win while it runs.
; Run: AutoHotkey64.exe /ErrorStdOut=UTF-8 main.test.ahk  (prints a line per check; exit code = failures)
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\ime.ahk
#Include %A_LineFile%\..\keys.ahk
#Include %A_LineFile%\..\config.ahk
#Include %A_LineFile%\..\remap.ahk

SENT := ""
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
Check("L held past SELECT_LAYER_MS", Keys("L", 150, "^L"), "l (^l)")
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
ExitApp(FAILURES)

SelLeft() => "lshift left ^left ^lshift"
SelRight() => "lshift right ^right ^lshift"

Keys(steps*) {
    global SENT
    SENT := ""
    for step in steps {
        if IsNumber(step) {
            Critical("Off"), Sleep(step)  ; the handlers' Critical lasts for the thread, which would hold off timers
            continue
        }
        release := SubStr(step, 1, 1) = "^", name := LTrim(step, "^")
        if !OnKey({vk: GetKeyVK(name), sc: GetKeySC(name), ext: false, down: !release})
            SENT .= "(" KeyText(GetKeyVK(name), release) ") "
    }
    Critical("Off"), Sleep(SELECT_LAYER_MS + 50)  ; let the timers run out
    return Trim(SENT)
}

; Stands in for send.ahk.
SendKeys(keys*) {
    global SENT
    for k in keys
        SENT .= KeyText(k[1], k[3]) " "
}

KeyText(vk, up) => (up ? "^" : "") StrLower(GetKeyName(Format("vk{:x}", vk)) || Format("vk{:x}", vk))

Check(name, got, want) {
    global FAILURES
    ok := got == want
    FAILURES += !ok
    FileAppend((ok ? "ok    " : "FAIL  ") name (ok ? "" : ": got " got ", want " want) "`n", "*", "UTF-8")
}
