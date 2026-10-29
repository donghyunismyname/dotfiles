; What the script keeps about a window lives on the window itself, as window properties, so it goes away
; with the window and outlives a restart of the script:
;   panes.want     the pane the window is meant to be in, or FLOATING when it is meant to be off the grid;
;                  set when the user puts it somewhere, and when it first shows up
;   panes.at       the pane the script last put it in, to recognize it there when an app's minimum size
;                  keeps it larger than the pane
;   panes.evicted  set while it is minimized to make room, so it comes back by itself
; Panes are stored packed into integers (PackPane).

FLOATING := 1

Want(hwnd, grids) => UnpackPane(GetProp(hwnd, "panes.want"), grids)
IsKnown(hwnd) => GetProp(hwnd, "panes.want") != 0
SetWant(hwnd, p) => SetProp(hwnd, "panes.want", p ? PackPane(p) : FLOATING)
PlacedAt(hwnd, grids) => UnpackPane(GetProp(hwnd, "panes.at"), grids)
SetPlacedAt(hwnd, p) => SetProp(hwnd, "panes.at", p ? PackPane(p) : 0)
IsEvicted(hwnd) => GetProp(hwnd, "panes.evicted") != 0
SetEvicted(hwnd, on) => SetProp(hwnd, "panes.evicted", on ? 1 : 0)

GetProp(hwnd, name) => DllCall("GetProp", "ptr", hwnd, "str", name, "ptr")

; Setting 0 removes the property.
SetProp(hwnd, name, v) => v ? DllCall("SetProp", "ptr", hwnd, "str", name, "ptr", v) : DllCall("RemoveProp", "ptr", hwnd, "str", name, "ptr")
