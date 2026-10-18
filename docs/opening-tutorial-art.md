# Opening tutorial art set (#70)

The owner requested a broken knife, damaged armour and matching chest states for the opening tutorial. The set follows the rough wood/iron/cloth of the existing items and the restrained cave sprites. [Overview](../art/concepts/opening-tutorial-v1/overview.png) · [Original/damaged gear comparison at enlarged and 40px sizes](../art/concepts/opening-tutorial-v1/gear-comparison.png).

## Inventory assets

| Asset | Runtime path | Status |
| --- | --- | --- |
| Broken knife | `res://art/items/opening-tutorial-v1/broken-knife.png` | Connected to `data/gear/broken_knife.tres`; replaces its intact-knife stand-in |
| Damaged armour | `res://art/items/opening-tutorial-v1/damaged-armour.png` | Ready for the equipment/hero interface; no armour definition or mechanics added |

Both are 64×64 RGBA with real transparent margins and at most 24 visible colours each. Nearest filtering is intended when enlarged. The knife preserves the approved two-rivet wooden handle and rusty iron, with the tip removed and a broad fractured edge. The armour is a torn version of the existing basic **padded coat**, with exposed stuffing and a ragged hem. It is an inventory illustration, **not a registered portrait clothing layer**. Choosing it does not establish armour stats, durability, repair or starting stock.

The original approved knife and padded coat remain unchanged. The knife's existing damage/accuracy values are unchanged too; only its icon path changes.

## Chest state contract

`res://art/props/tutorial-chest-v1/scene.tscn` is an upright, camera-facing Node3D world prop. Place the root at the cell's floor centre. It has a lit AnimatedSprite3D named `Sprite`, and accepts `set_state(&"closed")`, `set_state(&"open")` or `set_state(&"empty")`. Equivalent ready-to-instance scenes are [closed.tscn](../art/props/tutorial-chest-v1/closed.tscn), [open.tscn](../art/props/tutorial-chest-v1/open.tscn) and [empty.tscn](../art/props/tutorial-chest-v1/empty.tscn).

| State | Meaning | Texture |
| --- | --- | --- |
| `closed` | Lid down; contents not revealed | `closed.png` |
| `open` | Lid up; supplies remain | `open.png` |
| `empty` | Lid up; no supplies remain | `empty.png` |

Each texture is **128×128**, untrimmed, with one shared palette of at most 32 visible colours. Floor pivot is `(64,120)`; all three have the same scale and the same 103px-wide lower contact region. Runtime `pixel_size` is `0.009375` and child Y is `0.525`, so the complete canvas spans 1.2 world units, with the visible box about 1 metre across. The same shadow/light response, nearest filtering and binary cutout alpha apply to all states. Do not independently resize/trim a state or change sprite offsets when switching it.

The SpriteFrames resource contains **three static drawings**, not a hinge-opening animation. Changing state never moves the scene. Keep the actual room/chest model authoritative for contents, interactions, collision, persistence and transfers. This prop has no collider, lamp, glow, loot generation or game-state logic. It uses existing dungeon illumination.

The open illustration contains an amber bottle and folded dressing, matching the two kinds in Claude's current `OPENING_CHEST`. It communicates supplies remaining; it does not dynamically depict exact item quantities or partial removal. The chest window remains the source of truth. For other loot combinations, review the illustration or use an appropriate generic open state.

**Handoff after #69:** Claude's `Main._add_chest(cell, opened)` builds a placeholder box/lid. Its `opened` flag currently means the chest was **emptied**. Map that existing boolean to `empty` when true and `closed` when false; use `open` explicitly while supplies remain if that world state is shown. The art task preserves the Main/chest-window implementation and does not alter its lifecycle or collision. #46 can reuse the scenes for other room contents later. Do not add free light to make chests visible without reviewing that gameplay choice.

## Generation and validation

Made with the built-in image-generation tool: [exact prompts/reference roles](../art/source/opening-tutorial-v1/generation-manifest.json). Five masters are preserved there. Knife/armour edits use the approved item references; open edits the closed chest and empty edits the open chest. [Exporter](../tools/art/build_opening_tutorial_art.py) crops/normalizes gear icons, registers chest lower boxes with one common scale, thresholds alpha and applies palettes without dithering. It does not repaint the generated drawings. Palette selection gives the small amber bottle enough weight to preserve its colour against the larger wooden surfaces.

[Asset checks](../art/concepts/opening-tutorial-v1/asset-validation.json) cover all five canvases, alpha/margins, colour limits/shared chest palette, floor contact, lower-box registration and source/reference/export hashes. [Godot checks](../art/concepts/opening-tutorial-v1/godot-validation.json): **51 passing assertions**, including item reference/unchanged values, scene selection, state swaps without movement, texture/material/floor contracts, twelve captures and dim-light response. Godot 4.7.2's Mobile renderer on Windows/D3D12 was used at 1280×720 and 1278×590.

[Open chest on phone](../art/concepts/opening-tutorial-v1/open-phone.png) · [Empty chest in dim light](../art/concepts/opening-tutorial-v1/empty-dim-desktop.png) · [Dark background](../art/concepts/opening-tutorial-v1/chest-dark.png) · [Light background](../art/concepts/opening-tutorial-v1/chest-light.png). Captures were visually inspected. The cave check uses the real Cave theme/LevelBuilder in an isolated room, not Main or the unfinished tutorial. Physical iPhone performance and actual placement/input flow remain integration checks.

All five runtime textures total **229,376 uncompressed RGBA bytes (224 KiB)** before engine overhead, with lossless imports and mipmaps disabled. Source/review folders have `.gdignore`. Rebuild with Python/Pillow: `python tools/art/build_opening_tutorial_art.py`. After importing in Godot, run `Godot --headless --path . --script res://tools/art/check_opening_tutorial_art.gd`; omit `--headless` and append `-- --capture` to save all cave views. `--icons-only` on the exporter updates only the two gear exports and their comparison.
