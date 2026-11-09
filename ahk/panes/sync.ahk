; Between the model (model.ahk) and the windows: loading a layout from the windows' claims and states,
; and carrying a changed one out by storing the claims and moving the windows.
;
; The claims are stored on the window itself as window properties, so they go away with the window and
; outlive a restart of the script. panes.claims holds how many there are, and panes.claim1,
; panes.claim2, ... each one, in rank order, as its time and its pane (PackPane, or 0 for the claim of a
; parked window). panes.claims is FLOATING for a window that left the grid; a window without it has not
; been seen by the script yet.

LoadLayout() {
    grids := MonitorGrids(), wins := Map()
    for hwnd in Windows()
        try {
            if IsObject(claims := ReadClaims(hwnd, grids))
                wins[hwnd] := Win(hwnd, claims)
        }
    return {grids: grids, wins: wins}
}

; The window with the claims, as the model sees it, its state read from the window.
Win(hwnd, claims) => (state := WinGetMinMax(hwnd), {hwnd: hwnd, claims: claims, minimized: state = -1, maximized: state = 1})

; Runs change(layout) on the current layout, resolves, and commits; focus, when given, is activated.
Update(change, focus := 0) {
    Critical
    before := LoadLayout()
    Commit(before, Changed(before, change), focus)
}

; Stores the claims that changed, and moves the windows to match `after`.
Commit(before, after, focus := 0) {
    for hwnd, w in after.wins
        if !(b := before.wins.Get(hwnd, "")) || ClaimsKey(b) != ClaimsKey(w)
            try WriteClaims(hwnd, w.claims)
    ApplyMoves(LayoutMoves(before, after, focus))
    if focus
        try WinActivate(focus)
}

ClaimsKey(w) {
    key := ""
    for c in w.claims
        key .= PaneKey(c.pane) "@" c.time ";"
    return key
}

; Carries out the moves, the first last so it ends on top, without the focus. A maximized window stays so,
; and only its restore position moves. Windows shown normally move together in one step (MoveTogether).
; Each is marked as the script's own change (events.ahk).
ApplyMoves(list) {
    together := []
    loop list.Length {
        m := list[list.Length - A_Index + 1]
        MarkOwn(m.hwnd)
        try {
            if !m.rect
                WinMinimize(m.hwnd)
            else if m.maximized
                SetNormalRect(m.hwnd, m.rect, 3)  ; SW_SHOWMAXIMIZED
            else if WinGetMinMax(m.hwnd) != 0
                MoveTo(m.hwnd, m.rect, false)
            else
                together.Push(m)
        }
    }
    MoveTogether(together)
}

; ---- Stored claims ----

FLOATING := -1

; The window's claims in rank order, each {pane, time} with pane "" for a parked window; "floating"; or ""
; for a window not seen yet. Claims on cells that are gone (a monitor unplugged) are dropped, the next one
; then being the home, and a window left without a pane to claim floats.
ReadClaims(hwnd, grids) {
    n := GetProp(hwnd, "panes.claims")
    if !n
        return ""
    if n = FLOATING
        return "floating"
    claims := [], anyPane := false
    loop n {
        v := GetProp(hwnd, "panes.claim" A_Index), code := v & 0xFFFFF
        if code && !(p := UnpackPane(code, grids))
            continue
        claims.Push({pane: code ? p : "", time: v >> 20})
        anyPane := anyPane || code
    }
    return anyPane ? claims : "floating"
}

WriteClaims(hwnd, claims) {
    old := GetProp(hwnd, "panes.claims")
    for i, c in claims
        SetProp(hwnd, "panes.claim" i, c.time << 20 | (c.pane ? PackPane(c.pane) : 0))
    loop old - claims.Length
        SetProp(hwnd, "panes.claim" (claims.Length + A_Index), 0)
    SetProp(hwnd, "panes.claims", claims.Length)
}

SetFloating(hwnd) {
    WriteClaims(hwnd, [])
    SetProp(hwnd, "panes.claims", FLOATING)
}

IsManaged(hwnd) => GetProp(hwnd, "panes.claims") > 0

GetProp(hwnd, name) => DllCall("GetProp", "ptr", hwnd, "str", name, "ptr")

; Setting 0 removes the property.
SetProp(hwnd, name, v) => v ? DllCall("SetProp", "ptr", hwnd, "str", name, "ptr", v) : DllCall("RemoveProp", "ptr", hwnd, "str", name, "ptr")

; Whether the script has seen the window: on the grid or floating.
IsSeen(hwnd) => GetProp(hwnd, "panes.claims") != 0
