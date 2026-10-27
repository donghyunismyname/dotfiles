#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\lib\admin.ahk

; Input indicator: a small "한" / "A" box just below the text caret shows the input mode.
; Kept apart from zones.ahk: its calls into other apps can block for a while, and AHK has one thread,
; so inside zones.ahk they would stall the mouse hook.
; Updated on window events (caret moved, text changed, focus or foreground changed) and the 한/영 key.

; ---- Config ----
HANGUL_COLOR := "2A5CC8"  ; RGB hex
ENGLISH_COLOR := "4A4A4A"
TEXT_COLOR := "E6E6E6"
UPDATE_DELAY_MS := 30     ; after an event, so a burst of events causes one update
EMPTY_LINE_H := 24        ; px; an empty field has no text to measure a line by

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
A_IconTip := "ime"
imeTip := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020")  ; layered + transparent: clicks pass through
imeTip.SetFont("s9 bold c" TEXT_COLOR, "Segoe UI")
imeLabel := imeTip.AddText("x0 y0 w20 h18 Center 0x200", "")  ; 0x200: vertically centered
WinSetTransparent(255, imeTip)

; Window events that may move the caret, from every process (out of context, skipping this one).
WATCHED := Map(
    0x0003, "foreground",
    0x000B, "move or resize ended",
    0x8002, "shown",        ; with OBJID_CARET: the caret appeared
    0x8003, "hidden",
    0x8005, "focus",
    0x800B, "location",     ; only for OBJID_CARET, see OnWinEvent
    0x8014, "text selection",
    0x011B, "caret moved",  ; IAccessible2 events, sent by Chromium
    0x011E, "text inserted",
    0x011F, "text removed",
)
winEventProc := CallbackCreate(OnWinEvent, "F")
for range in [[0x0003, 0x000B], [0x8002, 0x8014], [0x011B, 0x011F]]
    DllCall("SetWinEventHook", "uint", range[1], "uint", range[2], "ptr", 0, "ptr", winEventProc, "uint", 0, "uint", 0, "uint", 2, "ptr")
Hotkey("~vk15", (*) => SetTimer(UpdateImeTip, -UPDATE_DELAY_MS))  ; 한/영 key
UpdateImeTip()

OnWinEvent(hook, event, hwnd, idObject, *) {
    if WATCHED.Has(event) && (event != 0x800B || idObject & 0xFFFFFFFF = 0xFFFFFFF8)  ; OBJID_CARET: not every window move
        SetTimer(UpdateImeTip, -UPDATE_DELAY_MS)
}

UpdateImeTip() {
    static last := ""
    key := ""
    try {
        if c := FocusCaret()
            hangul := IsHangul(c.focus), key := c.x "," c.y "," c.h "," hangul
    }
    if key = last
        return
    last := key
    if !key
        return imeTip.Hide()
    imeTip.BackColor := hangul ? HANGUL_COLOR : ENGLISH_COLOR
    imeLabel.Text := hangul ? "한" : "A"
    imeTip.Show("NA x" c.x " y" c.y + c.h + 2 " w20 h18")
}

; Text caret of the foreground window in screen coordinates, with the control that has the focus.
FocusCaret() {
    info := Buffer(72, 0)  ; GUITHREADINFO
    NumPut("uint", 72, info)
    if !DllCall("GetGUIThreadInfo", "uint", 0, "ptr", info) || !(focus := NumGet(info, 16, "ptr"))
        return ""
    if caret := NumGet(info, 48, "ptr") {  ; a system caret, in its window's client coordinates
        pt := Buffer(8)
        NumPut("int", NumGet(info, 56, "int"), "int", NumGet(info, 60, "int"), pt)
        DllCall("ClientToScreen", "ptr", caret, "ptr", pt)
        return {focus: focus, x: NumGet(pt, 0, "int"), y: NumGet(pt, 4, "int"), h: NumGet(info, 68, "int") - NumGet(info, 60, "int")}
    }
    ; Apps that draw their own caret (Chrome, Electron, WinUI) report it through UI Automation.
    ; (MSAA's caret object is not used: on this Windows build querying it crashes the caller.)
    r := UiaCaretRect()
    return r ? {focus: focus, x: r.x, y: r.y, h: r.h} : ""
}

; Caret of the focused UI Automation element, or the start of its selection when it has no caret range
; (Chrome); interface pointers are wrapped in ComValue so they are released automatically.
UiaCaretRect() {
    static uia := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
    static iidText2 := Guid("{506a921a-fcc9-409f-b23b-37eb74106872}"), iidText := Guid("{32eba289-3583-42c9-9c59-3b6d9a1e9b6a}")
    ; Every pointer is checked: a call through a null one crashes the process instead of throwing.
    Unk(p) => p ? ComValue(13, p) : ""
    if !el := (ComCall(8, uia, "ptr*", &p := 0, "int"), Unk(p))  ; GetFocusedElement: none while switching windows
        return ""
    range := ""
    if (ComCall(14, el, "int", 10024, "ptr", iidText2, "ptr*", &p := 0, "int"), tp := Unk(p)) {  ; GetCurrentPatternAs TextPattern2
        ComCall(10, tp, "int*", &active := 0, "ptr*", &p := 0, "int"), range := Unk(p)  ; GetCaretRange
    } else if (ComCall(14, el, "int", 10014, "ptr", iidText, "ptr*", &p := 0, "int"), tp := Unk(p)) {  ; TextPattern
        if (ComCall(5, tp, "ptr*", &p := 0, "int"), ranges := Unk(p)) {  ; GetSelection
            ComCall(3, ranges, "int*", &n := 0, "int")
            if n
                ComCall(4, ranges, "int", 0, "ptr*", &p := 0, "int"), range := Unk(p)
        }
    }
    if !range
        return ""
    loop 2 {  ; a collapsed range may have no rectangle; then take the character at the caret
        ComCall(10, range, "ptr*", &psa := 0, "int")  ; GetBoundingRectangles: SAFEARRAY of [left, top, width, height] doubles
        if !psa
            return ""
        n := NumGet(psa, 24, "uint"), d := NumGet(psa, 16, "ptr")
        r := n >= 4 ? {x: Round(NumGet(d, 0, "double")), y: Round(NumGet(d, 8, "double")), h: Round(NumGet(d, 24, "double"))} : ""
        DllCall("oleaut32\SafeArrayDestroy", "ptr", psa)
        if r
            return (r.x || r.y) && r.h > 0 ? r : ""
        if A_Index = 1
            ComCall(6, range, "int", 0, "int")  ; ExpandToEnclosingUnit(TextUnit_Character)
    }
    ; An empty field has no character to measure: use the field's top-left corner, one line high.
    rc := Buffer(16, 0)
    ComCall(43, el, "ptr", rc, "int")  ; get_CurrentBoundingRectangle
    x := NumGet(rc, 0, "int"), y := NumGet(rc, 4, "int"), h := Min(NumGet(rc, 12, "int") - y, EMPTY_LINE_H)
    return (x || y) && h > 0 ? {x: x, y: y, h: h} : ""
}

Guid(s) {
    b := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", s, "ptr", b)
    return b
}

; Hangul mode of the window's IME: bit 0 (native) of its conversion mode.
IsHangul(hwnd) {
    ime := DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr")
    mode := 0  ; WM_IME_CONTROL, IMC_GETCONVERSIONMODE; SMTO_ABORTIFHUNG
    DllCall("SendMessageTimeoutW", "ptr", ime, "uint", 0x283, "ptr", 1, "ptr", 0, "uint", 2, "uint", 100, "ptr*", &mode)
    return mode & 1
}
