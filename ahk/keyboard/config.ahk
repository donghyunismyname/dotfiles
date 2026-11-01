; Settings of the key remapping. Needs keys.ahk.

COMBO_MS := 50
COMBOS := [
    {keys: [Ord("D"), Ord("F")], shift: VK_LSHIFT},
    {keys: [Ord("J"), Ord("K")], shift: VK_RSHIFT},
    {keys: [Ord("X"), Ord("C")], hangul: false},  ; English
    {keys: [VK_OEM_COMMA, VK_OEM_PERIOD], hangul: true},
]
SELECT_LAYER_KEY := Ord("L")
SELECT_LAYER_START := Ord("J")  ; the key that turns the layer on
SELECT_LAYER_MS := 100
SELECT_LAYER_ARROWS := Map(Ord("J"), VK_LEFT, Ord("K"), VK_RIGHT)  ; sent with Shift
HANGUL_TAP_MS := 250
ENGLISH_HOLD_KEY := VK_F13  ; the left space half sends it (via/)
