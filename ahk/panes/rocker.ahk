; Rocker: with Right held, pressing Left shows every cell; dragging selects the pane between the cell
; where Left went down and the one under the cursor, on that monitor, and previews putting the window
; there. Releasing Left puts the window that was under the cursor when Right went down; releasing Right
; first, or Esc, cancels. Driven by a timer and hotkeys, so no thread waits while selecting.

rocker := {active: false}  ; the selection in progress: {active, hwnd, grid, anchor, base, cells, pane}

; The hotkeys have to exist before Left goes down, or the hook does not hand its release over.
StartRocker() {
    HotIf((*) => rocker.active)
    Hotkey("*LButton Up", (*) => EndSelection(right.held))
    Hotkey("*Esc", (*) => EndSelection(false))
    HotIf()
}

StartSelection() {
    if !IsAppWindow(hwnd := right.hwnd)
        return
    base := LoadLayout()
    MouseGetPos(&x, &y)
    g := GridAt(base.grids, x, y)
    global rocker := {active: true, hwnd: hwnd, grid: g, anchor: CellAt(g, x, y), base: base, cells: ShowCells(base.grids), pane: ""}
    FollowCursor()
    SetTimer(FollowCursor, POLL_MS)
}

; Selects the pane from the anchor to the cell under the cursor and previews putting the window there;
; Right released first cancels.
FollowCursor() {
    if !right.held
        return EndSelection(false)
    MouseGetPos(&x, &y)
    cell := CellAt(rocker.grid, x, y), p := Pane(rocker.grid, rocker.anchor.r1, rocker.anchor.c1, cell.r1, cell.c1)
    if PaneKey(p) = PaneKey(rocker.pane)
        return
    rocker.pane := p, hwnd := rocker.hwnd
    ShowMoves(Preview(rocker.base, (l) => Put(l, hwnd, p), hwnd))
}

EndSelection(confirmed) {
    if !rocker.active
        return
    SetTimer(FollowCursor, 0)
    ShowMoves()
    for g in rocker.cells
        g.Destroy()
    s := rocker, rocker.active := false
    if confirmed && s.pane
        Update((l) => Put(l, s.hwnd, s.pane), s.hwnd)
}

; Every cell as a translucent rectangle.
ShowCells(grids) {
    cells := []
    for g in grids
        loop g.rows {
            r := A_Index
            loop g.cols
                cells.Push(ShowRect(ClickThroughGui(ROCKER_CELL_COLOR, ROCKER_CELL_ALPHA), PaneRect(Pane(g, r, A_Index, r, A_Index))))
        }
    return cells
}
