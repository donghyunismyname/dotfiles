#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\lib\util.ahk

; Keyboard navigation over clickable elements, found through UI Automation (the accessibility API).
;   Ctrl+Space  outlines every clickable element of the active window and highlights the one nearest
;               the keyboard focus. Arrows (or hjkl) move the highlight to the nearest element that way;
;               Enter clicks it (Shift+Enter right-clicks). Any other key cancels.

; ---- Config ----
KEY_SHOW := "^Space"
MOVES := Map("Left", "Left", "Right", "Right", "Up", "Up", "Down", "Down", "h", "Left", "j", "Down", "k", "Up", "l", "Right")
KEY_CLICK := "Enter"
TIMEOUT_S := 15
ACROSS_WEIGHT := 3       ; how much sideways offset counts against a candidate, relative to distance ahead
SLACK := 4               ; px a candidate may overlap the current element and still count as ahead
; UIA control types treated as clickable
CLICKABLE := [50000, 50002, 50003, 50004, 50005, 50007, 50011, 50013, 50019, 50024, 50029, 50031, 50035]
; Button, CheckBox, ComboBox, Edit, Hyperlink, ListItem, MenuItem, RadioButton, TabItem, TreeItem, DataItem, SplitButton, HeaderItem
; Colors, RGB hex
OUTLINE_COLOR := "8A8A8A"
OUTLINE_ALPHA := 160     ; 0-255
HIGHLIGHT_COLOR := "FF9F1C"
HIGHLIGHT_WIDTH := 3
KEY_COLOR := "010101"    ; never drawn: keyed out so only the outlines show

; Work in physical pixels on every monitor, even with mixed display scaling; UIA follows the thread.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")
A_IconTip := "nav"
uia := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")  ; CUIAutomation, IUIAutomation
condition := ClickableCondition()
highlightBars := []
loop 4
    highlightBars.Push(ClickThroughGui(HIGHLIGHT_COLOR))
Hotkey(KEY_SHOW, (*) => Nav())

