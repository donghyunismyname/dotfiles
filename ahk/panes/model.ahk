; The layout model (see main.ahk), in memory only: no window is read or moved here, so it can be tested
; on its own (model.test.ahk). A layout is {grids, wins: Map(hwnd -> win)}; a win is {hwnd, claims,
; minimized, maximized}, its claims its stack, bottom first, each {pane, time} with pane "" for a
; minimized claim. sync.ahk loads a layout from the windows and carries one out.

CopyLayout(l) {
    wins := Map()
    for hwnd, w in l.wins {
        claims := []
        for c in w.claims
            claims.Push({pane: c.pane, time: c.time})
        wins[hwnd] := {hwnd: hwnd, claims: claims, minimized: w.minimized, maximized: w.maximized}
    }
    return {grids: l.grids, wins: wins}
}

Top(w) => w.claims[w.claims.Length]

; Whether the window takes part in resolution: every one but those the user minimized, which keep their
; claims but hold nothing until restored.
InPlay(w) => !(w.minimized && Top(w).pane)

; ---- Actions ----

; The user put the window in pane p: that is now all it claims, and windows in the way are pushed aside.
; A window the layout does not have yet joins it, shown normally.
Put(l, hwnd, p) {
    w := l.wins.Get(hwnd, "")
    from := w && InPlay(w) ? Top(w).pane : ""
    if !w
        l.wins[hwnd] := w := {hwnd: hwnd, claims: [], minimized: false, maximized: false}
    w.claims := [{pane: p, time: NewClaimTime()}], w.maximized := false
    PushAside(l, w, from)
}

; A new window takes the first free cell, or else the pane of the window whose top claim is oldest.
Open(l, hwnd) {
    if p := FirstFree(l.grids, TakenCells(l), 1, 1) || OldestPane(l)
        Put(l, hwnd, p)
}

; The user brought the window back (restored it, or showed it again): it claims its top pane anew, or the
; one under a minimized claim.
Reclaim(l, hwnd) {
    if !(w := l.wins.Get(hwnd, ""))
        return
    if !Top(w).pane && w.claims.Length > 1
        w.claims.Pop()
    Top(w).time := NewClaimTime()
    PushAside(l, w, "")
}

OldestPane(l) {
    oldest := ""
    for hwnd, w in l.wins
        if InPlay(w) && Top(w).pane && (!oldest || Top(w).time < Top(oldest).time)
            oldest := w
    return oldest ? Top(oldest).pane : ""
}

; ---- Resolution: push, then pop ----

; Pushes the windows in the way of w's top claim aside, each onto a new claim (see Claim), so no two
; windows hold the same cell:
; - when w came from a pane of the same shape apart from its new one, and they all lie inside the new
;   one, they move there keeping their places, so a layout swaps as a whole
; - when there is one and w came from a pane apart from its new one, it takes that pane
; - otherwise each, in cell order, goes to the free pane of its size nearest to it, else the nearest free
;   cell, else is minimized.
PushAside(l, w, from) {
    if !InPlay(w) || !(p := Top(w).pane)
        return
    inWay := []
    for hwnd, v in l.wins
        if v != w && InPlay(v) && Top(v).pane && Overlaps(Top(v).pane, p)
            inWay.Push(v)
    if !inWay.Length
        return
    SortByCell(inWay)
    apart := from && !Overlaps(from, p)
    if apart && SameShape(from, p) && AllInside(inWay, p) {
        for v in inWay {
            q := Top(v).pane
            Claim(v, Pane(from.grid, from.r1 + q.r1 - p.r1, from.c1 + q.c1 - p.c1, from.r1 + q.r2 - p.r1, from.c1 + q.c2 - p.c1))
        }
    } else if apart && inWay.Length = 1 {
        Claim(inWay[1], from)
    } else {
        taken := TakenCells(l, inWay)
        for v in inWay {
            q := Top(v).pane
            if aside := NearestFree(l.grids, taken, q, PaneRows(q), PaneCols(q)) || NearestFree(l.grids, taken, q, 1, 1)
                Take(taken, aside)
            Claim(v, aside)
        }
    }
}

