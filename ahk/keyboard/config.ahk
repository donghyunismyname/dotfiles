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
SHIFT_TAP_MS := 250
SHIFT_TAPS := Map(VK_LSHIFT, ToggleInputMode, VK_RSHIFT, ObjBindMethod(LastWord, "Convert"))
MODE_LAYER_KEY := VK_F13  ; the left space half sends it (via/)
MODE_LAYER_TAP_MS := 250
MODE_LAYER_MAP := Map(    ; key -> what it sends while MODE_LAYER_KEY is held: {vk, shift?}
    VK_ESC, {vk: VK_OEM_3},               ; `
    VK_TAB, {vk: VK_OEM_3, shift: true},  ; ~
    Ord("1"), {vk: VK_F1}, Ord("2"), {vk: VK_F1 + 1}, Ord("3"), {vk: VK_F1 + 2}, Ord("4"), {vk: VK_F1 + 3},
    Ord("5"), {vk: VK_F1 + 4}, Ord("6"), {vk: VK_F1 + 5}, Ord("7"), {vk: VK_F1 + 6}, Ord("8"), {vk: VK_F1 + 7},
    Ord("9"), {vk: VK_F1 + 8}, Ord("0"), {vk: VK_F1 + 9}, VK_OEM_MINUS, {vk: VK_F1 + 10}, VK_OEM_PLUS, {vk: VK_F1 + 11},
)
