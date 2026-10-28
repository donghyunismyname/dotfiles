; Right-button controls. The script takes the right button over: a short press is passed on as a
; right-click, a longer drag runs a gesture (GESTURES), and buttons pressed while it is held run
; their WHILE_RIGHT_HELD action instead of their own.

right := {held: false, used: false, ctrl: false, x: 0, y: 0, hwnd: 0}  ; the current right press

StartMouse() {
    Hotkey("*RButton", OnRightDown)
    Hotkey("*RButton Up", OnRightUp)
    HotIf((*) => right.held)
    for key, action in WHILE_RIGHT_HELD
        Hotkey("*" key, RunWhileRightHeld.Bind(action))
    HotIf()
}

OnRightDown(*) {
    MouseGetPos(&x, &y, &hwnd)
    right.held := true, right.used := false, right.x := x, right.y := y, right.hwnd := hwnd
}

RunWhileRightHeld(action, *) {
    right.used := true  ; the release is then neither a right-click nor a gesture
    action()
}

; Ends the press: cancels the overlay, right-clicks when short, or runs a gesture on the window
; where the drag began.
OnRightUp(*) {
    right.held := false
    if right.ctrl  ; held down by WheelTab
        right.ctrl := false, Send("{Ctrl up}")
    if right.used
        return
    if cancelOverlay
        return cancelOverlay()
    MouseGetPos(&x, &y)
    dx := x - right.x, dy := y - right.y
    if Max(Abs(dx), Abs(dy)) < GESTURE_PX
        return Send("{RButton}")
    hwnd := right.hwnd
    if !IsAppWindow(hwnd) || !(action := GESTURES.Get(GestureDir(dx, dy), ""))
        return
    try {
        if action is String
            WinActivate(hwnd), WinWaitActive(hwnd, , 1) && Send(action)  ; never send to another window
        else
            action(hwnd)
    }
}

; Nearest of 8 compass directions for a drag; screen y grows downward, so north is dy < 0.
GestureDir(dx, dy) {
    static names := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
    angle := DllCall("msvcrt\atan2", "double", dy, "double", dx, "double")
    return names[Mod(Round(angle / ATan(1)) + 8, 8) + 1]  ; ATan(1): 45 degrees
}

; Keeps Ctrl down until Right is released, like holding Ctrl and pressing Tab on the keyboard,
; so apps with a recent-tabs switcher (Ctrl+Tab picks on Ctrl release) keep moving through it.
; The window under the cursor is activated first, so the wheel switches tabs where it points.
WheelTab(keys) {
    if !GetKeyState("Ctrl") {
        MouseGetPos(, , &hwnd)
        try WinActivate(hwnd)
        Send("{Ctrl down}"), right.ctrl := true
    }
    Send("{Blind}" keys)  ; Blind: keep the held Ctrl
}