Nav() {
    if !(els := Elements(WinExist("A"))).Length {
        ToolTip("No clickable elements"), SetTimer(ToolTip, -1000)
        return
    }
    outlines := ShowOutlines(els)
    cur := Nearest(els, StartPoint())
    loop {
        Highlight(cur)
        key := ReadKey()
        if !MOVES.Has(key)
            break
        cur := Ahead(els, cur, MOVES[key]) || cur
    }
    for g in highlightBars
        g.Hide()
    outlines.Destroy()
    if key = KEY_CLICK
        Click((cur.l + cur.r) // 2 " " (cur.t + cur.b) // 2 " " (GetKeyState("Shift", "P") ? "Right" : "Left"))
}

; ---- UI Automation ----

; Not offscreen and of a CLICKABLE control type.
ClickableCondition() {
    types := Buffer(CLICKABLE.Length * A_PtrSize)
    for i, type in CLICKABLE
        NumPut("ptr", PropertyCondition(30003, 3, type), types, (i - 1) * A_PtrSize)  ; ControlType, VT_I4
    ComCall(30, uia, "ptr", types, "int", CLICKABLE.Length, "ptr*", &anyType := 0)  ; CreateOrConditionFromNativeArray
    ComCall(25, uia, "ptr", PropertyCondition(30022, 11, 0), "ptr", anyType, "ptr*", &cond := 0)  ; CreateAndCondition; IsOffscreen, VT_BOOL
    return cond  ; the parts stay referenced for the script's lifetime, which is fine
}

PropertyCondition(propertyId, vt, value) {
    v := Buffer(24, 0)  ; VARIANT, passed by reference on x64
    NumPut("ushort", vt, v, 0), NumPut("int", value, v, 8)
    ComCall(23, uia, "int", propertyId, "ptr", v, "ptr*", &cond := 0)  ; CreatePropertyCondition
    return cond
}

; Bounding rectangles of the window's clickable elements, in screen pixels, without duplicates.
Elements(hwnd) {
    els := [], seen := Map()
    if !hwnd
        return els
    ComCall(20, uia, "ptr*", &cache := 0)  ; CreateCacheRequest
    ComCall(3, cache, "int", 30001)        ; AddProperty: BoundingRectangle
    ComCall(11, cache, "int", 0)           ; put_AutomationElementMode: none, only the cached values are needed
    try {
        ComCall(6, uia, "ptr", hwnd, "ptr*", &root := 0)  ; ElementFromHandle
        ComCall(8, root, "int", 4, "ptr", condition, "ptr", cache, "ptr*", &found := 0)  ; FindAllBuildCache, TreeScope_Descendants
        ComCall(3, found, "int*", &n := 0)  ; get_Length
        rect := Buffer(16)
        loop n {
            ComCall(4, found, "int", A_Index - 1, "ptr*", &el := 0)  ; GetElement
            ComCall(75, el, "ptr", rect)  ; get_CachedBoundingRectangle
            ObjRelease(el)
            r := {l: NumGet(rect, 0, "int"), t: NumGet(rect, 4, "int"), r: NumGet(rect, 8, "int"), b: NumGet(rect, 12, "int")}
            if r.r > r.l && r.b > r.t && !seen.Has(key := r.l "," r.t "," r.r "," r.b)
                seen[key] := true, els.Push(r)
        }
        ObjRelease(found)
    }
    if IsSet(root) && root
        ObjRelease(root)
    ObjRelease(cache)
    return els
}

; Center of the element with keyboard focus, or the mouse cursor when there is none.
StartPoint() {
    try {
        ComCall(8, uia, "ptr*", &el := 0)  ; GetFocusedElement
        rect := Buffer(16)
        ComCall(43, el, "ptr", rect)  ; get_CurrentBoundingRectangle
        ObjRelease(el)
        if NumGet(rect, 8, "int") > NumGet(rect, 0, "int")
            return {x: (NumGet(rect, 0, "int") + NumGet(rect, 8, "int")) // 2, y: (NumGet(rect, 4, "int") + NumGet(rect, 12, "int")) // 2}
    }
    MouseGetPos(&x, &y)
    return {x: x, y: y}
}

; ---- Navigation ----

Nearest(els, p) {
    best := els[1], bestDist := 1e18
    for e in els
        if (d := ((e.l + e.r) / 2 - p.x) ** 2 + ((e.t + e.b) / 2 - p.y) ** 2) < bestDist
            best := e, bestDist := d
    return best
}

; The element ahead of cur in dir with the lowest distance ahead plus weighted sideways gap, or "".
Ahead(els, cur, dir) {
    best := "", bestScore := 1e18
    for e in els {
        switch dir {
            case "Right": ahead := e.l - cur.r, side := Max(e.t - cur.b, cur.t - e.b, 0)
            case "Left":  ahead := cur.l - e.r, side := Max(e.t - cur.b, cur.t - e.b, 0)
            case "Down":  ahead := e.t - cur.b, side := Max(e.l - cur.r, cur.l - e.r, 0)
            case "Up":    ahead := cur.t - e.b, side := Max(e.l - cur.r, cur.l - e.r, 0)
        }
        if e != cur && ahead >= -SLACK && (score := Max(ahead, 0) + ACROSS_WEIGHT * side) < bestScore
            best := e, bestScore := score
    }
    return best
}

; ---- Drawing ----

; One click-through window over all the elements, with a 1px outline around each.
ShowOutlines(els) {
    l := t := 1e9, r := b := -1e9
    for e in els
        l := Min(l, e.l), t := Min(t, e.t), r := Max(r, e.r), b := Max(b, e.b)
    g := ClickThroughGui(KEY_COLOR)
    for e in els {
        x := e.l - l, y := e.t - t, w := e.r - e.l, h := e.b - e.t
        for bar in [[x, y, w, 1], [x, y + h - 1, w, 1], [x, y, 1, h], [x + w - 1, y, 1, h]]
            g.AddText("x" bar[1] " y" bar[2] " w" bar[3] " h" bar[4] " Background" OUTLINE_COLOR)
    }
    g.Show("NA x" l " y" t " w" r - l " h" b - t)
    WinSetTransColor(KEY_COLOR " " OUTLINE_ALPHA, g)
    return g
}

; Four bars just outside the element.
Highlight(e) {
    t := HIGHLIGHT_WIDTH
    x := e.l - t, y := e.t - t, w := e.r - e.l + 2 * t, h := e.b - e.t + 2 * t
    for i, bar in [[x, y, w, t], [x, y + h - t, w, t], [x, y, t, h], [x + w - t, y, t, h]]
        highlightBars[i].Show("NA x" bar[1] " y" bar[2] " w" bar[3] " h" bar[4])
}

; Waits for one key down, blocking it from the app; returns its name, or "" on timeout.
ReadKey() {
    state := {key: ""}
    ih := InputHook("T" TIMEOUT_S)
    ih.KeyOpt("{All}", "NS")  ; every key down is reported and blocked
    ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-NS")  ; modifiers pass, so a held Ctrl does not cancel
    ih.OnKeyDown := (ih, vk, sc) => (state.key := GetKeyName(Format("vk{:x}", vk)), ih.Stop())
    ih.Start()
    ih.Wait()
    return state.key
}
