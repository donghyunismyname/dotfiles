#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\winevent.ahk
#Include %A_LineFile%\..\windows.ahk
#Include %A_LineFile%\..\grid.ahk
#Include %A_LineFile%\..\claims.ahk
#Include %A_LineFile%\..\model.ahk
#Include %A_LineFile%\..\sync.ahk
#Include %A_LineFile%\..\events.ahk
#Include %A_LineFile%\..\preview.ahk
#Include %A_LineFile%\..\rocker.ahk
#Include %A_LineFile%\..\mouse.ahk
#Include %A_LineFile%\..\border.ahk

; Window placement on a grid, like tmux panes. Each monitor's work area is split into equal cells; a pane
; is a rectangle of cells.
;
; Model. Each window on the grid has a stack of claims: the bottom one is the pane the user put it in,
; the ones above are where it was pushed to since, and the top one is where it is now. A claim is a pane,
; or "minimized" when the window was pushed out with nowhere to go, and carries the time it was made, so
; no two tie. A change runs in two steps:
;   action      the user puts a window in a pane, opens a new one, or restores one: a new claim, which
;               may land on cells another window holds
;   resolution  push: the windows in the way move aside onto new claims (PushAside), so no two windows
;               hold a cell; pop: windows drop back to the deepest claim in their stack whose cells are
;               free, the most recent claim first when several want the same cells (PopBack). A window
;               in place is never moved by popping.
; So closing or minimizing a window brings back what it pushed aside, as close to where the user wants it
; as the free cells allow. A window the user minimizes holds nothing until restored, when it claims its
; place anew; maximizing changes only how a window shows; one moved or resized by other means floats, off
; the grid and out of the model, until the user puts it on the grid again.
;
; Controls:
;   hold Right, press Left (rocker) and drag: every cell shows; the cells between where Left went down
;                     and the cursor make a pane, and releasing Left puts the window that was under the
;                     cursor when Right went down there. Releasing Right first, or Esc, cancels
;   drag Right onto another window: the window takes its pane, and the other its place; onto the desktop
;                     or a floating window: the cell there. Both preview where every window will go
;   drag Right (gestures, on the window under the cursor): 8 directions, see GESTURES
;   hold Right, wheel down / up: Ctrl+Tab / Ctrl+Shift+Tab (next / previous tab)
; A newly opened app window goes to the first free cell, else takes the pane of the window claimed longest
; ago. Dialogs and other fixed-size windows float. The active window also gets a colored border.

; ---- Config ----
GRID_LANDSCAPE := {rows: 2, cols: 4}  ; cells of a monitor wider than tall
GRID_PORTRAIT := {rows: 4, cols: 2}
GRID_GAP := 6              ; px between neighboring cells, and between a cell and the work area's edge
MATCH_TOLERANCE := 16      ; px of slack when deciding whether a window fills a pane
NEW_WINDOW_DELAY_MS := 300 ; after a new window is shown, so its app has placed it and set its title
SETTLE_DELAY_MS := 50      ; after windows close or hide, so a burst of them settles once
DRIFT_CHECK_DELAY_MS := 500 ; after a window on the grid moves by other means, before checking where it is
OWN_CHANGE_MS := 1000      ; how long events from a window the script changed are taken for its own
POLL_MS := 20              ; how often the rocker and drag previews follow the cursor
WHILE_RIGHT_HELD := Map(  ; button pressed while Right is held -> action
    "LButton",   StartSelection,            ; rocker
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
; Colors, RGB hex, and opacities, 0-255
BORDER_COLOR := "2A5CC8"          ; focus border
BORDER_WIDTH := GRID_GAP          ; drawn outside the active window, so it fills the gap around it
ROCKER_CELL_COLOR := "1F1F1F"     ; cells shown by the rocker
ROCKER_CELL_ALPHA := 140
PREVIEW_PUT_COLOR := "2A5CC8"     ; where the window being put goes
PREVIEW_MOVED_COLOR := "C87A2A"   ; where another window goes
PREVIEW_MINIMIZED_COLOR := "B03A3A" ; another window that gets minimized
PREVIEW_TEXT_COLOR := "FFFFFF"    ; window titles
PREVIEW_ALPHA := 150

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")  ; gesture start and end are compared across windows
A_IconTip := "panes"
StartMouse()
StartRocker()
StartBorder()
StartEvents()
