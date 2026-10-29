#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\..\lib\util.ahk
#Include %A_LineFile%\..\..\lib\winevent.ahk
#Include %A_LineFile%\..\windows.ahk
#Include %A_LineFile%\..\cells.ahk
#Include %A_LineFile%\..\props.ahk
#Include %A_LineFile%\..\placement.ahk
#Include %A_LineFile%\..\settle.ahk
#Include %A_LineFile%\..\preview.ahk
#Include %A_LineFile%\..\rocker.ahk
#Include %A_LineFile%\..\mouse.ahk
#Include %A_LineFile%\..\border.ahk

; Window placement on a grid, like tmux panes. Each monitor's work area is split into cells; a pane is
; a rectangle of one or more cells holding one window. Cells are ordered by monitor, row, then column.
;   hold Right, press Left (rocker) and drag: every cell shows; the cells between where Left went down
;                     and the cursor make a pane, and releasing Left fits the window that was under the
;                     cursor when Right went down to it. Releasing Right first, or Esc, cancels
;   hold Right, wheel down / up: Ctrl+Tab / Ctrl+Shift+Tab (next / previous tab)
;   drag Right (gestures, on the window under the cursor): 8 directions, see GESTURES
;   drag Right onto another window: the two swap places and sizes; onto the desktop: the window goes to
;                     the cell there
; Both the rocker and a drag onto something preview the result: where each window will go, and which
; ones will be minimized.
; Windows in the way of a pane move out (see PlanPane): to its old pane, or the first free cells, or
; else they are minimized.
; A window counts as in a pane when it fills it, or when the script put it there and its top-left corner
; is still there: an app's minimum size can keep it larger than the pane.
; Each window wants the pane the user last put it in (settle.ahk). One pushed out goes back by itself,
; without the focus, once that pane is free again, even from minimized; one the user minimized stays
; so, and comes back there when restored, or to a free pane until it is free. A newly opened app window
; goes to the first free cell, else takes the pane of the least recently active window. Dialogs and
; popups stay where their app puts them.
; The active window also gets a colored border.

; ---- Config ----
LANDSCAPE_GRID := {rows: 2, cols: 4}  ; cells of a monitor wider than tall
PORTRAIT_GRID := {rows: 4, cols: 2}
NEW_WINDOW_DELAY_MS := 300 ; after a new window is shown, so its app has placed it and set its title
LAYOUT_SETTLE_MS := 300    ; after the layout changes, before moving windows back where they want to be
POLL_MS := 20              ; how often the rocker and drag previews follow the cursor
WHILE_RIGHT_HELD := Map(  ; button pressed while Right is held -> action
    "LButton",   SelectAndPlace,            ; rocker
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
MARGIN := 6              ; px between cells, and between a cell and the work area's edge
MATCH_TOLERANCE := 16    ; px of slack when deciding which pane a window fills
; Colors, RGB hex, and opacities, 0-255
BORDER_COLOR := "2A5CC8" ; focus border
CELL_COLOR := "1F1F1F"   ; cells shown by the rocker
CELL_ALPHA := 140
SELECT_COLOR := "2A5CC8" ; preview: where the placed window goes
MOVED_COLOR := "C87A2A"  ; preview: where a window in its way goes
MINIMIZED_COLOR := "B03A3A" ; preview: a window in its way that gets minimized
TEXT_COLOR := "FFFFFF"   ; preview: window titles
PREVIEW_ALPHA := 150
BORDER_WIDTH := MARGIN   ; drawn outside the active window, so it fills the margin around a pane

; Work in physical pixels on every monitor, even with mixed display scaling.
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
CoordMode("Mouse", "Screen")  ; gesture start and end are compared across windows
A_IconTip := "panes"
StartMouse()
StartBorder()
StartSettle()
