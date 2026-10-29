; Right-button controls. The script takes the right button over: a short press is passed on as a
; right-click, a drag that ends outside the window it began on drops that window there (PlanDrop),
; previewed while dragging, and any other drag runs a gesture (GESTURES). Buttons pressed while it is
; held run their WHILE_RIGHT_HELD action instead of their own.

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
    SetTimer(PreviewDrop, POLL_MS)
}

RunWhileRightHeld(action, *) {
    right.used := true  ; the release is then neither a right-click, a drop nor a gesture
    SetTimer(PreviewDrop, 0), ShowPlan()
    action()
}

PreviewDrop() {
    MouseGetPos(&x, &y)
    try ShowPlan(ReleaseKind(x, y) = "drop" ? PlanDrop(right.hwnd, x, y) : [])
}

OnRightUp(*) {
    right.held := false
    if right.ctrl  ; held down by WheelTab
        right.ctrl := false, Send("{Ctrl up}")
    if right.used
        return
    SetTimer(PreviewDrop, 0), ShowPlan()
    MouseGetPos(&x, &y)
    switch ReleaseKind(x, y) {
        case "click": Send("{RButton}")
        case "drop": ApplyPlan(PlanDrop(right.hwnd, x, y), true)
        default: RunGesture(right.hwnd, x - right.x, y - right.y)
    }
}

; What releasing Right at the point does: a "click" when it barely moved, a "drop" outside the app
; window it went down on, else a "gesture".
ReleaseKind(x, y) {
    if Max(Abs(x - right.x), Abs(y - right.y)) < GESTURE_PX
        return "click"
    try {
        if IsAppWindow(right.hwnd) && !InRect(FrameRect(right.hwnd), x, y)
            return "drop"
    }
    return "gesture"
}

RunGesture(hwnd, dx, dy) {
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
