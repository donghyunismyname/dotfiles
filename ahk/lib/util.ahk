; Small helpers shared by the scripts.

; Topmost borderless window that clicks pass through (layered + transparent), sized in physical pixels.
; alpha: opacity, 0-255.
ClickThroughGui(color, alpha := 255) {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020")
    g.BackColor := color
    WinSetTransparent(alpha, g)
    return g
}

; GUITHREADINFO of the foreground window's thread (focus at 16, caret window at 48, caret rect at 56),
; or "" when there is none.
GuiThreadInfo() {
    info := Buffer(72, 0)
    NumPut("uint", 72, info)
    return DllCall("GetGUIThreadInfo", "uint", 0, "ptr", info) ? info : ""
}

; A GUID string in its 16-byte binary form.
Guid(s) {
    b := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", s, "ptr", b)
    return b
}
