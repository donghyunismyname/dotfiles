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
SELECT_LAYER_MS := 200
SELECT_LAYER_ARROWS := Map(Ord("J"), VK_LEFT, Ord("K"), VK_RIGHT)  ; sent with Shift
SHIFT_TAP_MS := 250
SHIFT_TAPS := Map(VK_LSHIFT, ToggleInputMode)
MODE_LAYER_KEY := VK_F13  ; the left space half sends it (via/)
MODE_LAYER_SHIFT_KEY := VK_SPACE  ; the right space half, held as Shift
MODE_LAYER_MAP := Map(    ; key -> what it sends while MODE_LAYER_KEY is held: {vk, shift?}
    VK_ESC, {vk: VK_OEM_3},               ; `
    VK_TAB, {vk: VK_OEM_3, shift: true},  ; ~
)
