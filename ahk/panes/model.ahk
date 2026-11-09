; The layout model (see main.ahk), in memory only: no window is read or moved here, so it can be tested
; on its own (model.test.ahk). A layout is {grids, wins: Map(hwnd -> win)}; a win is {hwnd, claims,
; minimized, maximized}, its claims in rank order: its home, then the panes it was moved aside to, oldest
; first, then, when it is parked, a claim with pane "". The last claim is where the window is. sync.ahk
; loads a layout from the windows, minimized and maximized as they are, and carries one out; Resolve sets
; minimized to how each window should be.

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

; Where the window is: the pane of its last claim, "" when parked.
Current(w) => w.claims[w.claims.Length].pane

; Whether the window takes part in the layout: every one but those the user minimized, which keep their
; claims but hold nothing until restored.
InPlay(w) => !(w.minimized && Current(w))

; ---- Actions: each changes claims, and returns what Resolve should know of it or "" ----

; The user put the window in pane p: p becomes its home and only claim. Returns the move, {from, to}.
; A window the layout does not have yet joins it, shown normally.
Put(l, hwnd, p) {
    w := l.wins.Get(hwnd, "")
    from := w && InPlay(w) ? Current(w) : ""
    if !w
        l.wins[hwnd] := w := {hwnd: hwnd, claims: [], minimized: false, maximized: false}
    w.claims := [{pane: p, time: NewClaimTime()}], w.maximized := false
    return {from: from, to: p}
}

; The user brought the window back (restored it, or showed it again): it is put where it last was, for a
; parked one the pane under its parked claim.
PutBack(l, hwnd) {
    if !(w := l.wins.Get(hwnd, ""))
        return ""
    n := w.claims.Length
    return Put(l, hwnd, w.claims[n].pane || w.claims[n - 1].pane)
}

; ---- Resolution ----

; Lays the windows in play out from their claims: takes the claims in rank order (Outranks), each one
; whose window has no place yet and whose cells are free. Any claims give exactly one layout this way, so
; no two windows can wait on each other. A window left without a place moves aside onto a new claim
; (AsidePane), ranked below every other as the newest aside, or with no free cell is parked until one of
; its claims frees. Last, the claims ranked below each window's place are dropped, and each window is shown
; or minimized to match. move, from Put, steers where windows go aside.
Resolve(l, move := "") {
    wins := [], ranked := []
    for hwnd, w in l.wins
        if InPlay(w) {
            wins.Push(w)
            for i, c in w.claims
                if c.pane
                    ranked.Push({win: w, claim: c, home: i = 1})
        }
    InsertionSort(ranked, (a, b) => Outranks(b, a))
    taken := Map(), placed := Map()  ; window -> the claim it is placed on
    for e in ranked
        if !placed.Has(e.win) && IsFree(e.claim.pane, taken)
            Take(taken, e.claim.pane), placed[e.win] := e.claim
    left := []
    for w in wins
        if !placed.Has(w) && Current(w)
            left.Push(w)
    InsertionSort(left, (a, b) => CellOrder(Current(a)) > CellOrder(Current(b)))
    for w in left
        if p := AsidePane(l, w, taken, move)
            Take(taken, p), w.claims.Push(placed[w] := {pane: p, time: NewClaimTime()})
    for w in wins
        if placed.Has(w)
            DropBelow(w, placed[w]), w.minimized := false
        else if Current(w)
            w.claims.Push({pane: "", time: NewClaimTime()}), w.minimized := true
}

; Homes before asides; homes newest first, so the latest action wins; asides oldest first, so a window
; returns to the first place it was moved aside to. Claim times differ (NewClaimTime); the window breaks a
; tie only a clock set back could make.
Outranks(a, b) => a.home != b.home ? a.home
    : a.claim.time != b.claim.time ? (a.home ? a.claim.time > b.claim.time : a.claim.time < b.claim.time)
    : a.win.hwnd < b.win.hwnd

; Where a window left without a place goes, in free cells: the largest free part of the pane it was in,
; so it shrinks in place; else, when the window moved from `from` to `to` took its cells, the pane that
; one left, shifted like the window's place within `to` when both are the same shape, so a layout swaps as
; a whole; else the nearest free pane of its size, or cell; "" when no cell is free.
AsidePane(l, w, taken, move) {
    q := Current(w)
    if p := LargestFreePart(q, taken)
        return p
    if move && move.from && !Overlaps(move.from, move.to) && Overlaps(q, move.to) {
        p := Inside(q, move.to) && SameShape(move.from, move.to) ? ShiftPane(q, move.to, move.from) : move.from
        if IsFree(p, taken)
            return p
    }
    return NearestFree(l.grids, taken, q, PaneRows(q), PaneCols(q)) || NearestFree(l.grids, taken, q, 1, 1)
}

; Drops the window's claims after c, those ranked below it.
DropBelow(w, c) {
    for i, d in w.claims
        if d = c
            return w.claims.Length := i
}

; ---- Results ----

; A copy of `base` with change(layout) made and resolved; `base` stays as it is.
Changed(base, change) {
    after := CopyLayout(base)
    Resolve(after, change(after))
    return after
}

; The moves change(layout) would make from `base`, for a preview.
Preview(base, change, first) => LayoutMoves(base, Changed(base, change), first)

; What turning `before` into `after` does to the windows in play, as moves: {hwnd, rect, maximized}, rect
; "" to minimize. A window moves when its pane, or whether it is minimized or maximized, changed; `first`
; leads.
LayoutMoves(before, after, first := 0) {
    list := []
    for hwnd, w in after.wins {
        if !InPlay(w)
            continue
        b := before.wins.Get(hwnd, ""), p := Current(w)
        if b && PaneKey(Current(b)) = PaneKey(p) && b.minimized = w.minimized && b.maximized = w.maximized
            continue
        m := {hwnd: hwnd, rect: p ? PaneRect(p) : "", maximized: w.maximized}
        hwnd = first ? list.InsertAt(1, m) : list.Push(m)
    }
    return list
}

; Sorts the list in place; after(a, b) tells whether a goes after b.
InsertionSort(list, after) {
    loop list.Length - 1 {
        i := A_Index + 1, v := list[i]
        while i > 1 && after(list[i - 1], v)
            list[i] := list[i - 1], i--
        list[i] := v
    }
}
