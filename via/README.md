# VIA: GUTS WECAT6

| File | What |
| --- | --- |
| `GUTS_WECAT6.json` | Keyboard definition. VIA has no built-in entry for this board, so load it in VIA → Settings → Show Design tab → Design → Load Draft Definition. |
| `guts_wecat6.layout.json` | Current keymap (layers, macros, encoder). VIA → Save + Load → Load to apply, Save to update this file. |
| `guts_wecat6.default.layout.json` | Factory keymap, kept unchanged to reset to. |
| `GUTS_WECAT6_v7.hex` | Vendor firmware v7 that the definition matches. |

In the factory keymap, layers 0/1 are the Windows base and its Fn layer; layers 2/3 are the macOS base and its Fn layer.
In the current keymap, left space sends F13, which `ahk/keyboard` (modelayer.ahk) turns into a layer: the other input mode (Hangul / English) while held, `` ` `` on Esc, `~` on Tab.
Layer 2 is no longer reachable (left space used to be `MO(2)` for it: F1–F12 on the number row, arrows on HJKL, Y on U, Home/End on I/O, Shift on F, digits on the bottom row, Right Alt on right space).
Layer 3 is unused.
The firmware fixes the layer count at 4.
