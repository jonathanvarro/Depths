# Playable art pass — inventory, Mara and interaction review

2026-10-18 · #92 / #36 / #98, related queue #96. This pass uses the current playable stock and drops. It does not add armour rules, items, starting grants, prices or balance changes.

## Inventory

`art/items/inventory-64-v1/catalog.json` indexes sixteen transparent 64×64 exports: thirteen approved starter illustrations plus copper ore and lit/unlit lanterns. Each has at least four pixels of exterior padding, a maximum 56px silhouette, binary alpha, at most 32 colours and nearest filtering. Keep the 64px canvas; do not trim an individual icon. Read them at 40px in Pack and 28 virtual pixels in camp rows. Thin spear/staff shafts intentionally remain thin; the full silhouette is visible at these sizes.

| Live resource | New icon |
| --- | --- |
| `data/gear/plain_knife.tres` | `plain-knife.png` |
| `data/gear/wooden_club.tres` | `wooden-club.png` |
| `data/gear/simple_spear.tres` | `simple-spear.png` |
| `data/gear/woodcutters_axe.tres` | `woodcutters-axe.png` |
| `data/gear/iron_sword.tres` | `iron-sword.png` (replaces full-size source at runtime) |
| `data/items/dressing.tres` | `clean-dressing.png` (replaces full-size source at runtime) |
| `data/items/copper_ore.tres` | `copper-ore.png` |

The brooch (`silver_trinket.tres`) and old coin purse already use the correct #90 exports; preserved. Existing oil/ration/draught/torch/broken-knife paths remain valid. Additional staff, shield, coat and antivenom exports are library assets; availability and equipment rules remain with game data.

Camp merchant/smith/sale rows now show the actual resource icon. The lantern upgrade shows the unlit lantern; Pack chooses lit/unlit/torch from its real light source and fuel. `gold-coin.svg` is a native 20px vector glyph for purse/prices, also readable at 16px; a UI symbol, separate from treasure illustrations or the coin-flip animation.

## Mara and shared lighting

`data/portraits/mara.tres` is the live tunic set. All eighteen PNGs in `art/portraits/mara-neutral-v1` keep a 192×192 canvas, origin (0,0), nearest filtering and lossless imports. Neutral character/tunic and frames share a 48-colour palette; conditions use small palettes and separate alpha. Five registered replacements provide half/closed eyes and small/open/round mouths. Blood, dirt, bandage and pallor retain their existing condition names.

The generated base/tunic remove the old orange rim and lamp cast shadows, while retaining natural material colour, local creases and facial volume. `base.png` contains the complete charcoal underlayer; `tunic.png` is removable clothing. `underlayer.tres` is a review variant with its own coordinated masks. Switch complete sets when changing this outfit: merely hiding the tunic while retaining its masks is not a validated outfit change. Old Mara drawings and animations are untouched.

PortraitSet's `light_shadow` / `light_highlight` are optional full-canvas textures. PortraitView applies them above the character and condition stack. Its background stays in a separate parent; hurt flash and card UI stay outside illumination. `set_illumination("neutral")`, `"warm"`, `"dim"` select explicit presets. Neutral hides both passes, warm uses restrained amber highlighting/shade, dim preserves a readable cool ambient floor. Reconfiguring kills prior blink/talk/hurt callbacks so they cannot restore a previous face.

Mara has separate black/white coverage for tunic and underlayer. Coverage is authored from generated masks, clustered at 32×32, expanded nearest to 192 and clipped to the exact composed silhouette. Shadow strength is alpha × (255 − luminance)/255; highlight is alpha × clamp((luminance − 110)/145). These are validated upper-left treatments, not arbitrary physical relighting.

All 27 existing recruit expression resources expose their already authored masks through the same fields. The optional recruit review adapter reuses them rather than drawing duplicate light passes; resource generators preserve this wiring. Party cards now retain nearest pixel filtering at 96px. Existing strain effects remain independent. No automatic oil-to-portrait lighting rule has been added.

## Interaction and consistency findings

