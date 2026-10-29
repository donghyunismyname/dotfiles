; Rocker: with Right held, pressing Left shows every cell; dragging selects the pane between the cell
; where Left went down and the one under the cursor, on that monitor. Releasing Left fits the window
; that was under the cursor when Right went down to it; Esc cancels.
selection := {active: false}  ; while selecting; the Left release ends it (see StartMouse)

SelectAndPlace() {
    hwnd := right.hwnd
    if !IsAppWindow(hwnd)
        return
    selection.active := true
    grids := MonitorGrids()
    MouseGetPos(&x, &y)
    g := GridAt(grids, x, y), p := anchor := CellAt(g, x, y)
    cells := []
    for each in grids
        loop each.rows {
            r := A_Index
            loop each.cols
                cells.Push(ShowRect(ClickThroughGui(CELL_COLOR, CELL_ALPHA), PaneRect(Pane(each, r, A_Index, r, A_Index))))
        }
    preview := ClickThroughGui(SELECT_COLOR, SELECT_ALPHA)
    ih := InputHook("", "{Esc}")  ; swallows keys while selecting; Esc ends it
    ih.Start()
    shown := ""
    while selection.active && ih.InProgress {
        MouseGetPos(&x, &y)
        cell := CellAt(g, x, y), p := Pane(g, anchor.r1, anchor.c1, cell.r1, cell.c1)
        if (key := CellOrder(p) "," p.r2 "," p.c2) != shown
            ShowRect(preview, PaneRect(p)), shown := key
        Sleep(15)
    }
    cancelled := !ih.InProgress
    selection.active := false
    ih.Stop()
    preview.Destroy()
    for each in cells
        each.Destroy()
    if !cancelled
        PlaceInPane(hwnd, p)
}

ShowRect(g, r) {
    g.Show("NA x" r.x " y" r.y " w" r.w " h" r.h)
    return g
}
