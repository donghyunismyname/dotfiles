#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\lib\admin.ahk
#Include %A_LineFile%\..\lib\util.ahk
#Include %A_LineFile%\..\lib\winevent.ahk
#Include %A_LineFile%\..\zones\windows.ahk
#Include %A_LineFile%\..\zones\placement.ahk
#Include %A_LineFile%\..\zones\overlay.ahk
#Include %A_LineFile%\..\zones\mouse.ahk
#Include %A_LineFile%\..\zones\border.ahk

; Zone-based window placement.
;   tap Left Shift    every zone shows a tile per open window; click a tile to put that window there,
;                     or the first tile to minimize every window in that zone. Clicking a zone's
;                     background moves the active window there (swapping with the window there).
;                     Right-click, Esc, or any key cancels
;   hold Right, click Left (rocker): same as tapping Left Shift
;   hold Right, wheel down / up: Ctrl+Tab / Ctrl+Shift+Tab (next / previous tab)
;   drag Right (gestures, on the window under the cursor): 8 directions, see GESTURES
;   Ctrl+Shift+Space  move the active window to MAIN_ZONE
; Zones are fractions of a monitor's work area and may overlap (Left, Right, and the whole monitor).
; Placing a window swaps it with the top window of the target zone when the two zones are disjoint;
; otherwise (overlapping zones, window not in any zone) the target's windows just stay behind.
; The active window also gets a colored border.

; ---- Config ----
ZONES := [
    {name: "Left",   mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},
    {name: "Right",  mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},
    {name: "Top",    mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},
    {name: "Bottom", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},
    {name: "Wide",   mon: 1, x: 0,   y: 0,   w: 1,   h: 1},
    {name: "Tall",   mon: 2, x: 0,   y: 0,   w: 1,   h: 1},
]
MAIN_ZONE := ZONES[1]
KEY_PICK := "LShift"     ; tapped alone
TAP_MAX_MS := 300        ; a longer press is not a tap
KEY_PROMOTE := "^+Space"
WHILE_RIGHT_HELD := Map(  ; button pressed while Right is held -> action
    "LButton",   PickAndPlace,              ; rocker
    "WheelDown", () => WheelTab("{Tab}"),   ; next tab
    "WheelUp",   () => WheelTab("+{Tab}"),  ; previous tab
)
GESTURE_PX := 80          ; a right-drag shorter than this is a plain right-click
GESTURES := Map(          ; drag direction -> keys to send, or a function called with the window
    "N",  (hwnd) => (WinGetMinMax(hwnd) = 1 ? WinRestore(hwnd) : WinMaximize(hwnd), WinActivate(hwnd)),  ; maximize or restore, and focus
    "S",  WinMinimize,
    "NW", "^+t",          ; reopen closed tab
    "NE", "^t",           ; new tab
    "W",  "^c",           ; copy
    "E",  "^v",           ; paste
    "SW", "^w",           ; close tab
    "SE", "{Enter}",
)
GAP := 2                 ; px each zone edge is inset, so neighboring zones are 2 * GAP apart
MATCH_TOLERANCE := 16    ; px of slack when deciding which zone a window is in
ICON_SIZE := 32
TILE_W := 110            ; px per window tile: icon with its title below
TILE_H := 84
; Colors, RGB hex
BORDER_COLOR := "2A5CC8" ; focus border
BACK_COLOR := "1F1F1F"   ; zone overlays, bands included
KEY_COLOR := "1F1F1E"    ; never drawn: keyed out so the translucent backdrop shows through
TEXT_COLOR := "E6E6E6"
BACK_ALPHA := 200        ; overlay backdrop opacity, 0-255; icons and text stay opaque
BORDER_WIDTH := 4

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")  ; gesture start and end are compared across windows
A_IconTip := "zones"
InstallMouseHook()  ; so Shift+click is not taken for a tap
Hotkey("~" KEY_PICK, OnPickKey)
Hotkey(KEY_PROMOTE, (*) => PromoteActive())
StartMouse()
StartBorder()

OnPickKey(*) {
    KeyWait(KEY_PICK)
    if A_PriorKey != KEY_PICK || A_TimeSinceThisHotkey > TAP_MAX_MS
        return
    PickAndPlace()
}

PickAndPlace() {
    static busy := false  ; the key and the rocker both open the overlay; only one at a time
    if busy
        return
    busy := true
    active := WinExist("A")  ; before the overlay takes focus
    try {
        if !(pick := PickZoneAndWindow())
            return
        if pick.HasOwnProp("background") {
            if active && WinExist(active) && IsAppWindow(active)
                Place(active, pick.zone)
        }
        else if pick.hwnd
            Place(pick.hwnd, pick.zone)
        else
            MinimizeZone(pick.zone)
    } finally {
        busy := false
    }
}

PromoteActive() {
    if (hwnd := WinExist("A")) && IsAppWindow(hwnd)
        Place(hwnd, MAIN_ZONE)
}