- Selectable camp sites already had labels and mouse/pressed/keyboard outlines from Claude's clarity pass. Input-driven review confirms the full site is a target and Back restores its focus.
- Unaffordable stock now shows a persistent “Need Ng more” line as well as a disabled purchase, useful without a hover tooltip. Prices and item thumbnails follow actual resources. Touch height is at least 44px in both preview shapes.
- Pack and chest actions now accept keyboard focus; initial focus goes to Close. Scroll views follow focused actions. Usable and unavailable item states use the model's existing reasons; mouse/touch transfers and purchases occur once.
- Full-party condition details used to consume the phone's fixed vertical area. Condition, gear and supplies now share one scrolling region, preserving inventory access with three strained/injured heroes. This is the current live row UI; the accepted image-slot/equipment-tab redesign remains its separate design/integration work.
- Empty chests already display “Empty.” and disable Take all; reviewed with actual item transfers. The full opening confirms its looted chest flag/world empty state.
- All 28 live item/gear resources have 64px icons. `live-library-{dark,light}.png` compares each at native 64px and displayed 40px. Existing treasures retain their shared scale/padding/palettes; environments, portraits and floor props keep their own canvas/pivot contracts. No global rescaling or recolouring was applied.

## Sources and rebuild

New raster drawings use **built-in ImageGen**. Exact arguments/prompts and original generated masters are preserved in:

- [Inventory generation manifest](../art/source/inventory-64-v1/generation-manifest.json): copper ore, lantern, unlit variant. Other icons derive from unchanged `art/items/starter-v1` sources.
- [Mara generation manifest](../art/source/mara-neutral-v1/generation-manifest.json): neutral character, tunic, facial atlas, condition atlas and two-outfit lighting atlas.
- [Pallor correction prompt](../art/source/mara-neutral-v1/pallor-generation.json): continuous skin coverage replaces the atlas's patchy pallor. Export uses authored coverage clipped to visible skin at reduced opacity, preserving facial detail.
- `art/source/mara-neutral-v1/mara-neutral.ora`: editable full-canvas neutral/animation/condition/light layers, neutral tunic visible by default. Source and review folders have `.gdignore`.

Run `python -B tools/art/build_inventory_icons.py --wire` and `python -B tools/art/build_mara_neutral.py`, then Godot 4.7.2 editor import. Recruit resources can be rebuilt through the existing `make_resource` / `resources` helpers without regenerating their art. Source hashes, export hashes, padding, palettes and registration are recorded in each review folder's `asset-validation.json`.

## Verification

`tools/art/check_priority_art.gd` uses real mouse input on desktop and ScreenTouch input in the landscape-phone preview, the actual Main/camp/Pack/chest flow and the canonical PortraitView. It verifies all 28 resource icons, safe touch heights, disabled actions, one purchase/use/transfer per input, keyboard activation, restored focus, three-hero scrolling, conditions, animation reconfiguration and neutral/warm/dim light separation. Captures and its JSON report are in `art/concepts/inventory-64-v1` and `art/concepts/mara-neutral-v1` (1280×720 / 1278×590; 192px / 96px portraits). All 222 functional assertions pass.

Regressions: original recruit kit 424 checks and expanded roster 2,413 checks pass (48 captures total); current camp and gold checks and the complete opening escape pass at phone size with `fails=0`. Review outputs for these older scripts were redirected into ignored `build/art-review`, preserving their historical reference captures. Import and whitespace checks pass.

The combined review's shutdown emits a retained `scripts/save_game.gd` diagnostic (three static script/native-class instances). A minimal run of unchanged Main, `_save_now()`, freeing Main, then quit reproduces it without the gallery. Camp/gold/opening regressions shut down cleanly. This is tracked in [#100](https://github.com/jonathanvarro/Depths/issues/100), separately from the passing functional assertions; no saving code was changed in this art pass. Physical iPhone, iOS export/performance and touch-device testing remain outstanding.

Remaining #96 queue includes held lantern, status/intention glyphs, tutorial enemy variants, camp variants, leather armour, additional room props and sound. The shield/padded-coat icons are exported but their game rules are still pending #93.
