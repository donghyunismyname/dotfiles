; Small helpers shared by the scripts.

; Topmost borderless window that clicks pass through (layered + transparent), sized in physical pixels.
ClickThroughGui(color) {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020")
    g.BackColor := color
    WinSetTransparent(255, g)
    return g
}

; A GUID string in its 16-byte binary form.
Guid(s) {
    b := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", s, "ptr", b)
    return b
}