; Pushes a claim on p, or a minimized claim for "", onto the window's stack. A pane already in the stack
; is claimed anew there instead, dropping the claims above it, so a stack never holds a pane twice.
Claim(w, p) {
    for i, c in w.claims
        if PaneKey(c.pane) = PaneKey(p) {
            w.claims.Length := i
            return c.time := NewClaimTime()
        }
    w.claims.Push({pane: p, time: NewClaimTime()})
}

; Lets windows drop back, until none can, to the deepest claim in their stack whose cells are free (or
; their own), dropping the claims above it. When several want the same cells in a round, the most recent
; claim gets them. A window in place is never moved, and every drop shortens a stack, so this ends.
PopBack(l) {
    loop {
        held := Map()  ; cell -> the window whose top claim holds it
        for hwnd, w in l.wins
            if InPlay(w) && Top(w).pane
                Take(held, Top(w).pane, w)
        drops := []
        for hwnd, w in l.wins
            if InPlay(w) && (depth := DeepestFree(w, held))
                drops.Push({win: w, claim: w.claims[depth], depth: depth})
        if !drops.Length
            return
        SortByTimeDesc(drops)
        granted := Map()
        for d in drops
            if IsFree(d.claim.pane, granted) {
                Take(granted, d.claim.pane)
                d.win.claims.Length := d.depth
            }
    }
}

; The deepest claim below the window's top whose cells are free or its own, or 0.
DeepestFree(w, held) {
    loop w.claims.Length - 1
        if (c := w.claims[A_Index]).pane && IsFree(c.pane, held, w)
            return A_Index
    return 0
}

; ---- Results ----

; The moves change(layout) would make from `base`, for a preview.
Preview(base, change, first) {
    after := CopyLayout(base)
    change(after)
    PopBack(after)
    return LayoutMoves(base, after, first)
}

; What turning `before` into `after` does to the windows, as moves: {hwnd, rect, maximized}, rect "" to
; minimize. A window moves when its top pane changed, when it comes back from minimized, or when it is
; put out of maximized; `first` leads.
LayoutMoves(before, after, first := 0) {
    list := []
    for hwnd, w in after.wins {
        if !InPlay(w)
            continue
        b := before.wins.Get(hwnd, ""), p := Top(w).pane
        if b && InPlay(b) && PaneKey(Top(b).pane) = PaneKey(p) && !(b.minimized && p) && b.maximized = w.maximized
            continue
        m := {hwnd: hwnd, rect: p ? PaneRect(p) : "", maximized: w.maximized}
        hwnd = first ? list.InsertAt(1, m) : list.Push(m)
    }
    return list
}

; ---- Helpers ----

; Cells held by the top claims of the windows in play, but the given ones.
TakenCells(l, except := []) {
    taken := Map()
    for hwnd, w in l.wins
        if InPlay(w) && Top(w).pane && !HasItem(except, w)
            Take(taken, Top(w).pane)
    return taken
}

AllInside(wins, p) {
    for w in wins
        if !Inside(Top(w).pane, p)
            return false
    return true
}

HasItem(list, v) {
    for e in list
        if e = v
            return true
    return false
}

SortByCell(wins) => InsertionSort(wins, (a, b) => CellOrder(Top(a).pane) > CellOrder(Top(b).pane))
SortByTimeDesc(drops) => InsertionSort(drops, (a, b) => a.claim.time < b.claim.time)

; Sorts the list in place; after(a, b) tells whether a goes after b.
InsertionSort(list, after) {
    loop list.Length - 1 {
        i := A_Index + 1, v := list[i]
        while i > 1 && after(list[i - 1], v)
            list[i] := list[i - 1], i--
        list[i] := v
    }
}
