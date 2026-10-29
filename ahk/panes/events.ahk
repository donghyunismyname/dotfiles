; What the user does to windows outside the script's own controls, turned into layout updates
; (layout.ahk): restoring, minimizing, closing, opening, and moving windows by other means. The script's
; own changes raise the same events; MarkOwn tells those apart for OWN_CHANGE_MS.

own := Map()  ; window -> A_TickCount when the script last changed it

MarkOwn(hwnd) => own[hwnd] := A_TickCount
IsOwn(hwnd) => A_TickCount - own.Get(hwnd, -OWN_CHANGE_MS) < OWN_CHANGE_MS

StartEvents() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZEEND], (event, hwnd, idObject) => IsOwn(hwnd) || Soon(() => Update((l) => Reclaim(l, hwnd))))
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART], (event, hwnd, idObject) => IsOwn(hwnd) || SettleSoon())
    HookWinEvents([EVENT_OBJECT_DESTROY], (event, hwnd, idObject) => idObject = OBJID_WINDOW && (own.Has(hwnd) && own.Delete(hwnd), SettleSoon()))
    HookWinEvents([EVENT_OBJECT_HIDE], (event, hwnd, idObject) => idObject = OBJID_WINDOW && IsManaged(hwnd) && SettleSoon())
    HookWinEvents([EVENT_OBJECT_SHOW], (event, hwnd, idObject) => idObject = OBJID_WINDOW && IsTopLevel(hwnd)
        && SetTimer(Shown.Bind(hwnd), -NEW_WINDOW_DELAY_MS))
    HookWinEvents([EVENT_SYSTEM_MOVESIZEEND], (event, hwnd, idObject) => IsManaged(hwnd) && !IsOwn(hwnd) && Soon(LeaveGrid.Bind(hwnd)))
    HookWinEvents([EVENT_OBJECT_LOCATIONCHANGE], (event, hwnd, idObject) => idObject = OBJID_WINDOW && IsManaged(hwnd)
        && !IsOwn(hwnd) && SetTimer(CheckDrift, -DRIFT_CHECK_DELAY_MS))
    Update(Adopt)
}

Soon(fn) => SetTimer(fn, -1)
IsTopLevel(hwnd) => DllCall("GetAncestor", "ptr", hwnd, "uint", 1, "ptr") = DllCall("GetDesktopWindow", "ptr")  ; GA_PARENT

; Resolves without an action, e.g. after windows closed: those left drop back where they can.
Settle() => Update((l) => 0)

; Settles once a burst of closing or hiding windows is over.
SettleSoon() => SetTimer(Settle, -SETTLE_DELAY_MS)

; Windows the script has not seen yet (from before it ran) join the grid where they fill a pane, or would
; when shown normally, the topmost last so it wins; the others float. Unlike Put, a maximized or
; minimized window stays so.
Adopt(l) {
    stack := Windows()
    loop stack.Length {
        hwnd := stack[stack.Length - A_Index + 1]
        try {
            if GetProp(hwnd, "panes.claims")
                continue
            if !(p := FilledPane(hwnd, l.grids)) {
                SetFloating(hwnd)
                continue
            }
            l.wins[hwnd] := w := Win(hwnd, [{pane: p, time: NewClaimTime()}])
            PushAside(l, w, "")
        }
    }
}

; The pane the window fills, or for a minimized or maximized one would fill when shown normally; "" when
; off the grid.
FilledPane(hwnd, grids) => RectPane(WinGetMinMax(hwnd) = 0 ? FrameRect(hwnd) : NormalFrame(hwnd), grids)

; A window shown for the first time joins the grid when it can be resized, else floats; one shown again
; (e.g. back from the tray) claims its pane anew.
Shown(hwnd) {
    try {
        if IsOwn(hwnd) || !IsAppWindow(hwnd)
            return
        if IsManaged(hwnd)
            return Update((l) => Reclaim(l, hwnd))
        if GetProp(hwnd, "panes.claims")  ; floating
            return
        if WinGetMinMax(hwnd) != -1 && WinGetStyle(hwnd) & 0x40000  ; WS_THICKFRAME: resizable
            Update((l) => Open(l, hwnd))
        else
            SetFloating(hwnd)
    }
}

; Moved or resized by hand: the window leaves the grid, and what it held is free for the others.
LeaveGrid(hwnd) {
    SetFloating(hwnd)
    Settle()
}

; A window on the grid moved by other means (Win+arrow keys, its own app) floats once it is off its pane;
; one only a few pixels off, e.g. restored with a guessed border width, is fitted back. A window larger
; than its pane from the right top-left corner is one its app keeps from shrinking, and is left so.
CheckDrift() {
    Critical
    for hwnd, w in LoadLayout().wins
        try {
            if w.minimized || w.maximized || IsOwn(hwnd) || !(p := Top(w).pane)
                continue
            f := FrameRect(hwnd), r := PaneRect(p)
            if f.x = r.x && f.y = r.y && f.w = r.w && f.h = r.h || KeptLarger(f, r)
                continue
            if CloseTo(f, r)
                MarkOwn(hwnd), MoveTo(hwnd, r, false)
            else
                LeaveGrid(hwnd)
        }
}

KeptLarger(f, r) => Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE && f.w >= r.w && f.h >= r.h
