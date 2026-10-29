#Requires AutoHotkey v2.0
#Warn All, StdOut
; Tests of the layout model (model.ahk) on made-up windows and monitors; no real window is touched.
; Run: AutoHotkey64.exe /ErrorStdOut=UTF-8 model.test.ahk  (prints a line per check; exit code = failures)
#Include %A_LineFile%\..\grid.ahk
#Include %A_LineFile%\..\claims.ahk
#Include %A_LineFile%\..\model.ahk

GRID_LANDSCAPE := {rows: 2, cols: 4}, GRID_PORTRAIT := {rows: 4, cols: 2}, GRID_GAP := 6, MATCH_TOLERANCE := 16
GRIDS := [Grid(1, 0, 0, 2560, 1392, GRID_LANDSCAPE), Grid(2, 2560, -489, 3640, 1383, GRID_PORTRAIT)]  ; a landscape and a portrait monitor
FAILURES := 0
OnError((e, *) => (FileAppend("ERROR " e.Message " at " e.File ":" e.Line "`n", "*", "UTF-8"), ExitApp(99)))

SwapOnPut()
SwapBackRemovesCycle()
ReturnAfterTemporaryWindow()
RestoreReclaimsLastPlace()
MinimizedWindowLendsItsPlace()
FullGridMinimizesAndBringsBack()
MovesLeadWithThePutWindow()
ExitApp(FAILURES)

; ---- Cases ----

; Putting a window on an occupied cell sends the occupant to the mover's old cell.
SwapOnPut() {
    l := Layout([1, Cell(1, 1)], [2, Cell(1, 2)])
    Run(l, (l) => Put(l, 1, Cell(1, 2)))
    Check("swap: the put window", Where(l, 1), Key(Cell(1, 2), 1))
    Check("swap: the other window", Where(l, 2), Key(Cell(1, 1), 2))
}

; Swapping back pushes B onto a pane already in its stack: the stack is cut back to it, not grown, and
; that claim is made anew.
SwapBackRemovesCycle() {
    l := Layout([1, Cell(1, 1)], [2, Cell(1, 2)])
    Run(l, (l) => Put(l, 1, Cell(1, 2)))
    first := l.wins[2].claims[1].time
    Run(l, (l) => Put(l, 1, Cell(1, 1)))
    Check("swap back: the put window", Where(l, 1), Key(Cell(1, 1), 1))
    Check("swap back: the other window", Where(l, 2), Key(Cell(1, 2), 1))
    Check("swap back: claimed anew", l.wins[2].claims[1].time > first, true)
}

; A temporary window pushes W aside; once it closes, W goes back where it was before.
ReturnAfterTemporaryWindow() {
    l := Layout([10, Cell(1, 1)], [11, Cell(1, 1), Cell(1, 2)], [21, Cell(1, 3)], [22, Cell(1, 4)], [23, Cell(2, 1)], [24, Cell(2, 2)])
    l.wins[11].claims[1].time := 1  ; W wanted 1,1 before X took it
    Run(l, (l) => Put(l, 99, Cell(1, 2)))
    Check("temporary window: W pushed aside", l.wins[11].claims.Length, 3)
    l.wins.Delete(99), PopBack(l)
    Check("temporary window closed: W back", Where(l, 11), Key(Cell(1, 2), 2))
}

; Claims carry their own times: restoring M brings it back to its last place, not to the older place
; X has claimed since.
RestoreReclaimsLastPlace() {
    l := Layout([30, Cell(1, 1), Cell(1, 2)], [31, Cell(1, 1)])
    l.wins[30].claims[1].time := 1
    l.wins[30].minimized := true, PopBack(l)
    l.wins[30].minimized := false
    Run(l, (l) => Reclaim(l, 30))
    Check("restore: M", Where(l, 30), Key(Cell(1, 2), 2))
    Check("restore: X stays", Where(l, 31), Key(Cell(1, 1), 1))
}

; While M is minimized the window it pushed out comes back; restoring M pushes that one out again.
MinimizedWindowLendsItsPlace() {
    l := Layout([40, Cell(1, 1), Cell(2, 1)], [41, Cell(1, 1)])
    l.wins[40].claims[1].time := 1
    l.wins[41].minimized := true, PopBack(l)
    Check("M minimized: Y back", Where(l, 40), Key(Cell(1, 1), 1))
    l.wins[41].minimized := false
    Run(l, (l) => Reclaim(l, 41))
    Check("M restored", Where(l, 41), Key(Cell(1, 1), 1))
    Check("M restored: Y aside", PaneKey(Top(l.wins[40]).pane) != PaneKey(Cell(1, 1)), true)
}

; With every cell taken, a window pushed out is minimized, and comes back only when its own cell frees.
FullGridMinimizesAndBringsBack() {
    l := {grids: GRIDS, wins: Map()}
    for g in GRIDS
        loop g.rows * g.cols
            Add(l, 100 * g.mon + A_Index, Pane(g, (A_Index - 1) // g.cols + 1, Mod(A_Index - 1, g.cols) + 1, (A_Index - 1) // g.cols + 1, Mod(A_Index - 1, g.cols) + 1))
    Run(l, (l) => Put(l, 999, Cell(1, 1)))
    Check("full grid: occupant minimized", Where(l, 101), "minimized/2")
    l.wins.Delete(104), PopBack(l)
    Check("full grid: another cell frees", Where(l, 101), "minimized/2")
    l.wins.Delete(999), PopBack(l)
    Check("full grid: its cell frees", Where(l, 101), Key(Cell(1, 1), 1))
}

; The moves list the put window first, then the windows it moves.
MovesLeadWithThePutWindow() {
    before := Layout([1, Cell(1, 1)], [2, Cell(1, 2)])
    list := Preview(before, (l) => Put(l, 1, Cell(1, 2)), 1)
    Check("moves", list.Length " first " list[1].hwnd, "2 first 1")
}

; ---- Helpers ----

Cell(r, c) => Pane(GRIDS[1], r, c, r, c)

; A layout with the windows given as [hwnd, pane, pane, ...], their claims oldest first.
Layout(wins*) {
    l := {grids: GRIDS, wins: Map()}
    for w in wins
        Add(l, w*)
    return l
}

Add(l, hwnd, panes*) {
    claims := []
    for p in panes
        claims.Push({pane: p, time: NewClaimTime()})
    l.wins[hwnd] := {hwnd: hwnd, claims: claims, minimized: false, maximized: false}
}

Run(l, change) => (change(l), PopBack(l))

; Where the window is: its top pane and how many claims it holds.
Where(l, hwnd) => (w := l.wins[hwnd], (Top(w).pane ? PaneKey(Top(w).pane) : "minimized") "/" w.claims.Length)
Key(p, depth) => PaneKey(p) "/" depth

Check(name, got, want) {
    global FAILURES
    ok := got = want
    FAILURES += !ok
    FileAppend((ok ? "ok    " : "FAIL  ") name (ok ? "" : ": got " got ", want " want) "`n", "*", "UTF-8")
}
