; The grid: each monitor's work area split into cells, and panes as rectangles of cells.
; A pane is {grid, r1, c1, r2, c2}: its first and last row and column, counted from 1.
; Cells are ordered by monitor, then row, then column.

; The grids of the connected monitors, in monitor order.
MonitorGrids() {
    list := []
    loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
        shape := r - l >= b - t ? LANDSCAPE_GRID : PORTRAIT_GRID
        list.Push({mon: A_Index, rows: shape.rows, cols: shape.cols, x: l, y: t, w: r - l, h: b - t,
            xs: CellEdges(l, r, shape.cols), ys: CellEdges(t, b, shape.rows)})
    }
    return list
}

; Where the windows of n equal cells between lo and hi start and end. Neighboring cells share the MARGIN
; between them, like collapsing CSS margins, and a window sits PADDING inside its cell. Pixels left over
; from an uneven split go to the outer margins, so every cell is the same size.
CellEdges(lo, hi, n) {
    step := (hi - lo - MARGIN) // n  ; a cell and the margin after it
    first := lo + MARGIN + (hi - lo - MARGIN - n * step) // 2
    starts := [], ends := []
    loop n {
        cell := first + (A_Index - 1) * step
        starts.Push(cell + PADDING), ends.Push(cell + step - MARGIN - PADDING)
    }
    return {starts: starts, ends: ends}
}

; The pane with the two cells as opposite corners.
Pane(g, r1, c1, r2, c2) => {grid: g, r1: Min(r1, r2), c1: Min(c1, c2), r2: Max(r1, r2), c2: Max(c1, c2)}
PaneRows(p) => p.r2 - p.r1 + 1
PaneCols(p) => p.c2 - p.c1 + 1
PaneKey(p) => p.grid.mon ":" p.r1 "," p.c1 "," p.r2 "," p.c2
CellOrder(p) => p.grid.mon * 10000 + p.r1 * 100 + p.c1

; The pane packed into an integer, its numbers as decimal digits (a grid has fewer than 10 rows and columns).
PackPane(p) => p.grid.mon * 10000 + p.r1 * 1000 + p.c1 * 100 + p.r2 * 10 + p.c2

; The packed pane, or "" when the value is no pane or its monitor or cells are gone.
UnpackPane(n, grids) {
    if n < 10000 || (mon := n // 10000) > grids.Length
        return ""
    g := grids[mon], r2 := Mod(n // 10, 10), c2 := Mod(n, 10)
    return r2 <= g.rows && c2 <= g.cols ? Pane(g, Mod(n // 1000, 10), Mod(n // 100, 10), r2, c2) : ""
}

PaneRect(p) {
    x := p.grid.xs.starts[p.c1], y := p.grid.ys.starts[p.r1]
    return {x: x, y: y, w: p.grid.xs.ends[p.c2] - x, h: p.grid.ys.ends[p.r2] - y}
}

; Whether every edge of the rectangle is within MATCH_TOLERANCE of r's.
CloseTo(f, r) => Abs(f.x - r.x) <= MATCH_TOLERANCE && Abs(f.y - r.y) <= MATCH_TOLERANCE
    && Abs(f.x + f.w - r.x - r.w) <= MATCH_TOLERANCE && Abs(f.y + f.h - r.y - r.h) <= MATCH_TOLERANCE

; The pane the rectangle fills, or "".
RectPane(f, grids) {
    for g in grids
        if (c1 := NearEdge(g.xs.starts, f.x)) && (c2 := NearEdge(g.xs.ends, f.x + f.w)) && c1 <= c2
            && (r1 := NearEdge(g.ys.starts, f.y)) && (r2 := NearEdge(g.ys.ends, f.y + f.h)) && r1 <= r2
            return Pane(g, r1, c1, r2, c2)
    return ""
}

NearEdge(edges, v) {
    for i, e in edges
        if Abs(e - v) <= MATCH_TOLERANCE
            return i
    return 0
}

; The grid of the monitor the point is on, or else the first.
GridAt(grids, x, y) {
    for g in grids {
        MonitorGet(g.mon, &l, &t, &r, &b)
        if x >= l && x < r && y >= t && y < b
            return g
    }
    return grids[1]
}

; The cell of the grid nearest the point, as a one-cell pane.
CellAt(g, x, y) {
    r := Clamp(Floor((y - g.y) * g.rows / g.h) + 1, 1, g.rows)
    c := Clamp(Floor((x - g.x) * g.cols / g.w) + 1, 1, g.cols)
    return Pane(g, r, c, r, c)
}

Clamp(v, lo, hi) => Max(lo, Min(hi, v))
InRect(r, x, y) => x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h
Overlaps(p, q) => p.grid.mon = q.grid.mon && p.r1 <= q.r2 && q.r1 <= p.r2 && p.c1 <= q.c2 && q.c1 <= p.c2
Inside(p, q) => p.grid.mon = q.grid.mon && p.r1 >= q.r1 && p.r2 <= q.r2 && p.c1 >= q.c1 && p.c2 <= q.c2
SameShape(p, q) => PaneRows(p) = PaneRows(q) && PaneCols(p) = PaneCols(q)

; Keys of the pane's cells, for a map of taken cells.
CellKeys(p) {
    keys := []
    loop PaneRows(p) {
        r := p.r1 + A_Index - 1
        loop PaneCols(p)
            keys.Push(p.grid.mon ":" r ":" (p.c1 + A_Index - 1))
    }
    return keys
}

Take(taken, p) {
    for k in CellKeys(p)
        taken[k] := true
}

IsFree(p, taken) {
    for k in CellKeys(p)
        if taken.Has(k)
            return false
    return true
}

; The first pane of the size whose cells are all free, in cell order, or "" when there is none.
FirstFree(grids, taken, rows, cols) {
    for g in grids
        loop Max(0, g.rows - rows + 1) {
            r := A_Index
            loop Max(0, g.cols - cols + 1)
                if IsFree(p := Pane(g, r, A_Index, r + rows - 1, A_Index + cols - 1), taken)
                    return p
        }
    return ""
}

; The first free pane of the size, else the first free cell, marked taken; "" when no cell is free.
TakeFree(grids, taken, rows := 1, cols := 1) {
    if (p := FirstFree(grids, taken, rows, cols)) || (p := FirstFree(grids, taken, 1, 1))
        Take(taken, p)
    return p
}
