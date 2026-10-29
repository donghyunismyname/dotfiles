; Previews what a plan (see placement.ahk) does: where each window lands, the placed one in SELECT_COLOR
; and the ones in its way in MOVED_COLOR with their titles, and each window it minimizes in
; MINIMIZED_COLOR where it is now. With no plan, the preview hides.
ShowPlan(plan := []) {
    static shown := [], last := ""
    if (key := PlanKey(plan)) = last
        return
    last := key
    for g in shown
        g.Destroy()
    shown := []
    for i, m in plan
        try shown.Push(ShowRect(PreviewGui(m, i = 1), m.rect || FrameRect(m.hwnd)))
}

PlanKey(plan) {
    key := ""
    for m in plan
        key .= m.hwnd ":" (m.rect ? m.rect.x "," m.rect.y "," m.rect.w "," m.rect.h : "min") ";"
    return key
}

; The placed window is a plain fill; the others carry their title, after a glyph when minimized.
PreviewGui(m, placed) {
    g := ClickThroughGui(placed ? SELECT_COLOR : m.rect ? MOVED_COLOR : MINIMIZED_COLOR, PREVIEW_ALPHA)
    if placed
        return g
    if !m.rect {
        g.SetFont("s14 c" TEXT_COLOR, "Segoe MDL2 Assets")
        g.AddText("x12 y12", Chr(0xE921))  ; minimize glyph
    }
    g.SetFont("s11 bold c" TEXT_COLOR, "Segoe UI")
    g.AddText((m.rect ? "x12" : "x+8") " y12", WinGetTitle(m.hwnd))
    return g
}

ShowRect(g, r) {
    g.Show("NA x" r.x " y" r.y " w" r.w " h" r.h)
    return g
}
