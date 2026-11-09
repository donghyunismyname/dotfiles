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
SwapBackReturnsHome()
ShrinkAroundPut()
MovesThroughOthersUndone()
ReturnAfterTemporaryWindow()
RestoreReclaimsLastPlace()
MinimizedWindowLendsItsPlace()
FullGridParksAndBringsBack()
ResolvingAgainChangesNothing()
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

; Swapping back frees the other window's home: it returns there and drops its aside claim.
SwapBackReturnsHome() {
    l := Layout([1, Cell(1, 1)], [2, Cell(1, 2)])
    Run(l, (l) => Put(l, 1, Cell(1, 2)))
    Run(l, (l) => Put(l, 1, Cell(1, 1)))
    Check("swap back: the put window", Where(l, 1), Key(Cell(1, 1), 1))
    Check("swap back: the other window", Where(l, 2), Key(Cell(1, 2), 1))
}

; Putting a window inside a larger window's pane shrinks that one to the largest part left; once the
; put window leaves, it grows back.
ShrinkAroundPut() {
    l := Layout([1, Cell(1, 4)], [2, Pane(GRIDS[1], 1, 1, 2, 3)])
    Run(l, (l) => Put(l, 1, Cell(1, 1)))
    Check("shrink: the put window", Where(l, 1), Key(Cell(1, 1), 1))
    Check("shrink: the larger window", Where(l, 2), Key(Pane(GRIDS[1], 1, 2, 2, 3), 2))
    Run(l, (l) => Put(l, 1, Cell(1, 4)))
    Check("shrink: grows back", Where(l, 2), Key(Pane(GRIDS[1], 1, 1, 2, 3), 1))
}

; M is put on A's cell, then on B's, then back on its own: A and B end at home, not swapped with each
; other as a stack of claims per window left them.
MovesThroughOthersUndone() {
    l := Layout([1, Cell(1, 1)], [2, Cell(1, 3)], [3, Cell(2, 1)])
    Run(l, (l) => Put(l, 3, Cell(1, 1)))
    Run(l, (l) => Put(l, 3, Cell(1, 3)))
    Run(l, (l) => Put(l, 3, Cell(2, 1)))
    Check("moves undone: A", Where(l, 1), Key(Cell(1, 1), 1))
    Check("moves undone: B", Where(l, 2), Key(Cell(1, 3), 1))
    Check("moves undone: M", Where(l, 3), Key(Cell(2, 1), 1))
}

; A temporary window moves W aside; once it closes, W goes back where it was before, though that was
; itself an aside.
ReturnAfterTemporaryWindow() {
    l := Layout([10, Cell(1, 1)], [11, Cell(1, 1), Cell(1, 2)], [21, Cell(1, 3)], [22, Cell(1, 4)], [23, Cell(2, 1)], [24, Cell(2, 2)])
    l.wins[11].claims[1].time := 1  ; W's home was taken by X since
    Run(l, (l) => Put(l, 99, Cell(1, 2)))
    Check("temporary window: W moved aside", l.wins[11].claims.Length, 3)
    l.wins.Delete(99), Resolve(l)
    Check("temporary window closed: W back", Where(l, 11), Key(Cell(1, 2), 2))
}

; Restoring M puts it back where it last was, not in its home that X has taken since.
RestoreReclaimsLastPlace() {
    l := Layout([30, Cell(1, 1), Cell(1, 2)], [31, Cell(1, 1)])
    l.wins[30].claims[1].time := 1
    l.wins[30].minimized := true, Resolve(l)
    l.wins[30].minimized := false
    Run(l, (l) => Reclaim(l, 30))
    Check("restore: M", Where(l, 30), Key(Cell(1, 2), 1))
    Check("restore: X stays", Where(l, 31), Key(Cell(1, 1), 1))
}

