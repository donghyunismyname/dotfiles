#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\lib\util.ahk
#Include %A_LineFile%\..\lib\winevent.ahk
#Include %A_LineFile%\..\panes\windows.ahk
#Include %A_LineFile%\..\panes\placement.ahk
#Include %A_LineFile%\..\panes\autoplace.ahk
#Include %A_LineFile%\..\panes\overlay.ahk
#Include %A_LineFile%\..\panes\mouse.ahk
#Include %A_LineFile%\..\panes\border.ahk

; Pane-based window placement.
;   hold Right, click Left (rocker): every pane shows a tile per open window; click a tile to put that
;                     window there, or the first tile to minimize every window in that pane. Clicking a
;                     pane's background moves the active window there.
;                     Right-click, Esc, or any key cancels
;   hold Right, wheel down / up: Ctrl+Tab / Ctrl+Shift+Tab (next / previous tab)
;   drag Right (gestures, on the window under the cursor): 8 directions, see GESTURES
;   drag Right out of the window onto a pane: move the window there, like a pick from the overlay
; Panes are fractions of a monitor's work area: tiles and whole monitors. A pane holds any number of
; windows; moving a window from one tile to another swaps it with the target tile's top window.
; A window restored from minimized, or a newly opened app window, goes to HOME_TILE, on top of the
; windows there. Dialogs and popups stay where their app puts them.
; The active window also gets a colored border.

; ---- Config ----
TILES := [
    {name: "Left",   mon: 1, x: 0,   y: 0,   w: 0.5, h: 1},
    {name: "Right",  mon: 1, x: 0.5, y: 0,   w: 0.5, h: 1},
    {name: "Top",    mon: 2, x: 0,   y: 0,   w: 1,   h: 0.5},
    {name: "Bottom", mon: 2, x: 0,   y: 0.5, w: 1,   h: 0.5},
]
WHOLES := [
    {name: "Wide",   mon: 1, x: 0,   y: 0,   w: 1,   h: 1},
    {name: "Tall",   mon: 2, x: 0,   y: 0,   w: 1,   h: 1},
]
PANES := TILES.Clone()
PANES.Push(WHOLES*)
HOME_TILE := TILES[1]      ; where windows restored from minimized and newly opened app windows go
RESTORE_DELAY_MS := 100    ; after a window is minimized or restored, before acting on it
NEW_WINDOW_DELAY_MS := 300 ; after a new window is shown, so its app has placed it and set its title
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
MARGIN := 6              ; px between panes, and between a pane and the work area's edge
MATCH_TOLERANCE := 16    ; px of slack when deciding which pane a window is in
ICON_SIZE := 32
TILE_W := 110            ; px per window tile: icon with its title below
TILE_H := 84
; Colors, RGB hex
BORDER_COLOR := "2A5CC8" ; focus border
BACK_COLOR := "1F1F1F"   ; pane overlays, bands included
KEY_COLOR := "1F1F1E"    ; never drawn: keyed out so the translucent backdrop shows through
TEXT_COLOR := "E6E6E6"
BACK_ALPHA := 200        ; overlay backdrop opacity, 0-255; icons and text stay opaque
BORDER_WIDTH := MARGIN   ; drawn outside the active window, so it fills the margin around a pane

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")  ; gesture start and end are compared across windows
A_IconTip := "panes"
SnapToPanes()
StartMouse()
StartBorder()
StartAutoPlace()

PickAndPlace() {
    static busy := false  ; the rocker may fire again while the overlay is open; only one at a time
    if busy
        return
    busy := true
    active := WinExist("A")  ; before the overlay takes focus
    try {
        if !(pick := PickPaneAndWindow())
            return
        if pick.HasOwnProp("background") {
            if active && IsAppWindow(active)
                Place(active, pick.pane)
        }
        else if pick.hwnd
            Place(pick.hwnd, pick.pane)
        else
            MinimizePane(pick.pane)
    } finally {
        busy := false
    }
}
