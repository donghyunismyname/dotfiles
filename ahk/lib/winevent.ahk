; Window events (SetWinEventHook) from every other process, delivered out of context.

EVENT_SYSTEM_FOREGROUND := 0x0003
EVENT_SYSTEM_MOVESIZEEND := 0x000B
EVENT_SYSTEM_MINIMIZESTART := 0x0016
EVENT_SYSTEM_MINIMIZEEND := 0x0017
EVENT_OBJECT_SHOW := 0x8002
EVENT_OBJECT_HIDE := 0x8003
EVENT_OBJECT_FOCUS := 0x8005
EVENT_OBJECT_LOCATIONCHANGE := 0x800B
EVENT_OBJECT_TEXTSELECTIONCHANGED := 0x8014
IA2_EVENT_TEXT_CARET_MOVED := 0x011B  ; IAccessible2 events, sent by Chromium
IA2_EVENT_TEXT_INSERTED := 0x011E
IA2_EVENT_TEXT_REMOVED := 0x011F
OBJID_WINDOW := 0
OBJID_CARET := -8

; Calls fn(event, hwnd, idObject) for each of the events. fn runs in the middle of whatever the
; script is doing (fast callback), so it should only schedule work, e.g. with SetTimer.
HookWinEvents(events, fn) {
    static hooks := []
    if !hooks.Length
        OnExit(UnhookAll)  ; events keep arriving while AHK frees the globals at exit
    ; event and idObject are 32-bit, so the upper half of their registers is not theirs.
    proc := CallbackCreate((hook, event, hwnd, idObject, *) => fn(event & 0xFFFFFFFF, hwnd, idObject << 32 >> 32), "F", 7)
    for event in events
        hooks.Push(DllCall("SetWinEventHook", "uint", event, "uint", event, "ptr", 0, "ptr", proc,
            "uint", 0, "uint", 0, "uint", 2, "ptr"))  ; WINEVENT_SKIPOWNPROCESS

    UnhookAll(*) {
        for h in hooks
            DllCall("UnhookWinEvent", "ptr", h)
    }
}
