# Backlog #96: cave and interface art

Delivered 2026-10-18. This visual pass follows the existing small pixel-art library: rough materials, restrained detail, neutral material colours, transparent cutouts, nearest filtering and lossless imports. Generated originals are preserved separately from runtime exports.

## Connected in the game

| Art | Location and behaviour |
| --- | --- |
| Party conditions | `art/ui/backlog96-v1/status/`: eight 32px PNGs, shown at 14px by `scripts/party_card.gd`. Bleeding, wounded, healing, down, unconscious, deep wound, limp and a reusable dressed band. Existing conditions still determine what appears. |
| Enemy intentions | `art/ui/backlog96-v1/intent/`: fifteen 32px PNGs, shown at up to 18px on combat tags. Covers every current `CombatState.Intent`, including heavy blow and the fortress intentions. Text remains alongside the glyph. `glyphs.gd` holds the enum-order lookup; update it if that enum changes. |
| Tutorial enemies | `art/enemies/tutorial-v1/starved-rat/` and `small-spider/`: distinct bony/mangy rat and smaller pale spider. Each has idle, attack and hurt PNGs, frames and a drop-in scene. The two existing enemy resources now reference these scenes; their numbers are unchanged. |
| Contract and recovery | `art/camp/cave-camp-variants-v1/`: notice on the cave post and a patient in the nurse's cot. `CampScreen` selects them from the actual active contract and recovery state, restoring the original art afterwards. |
| Nine room events | `art/props/cave-events-v1/catalog.json` maps all nine event resources to their scenes. Includes cairn, old workings, idol niche, dry alcove, tripwire and hollow floor; reuses the existing abandoned pack, still pool and cold campsite. Strongbox already has a chest prop. |
| Searched containers | The abandoned-pack adapter calls its existing `set_searched`; the cairn switches to an open, empty bundle. Both expose the existing `state = "empty"` protocol. Other resolved events retain the game's existing removal behaviour. |
| Coin flip | `art/ui/coin-v1/`: 128px crown/heads, skull/tails and edge view. `scripts/coin_flip.gd` now draws the authored faces through its existing squash/spin animation and outcome logic. The edge view is available for a later animation refinement. |

Trap visibility belongs to the game: the current #95 implementation reveals trap props to a party with `keen_eyes`. The artwork does not reveal them to other parties or change detection rules.

## Ready for Claude to place

- **Held lantern:** `art/props/lantern-v1/held.tscn`, a 128×256 foreground scene matching the held torch canvas. Reuses the existing six-frame campfire flame behind the lantern's ribs. `set_state()` accepts `steady`, `dim`, `nearly-out`, `unlit`; `apply_supplies(supplies)` reads the real source/oil and changes presentation only. Nearly out is at 10% capacity; dim follows the existing light band. Add it beside the held torch in the navigation HUD, refresh it when supplies change and fit both around the touch pad and safe area. Neither held scene is instantiated by Main yet. Review captures use temporary placement only. This scene spends no fuel or time and creates no world light.
- **Opening daylight exit:** `art/features/daylight-exit-v1/scene.tscn`, 128×256 rocky crack with sky and a pale path. Place at the opening's exit cell only, using the existing opening dressing/light. It is not wired into Main. Do not replace the theme's general way-up scene, which is also used underground. The sprite is unshaded to retain the visible exterior.
- **Armour:** `art/items/armour-v1/catalog.json` lists three new 64px leather icons and the existing matching wooden shield/padded coat exports. Ordinary, boiled and studded leather differ in construction rather than luxury. Item definitions, trade-offs, shops and breakage rules remain with #93; damaged variants await a decision that armour can break.
- **Map materials:** `art/ui/map-v1/parchment.png` is blank rough 512px paper, with `paper.tres` providing 40px nine-patch margins and `quiet-centre.png` for repeated interiors. Eleven 32px charcoal map markers live in `art/ui/backlog96-v1/map/`. The review image is a material/marker legend, not a proposed dungeon layout. #50 still needs the explored-cell renderer, imperfect ink strokes, touch behaviour and legend in the actual map UI.

## Export contracts

- Tutorial enemies: 128×128 per pose, shared 32-colour palette per family, common scale and horizontal registration, floor contact at pixel 120. Root at floor; Sprite's vertical offset is `56 * pixel_size`. Attack/hurt remain single poses, matching the current combat calls.
- Upright room cutouts: 128×128, up to 32 colours, floor pivot `(64,120)`, shaded Y billboards. Pool and hollow floor lie flat; hollow floor uses centre `(64,64)`, a 1.4m span and 0.015m floor clearance. The initial frontal hollow-floor source was replaced by the preserved top-down correction.
- Armour: 64×64, maximum 56px occupied span, at least 4px padding. Coin faces: 128×128, centred, maximum 116px disk, shared palette. Raster exports use binary cutout alpha; original generated alpha is retained in the source masters.
- Camp: exactly 256×192 with the old origin and site placement. Only `(59,85)-(93,130)` changes for the notice, and `(86,106)-(138,150)` for the cot. Export asserts that every byte outside each rectangle matches the original. Registered patch PNGs are also supplied.
- Glyphs: original editable SVG drawings in `art/source/backlog96-v1/glyphs/`, rasterized by Godot at native 32px. These UI drawings retain antialiased edge alpha. Runtime PNGs avoid importing a duplicate vector library.

## Sources, review and checks

Built-in ImageGen authored the raster illustrations. All sixteen initial requests and two hollow-floor corrections, exact prompts, reference paths and preserved filenames are in [`generation-manifest.json`](../art/source/backlog96-v1/generation-manifest.json). Reference boards, unused correction masters and all originals remain in that ignored-by-Godot source directory. No paid API fallback was used. Tiny glyphs are original vector drawings rather than generated illustrations.

Rebuild with Python/Pillow using `tools/art/build_backlog96_art.py --wire`; `--wire` updates only event prop references. Regenerate SVGs with `tools/art/build_backlog_glyphs.py`, rasterize them with Godot's `tools/art/rasterize_backlog_glyphs.gd`, then run `tools/art/review_backlog96.py` for the contact sheets. `tools/art/check_backlog96.gd` exercises the actual scenes and UI.

Godot 4.7.2 import succeeds. The art/state/renderer review passes **185 checks, zero failures**, producing **50 captures** at 1280×720 and 1278×590 with simulated phone safe areas, including camp/combat at the 1.3 Larger setting. Existing opening-escape, camp and coin checks also pass with clean error logs. PNG dimensions, margins, palette limits, binary alpha, family registration and source/output hashes are recorded in `asset-validation.json`. Physical iPhone testing remains outstanding.

Review files are in [`art/concepts/backlog96-v1`](../art/concepts/backlog96-v1): dark/light native and small-size contact sheets, actual game captures and `godot-validation.json`. Start with [room props](../art/concepts/backlog96-v1/room-props-dark.png), [tutorial poses](../art/concepts/backlog96-v1/tutorial-poses-dark.png), [camp](../art/concepts/backlog96-v1/camp-occupied-phone-larger.png), [heavy blow](../art/concepts/backlog96-v1/combat-heavy-phone-larger.png) and [map material](../art/concepts/backlog96-v1/map-material-and-markers.png). Lantern/daylight screenshots are isolated placement previews, not live Main integration.

Real sound remains unfinished in #54/#96, including the coin flip: the available image tool does not author audio, and existing placeholder sound was left intact. Later-site merchant portraits remain gated on a second site. Fortress enemy/environment art is tracked separately in #99. Concurrent starting-hero, equipment and research changes are excluded from this pass.
