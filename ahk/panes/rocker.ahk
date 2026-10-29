; Rocker: with Right held, pressing Left shows every cell; dragging selects the pane between the cell
; where Left went down and the one under the cursor, on that monitor, and previews the result.
; Releasing Left places the window that was under the cursor when Right went down; releasing Right
; first, or Esc, cancels.
SelectAndPlace() {
    hwnd := right.hwnd
    if !IsAppWindow(hwnd)
        return
    snap := Snapshot()
    MouseGetPos(&x, &y)
    g := GridAt(snap.grids, x, y), anchor := CellAt(g, x, y)
    cells := ShowCells(snap.grids)
    released := {left: false, apply: false}
    Hotkey("*LButton Up", (*) => (released.apply := right.held, released.left := true), "On")
    ih := InputHook("", "{Esc}")  ; swallows keys while selecting; Esc ends it
    ih.Start()
    loop {
        MouseGetPos(&x, &y)
        cell := CellAt(g, x, y)
        ShowPlan(plan := PlanPane(hwnd, Pane(g, anchor.r1, anchor.c1, cell.r1, cell.c1), snap))
        Sleep(POLL_MS)
    } until released.left || !right.held || !ih.InProgress
    escaped := !ih.InProgress
    Hotkey("*LButton Up", "Off")
    ih.Stop()
    ShowPlan()
    for c in cells
        c.Destroy()
    if released.apply && !escaped
        ApplyPlan(plan)
}

; Every cell as a translucent rectangle.
ShowCells(grids) {
    cells := []
    for g in grids
        loop g.rows {
            r := A_Index
            loop g.cols
                cells.Push(ShowRect(ClickThroughGui(CELL_COLOR, CELL_ALPHA), PaneRect(Pane(g, r, A_Index, r, A_Index))))
        }
    return cells
}
