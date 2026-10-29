; A window's claims, its stack, are stored on the window itself as window properties, so they go away
; with the window and outlive a restart of the script. panes.claims holds how many there are, and
; panes.claim1, panes.claim2, ... each one, bottom first, as its time and its pane (PackPane, or 0 for a
; minimized claim). panes.claims is FLOATING for a window that left the grid; a window without it has
; not been seen by the script yet.

FLOATING := -1

; The window's claims, bottom first, each {pane, time} with pane "" for a minimized claim; "floating";
; or "" for a window not seen yet. Claims on cells that are gone (a monitor unplugged) are dropped, and a
; window left without a pane to claim floats.
ReadClaims(hwnd, grids) {
    n := GetProp(hwnd, "panes.claims")
    if !n
        return ""
    if n = FLOATING
        return "floating"
    claims := [], anyPane := false
    loop n {
        v := GetProp(hwnd, "panes.claim" A_Index), code := v & 0xFFFFF
        if code && !(p := UnpackPane(code, grids))
            continue
        claims.Push({pane: code ? p : "", time: v >> 20})
        anyPane := anyPane || code
    }
    return anyPane ? claims : "floating"
}

WriteClaims(hwnd, claims) {
    old := GetProp(hwnd, "panes.claims")
    for i, c in claims
        SetProp(hwnd, "panes.claim" i, c.time << 20 | (c.pane ? PackPane(c.pane) : 0))
    loop old - claims.Length
        SetProp(hwnd, "panes.claim" (claims.Length + A_Index), 0)
    SetProp(hwnd, "panes.claims", claims.Length)
}

SetFloating(hwnd) {
    WriteClaims(hwnd, [])
    SetProp(hwnd, "panes.claims", FLOATING)
}

IsManaged(hwnd) => GetProp(hwnd, "panes.claims") > 0

; The time for a new claim: milliseconds since 2020, and later than any claim before, so no two tie.
NewClaimTime() {
    static last := 0
    DllCall("GetSystemTimeAsFileTime", "int64*", &now := 0)  ; 100 ns units since 1601
    return last := Max(now // 10000 - 13222310400000, last + 1)
}

GetProp(hwnd, name) => DllCall("GetProp", "ptr", hwnd, "str", name, "ptr")

; Setting 0 removes the property.
SetProp(hwnd, name, v) => v ? DllCall("SetProp", "ptr", hwnd, "str", name, "ptr", v) : DllCall("RemoveProp", "ptr", hwnd, "str", name, "ptr")
