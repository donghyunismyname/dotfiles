; Where the text caret is, in screen coordinates.

; Text caret of the foreground window, with the control that has the focus.
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
    static TextPattern2Id := 10024, TextPatternId := 10014
    ; Method numbers in each interface's vtable (IUnknown's three come first).
    static GetFocusedElement := 8                                     ; IUIAutomation
    static GetCurrentPatternAs := 14, CurrentBoundingRectangle := 43  ; IUIAutomationElement
    static GetSelection := 5, GetCaretRange := 10                     ; IUIAutomationTextPattern(2)
    static RangeCount := 3, GetRange := 4                             ; IUIAutomationTextRangeArray
    static ExpandToEnclosingUnit := 6, GetBoundingRectangles := 10    ; IUIAutomationTextRange
    ; Every pointer is checked: a call through a null one crashes the process instead of throwing.
    Unk(p) => p ? ComValue(13, p) : ""
    if !el := (ComCall(GetFocusedElement, uia, "ptr*", &p := 0, "int"), Unk(p))  ; none while switching windows
        return ""
    range := ""
    if (ComCall(GetCurrentPatternAs, el, "int", TextPattern2Id, "ptr", iidText2, "ptr*", &p := 0, "int"), tp := Unk(p)) {
        ComCall(GetCaretRange, tp, "int*", &active := 0, "ptr*", &p := 0, "int"), range := Unk(p)
    } else if (ComCall(GetCurrentPatternAs, el, "int", TextPatternId, "ptr", iidText, "ptr*", &p := 0, "int"), tp := Unk(p)) {
        if (ComCall(GetSelection, tp, "ptr*", &p := 0, "int"), ranges := Unk(p)) {
            ComCall(RangeCount, ranges, "int*", &n := 0, "int")
            if n
                ComCall(GetRange, ranges, "int", 0, "ptr*", &p := 0, "int"), range := Unk(p)
        }
    }
    if !range
        return ""
    loop 2 {  ; a collapsed range may have no rectangle; then take the character at the caret
        ComCall(GetBoundingRectangles, range, "ptr*", &psa := 0, "int")  ; SAFEARRAY of [left, top, width, height] doubles
        if !psa
            return ""
        n := NumGet(psa, 24, "uint"), d := NumGet(psa, 16, "ptr")
        r := n >= 4 ? {x: Round(NumGet(d, 0, "double")), y: Round(NumGet(d, 8, "double")), h: Round(NumGet(d, 24, "double"))} : ""
        DllCall("oleaut32\SafeArrayDestroy", "ptr", psa)
        if r
            return (r.x || r.y) && r.h > 0 ? r : ""
        if A_Index = 1
            ComCall(ExpandToEnclosingUnit, range, "int", 0, "int")  ; TextUnit_Character
    }
    ; An empty field has no character to measure: use the field's top-left corner, one line high.
    rc := Buffer(16, 0)
    ComCall(CurrentBoundingRectangle, el, "ptr", rc, "int")
    x := NumGet(rc, 0, "int"), y := NumGet(rc, 4, "int"), h := Min(NumGet(rc, 12, "int") - y, EMPTY_LINE_H)
    return (x || y) && h > 0 ? {x: x, y: y, h: h} : ""
}
