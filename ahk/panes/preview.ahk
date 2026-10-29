; Previews moves (LayoutMoves in model.ahk): where each window lands, the one being put first in
; PREVIEW_PUT_COLOR and the others in PREVIEW_MOVED_COLOR with their titles, and each window to be
; minimized in PREVIEW_MINIMIZED_COLOR where it is now. With no moves, the preview hides.
ShowMoves(list := []) {
    static shown := [], last := ""
    if (key := MovesKey(list)) = last
        return
    last := key
    for g in shown
        g.Destroy()
    shown := []
    for i, m in list
        try shown.Push(ShowRect(PreviewGui(m, i = 1), m.rect || FrameRect(m.hwnd)))
}

MovesKey(list) {
    key := ""
    for m in list
        key .= m.hwnd ":" (m.rect ? m.rect.x "," m.rect.y "," m.rect.w "," m.rect.h : "min") ";"
    return key
}

; The window being put is a plain fill; the others carry their title, after a glyph when minimized.
PreviewGui(m, isPut) {
    g := ClickThroughGui(isPut ? PREVIEW_PUT_COLOR : m.rect ? PREVIEW_MOVED_COLOR : PREVIEW_MINIMIZED_COLOR, PREVIEW_ALPHA)
    if isPut
        return g
    if !m.rect {
        g.SetFont("s14 c" PREVIEW_TEXT_COLOR, "Segoe MDL2 Assets")
        g.AddText("x12 y12", Chr(0xE921))  ; minimize glyph
    }
    g.SetFont("s11 bold c" PREVIEW_TEXT_COLOR, "Segoe UI")
    g.AddText((m.rect ? "x12" : "x+8") " y12", WinGetTitle(m.hwnd))
    return g
}

ShowRect(g, r) {
    g.Show("NA x" r.x " y" r.y " w" r.w " h" r.h)
    return g
}