; While M is minimized the window it moved aside goes home; restoring M moves that one aside again.
MinimizedWindowLendsItsPlace() {
    l := Layout([40, Cell(1, 1), Cell(2, 1)], [41, Cell(1, 1)])
    l.wins[40].claims[1].time := 1
    l.wins[41].minimized := true, Resolve(l)
    Check("M minimized: Y home", Where(l, 40), Key(Cell(1, 1), 1))
    l.wins[41].minimized := false
    Run(l, (l) => Reclaim(l, 41))
    Check("M restored", Where(l, 41), Key(Cell(1, 1), 1))
    Check("M restored: Y aside", PaneKey(Current(l.wins[40])) != PaneKey(Cell(1, 1)), true)
}

; With every cell taken, a window moved out is parked, and comes back only when one of its claims frees.
FullGridParksAndBringsBack() {
    l := FullGrid()
    Run(l, (l) => Put(l, 999, Cell(1, 1)))
    Check("full grid: occupant parked", Where(l, 101), "parked/2")
    l.wins.Delete(104), Resolve(l)
    Check("full grid: another cell frees", Where(l, 101), "parked/2")
    l.wins[101].minimized := true  ; as loaded from the window once parked
    l.wins.Delete(999), before := CopyLayout(l), Resolve(l)
    Check("full grid: its cell frees", Where(l, 101), Key(Cell(1, 1), 1))
    Check("full grid: shown again", Moves(LayoutMoves(before, l)), "101 to " PaneKey(Cell(1, 1)))
}

; A resolved layout is stable: resolving it again moves nothing and makes no claim.
ResolvingAgainChangesNothing() {
    l := FullGrid()
    Run(l, (l) => Put(l, 999, Pane(GRIDS[1], 1, 2, 2, 3)))
    before := CopyLayout(l)
    Resolve(l)
    Check("resolve again: moves", LayoutMoves(before, l).Length, 0)
    Check("resolve again: claims", ClaimsText(l), ClaimsText(before))
}

; The moves list the put window first, then the windows it moves.
MovesLeadWithThePutWindow() {
    before := Layout([1, Cell(1, 1)], [2, Cell(1, 2)])
    list := Preview(before, (l) => Put(l, 1, Cell(1, 2)), 1)
    Check("moves", list.Length " first " list[1].hwnd, "2 first 1")
}

; ---- Helpers ----

Cell(r, c) => Pane(GRIDS[1], r, c, r, c)

; A layout with the windows given as [hwnd, home, aside, ...], their claims made in that order.
Layout(wins*) {
    l := {grids: GRIDS, wins: Map()}
    for w in wins
        Add(l, w*)
    return l
}

; Every cell of every monitor held by its own window, 100 * monitor + cell number.
FullGrid() {
    l := {grids: GRIDS, wins: Map()}
    for g in GRIDS
        loop g.rows * g.cols {
            r := (A_Index - 1) // g.cols + 1, c := Mod(A_Index - 1, g.cols) + 1
            Add(l, 100 * g.mon + A_Index, Pane(g, r, c, r, c))
        }
    return l
}

Add(l, hwnd, panes*) {
    claims := []
    for p in panes
        claims.Push({pane: p, time: NewClaimTime()})
    l.wins[hwnd] := {hwnd: hwnd, claims: claims, minimized: false, maximized: false}
}

Run(l, change) => Resolve(l, change(l))

; Where the window is and how many claims it holds.
Where(l, hwnd) => (w := l.wins[hwnd], (Current(w) ? PaneKey(Current(w)) : "parked") "/" w.claims.Length)
Key(p, count) => PaneKey(p) "/" count

Moves(list) {
    s := ""
    for m in list
        s .= m.hwnd " to " (m.rect ? PaneKey(RectPane(m.rect, GRIDS)) : "minimized")
    return s
}

ClaimsText(l) {
    s := ""
    for hwnd, w in l.wins
        for c in w.claims
            s .= hwnd ":" PaneKey(c.pane) "@" c.time ";"
    return s
}

Check(name, got, want) {
    global FAILURES
    ok := got = want
    FAILURES += !ok
    FileAppend((ok ? "ok    " : "FAIL  ") name (ok ? "" : ": got " got ", want " want) "`n", "*", "UTF-8")
}
