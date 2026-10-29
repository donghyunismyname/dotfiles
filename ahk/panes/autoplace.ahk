; Windows that appear on their own go to HOME_TILE: ones restored from minimized, and newly opened
; app windows. Dialogs, popups and other owned or fixed-size windows stay where their app puts them.

newWindows := Map()  ; top-level windows created but not shown yet

StartAutoPlace() {
    HookWinEvents([EVENT_SYSTEM_MINIMIZESTART], (event, hwnd, *) => SetTimer(AimRestore.Bind(hwnd), -RESTORE_DELAY_MS))
    HookWinEvents([EVENT_SYSTEM_MINIMIZEEND], (event, hwnd, *) => SetTimer(PlaceRestored.Bind(hwnd), -RESTORE_DELAY_MS))
    HookWinEvents([EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY, EVENT_OBJECT_SHOW], OnWindowLifecycle)
}

; Points a minimized window's restore position at HOME_TILE, so Windows brings it back there
; instead of where it was. Needs the window's border widths, measured while it was shown.
AimRestore(hwnd) {
    try {
        if IsAppWindow(hwnd) && WinGetMinMax(hwnd) = -1
            SetNormalRect(hwnd, PaneRect(HOME_TILE), 7)  ; SW_SHOWMINNOACTIVE: stay minimized
    }
}

; Places the window when AimRestore could not, and brings it to the front.
PlaceRestored(hwnd) {
    global restoring
    if hwnd = restoring
        return restoring := 0
    PlaceHome(hwnd)
}

; A window is new when it is shown for the first time after being created; a hidden window shown
; again (e.g. an app coming back from the tray) is not.
OnWindowLifecycle(event, hwnd, idObject) {
    if idObject != OBJID_WINDOW
        return
    if event = EVENT_OBJECT_CREATE {
        if DllCall("GetAncestor", "ptr", hwnd, "uint", 1, "ptr") = DllCall("GetDesktopWindow", "ptr")  ; GA_PARENT: top-level
            newWindows[hwnd] := true
    } else if newWindows.Has(hwnd) {
        newWindows.Delete(hwnd)
        if event = EVENT_OBJECT_SHOW
            SetTimer(PlaceNew.Bind(hwnd), -NEW_WINDOW_DELAY_MS)
    }
}

PlaceNew(hwnd) {
    try {
        if WinGetStyle(hwnd) & 0x40000  ; WS_THICKFRAME: resizable
            PlaceHome(hwnd)
    }
}

PlaceHome(hwnd) {
    try {
        if IsAppWindow(hwnd) && WinGetMinMax(hwnd) != -1
            Place(hwnd, HOME_TILE, true)
    }
}
