; Between the model (model.ahk) and the windows: loading a layout from the windows' claims and states,
; and carrying a changed one out by storing the claims and moving the windows.

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
Win(hwnd, claims) => {hwnd: hwnd, claims: claims, minimized: WinGetMinMax(hwnd) = -1, maximized: WinGetMinMax(hwnd) = 1}

; Runs change(layout) on the current layout, resolves, and commits; focus, when given, is activated.
Update(change, focus := 0) {
    Critical
    before := LoadLayout(), after := CopyLayout(before)
    change(after)
    PopBack(after)
    Commit(before, after, focus)
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
; and only its restore position moves. Each is marked as the script's own change (events.ahk).
ApplyMoves(list) {
    loop list.Length {
        m := list[list.Length - A_Index + 1]
        MarkOwn(m.hwnd)
        try {
            if !m.rect
                WinMinimize(m.hwnd)
            else if m.maximized
                SetNormalRect(m.hwnd, m.rect, 3)  ; SW_SHOWMAXIMIZED
            else
                MoveTo(m.hwnd, m.rect, false)
        }
    }
}
