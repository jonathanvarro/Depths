# Gold and recoverable valuables · v1

**Expansion:** [eight additional valuables](treasure-extra-art.md) brings
the combined catalog to 22 visual IDs, preserving every original path.
This guide documents the first fourteen and their world props.

Artwork for [#90](https://github.com/jonathanvarro/Depths/issues/90), supporting
[gold, treasure and the merchant #42](https://github.com/jonathanvarro/Depths/issues/42).
Rough recovered valuables fit the cave's worn iron, leather, cloth and timber.
Gold is muted ochre; silver is tarnished. Gems have broad coloured planes
with clear silhouettes, without magical glow or glitter.

## Asset map

All inventory/event icons use `res://art/items/treasure-v1/<id>.png`.
The [catalog](../art/items/treasure-v1/catalog.json) supplies labels, categories,
64px icon paths, 128px illustrations and available world scenes/states.

| Visual ID | Drawing | Intended visual use |
| --- | --- | --- |
| coins-small | A few irregular hammered gold coins | Small loose find or currency indicator |
| coins-heap | Broad heap with uneven short stacks | Larger loose find |
| coin-purse | Small worn leather purse with coin edges | Compact carried purse/cache |
| coin-sack | Heavy tied cloth sack with spilled coins | Larger hoard/cache |
| chest-closed | Familiar closed timber/iron chest | Unopened container |
| chest-full | Same open chest with coins and stones | Treasure remains |
| chest-empty | Same open chest without contents | Container emptied |
| gold-signet-ring | Thick worn gold band with flattened seal | Recoverable jewelry |
| amber-pendant | Amber teardrop in a silver rim/chain | Recoverable jewelry |
| silver-brooch | Bent silver leaf-shaped cloak pin | Recoverable jewelry |
| garnet | Squat oval dark red cut gem | Loose valuable |
| emerald | Rectangular stepped green gem | Loose valuable |
| amethyst | Small rough violet crystal cluster | Loose valuable |
| silver-goblet | Dented plain silver cup/stem/foot | Recovered household treasure |

The small/large drawings are **visual quantity cues, not gold thresholds**.
Use the actual amount in text. Illustrated coin counts, gem colours or
full chests do not promise exact loot. No prices, rarity, drop rates,
selling rules, equipment effects or new starting stock are assigned here.
The jewelry is valuable artwork, not newly implemented wearable gear.
Chest icons are for containers/events; they do not imply a carryable chest.

## Runtime contract and integration

Icons are **64 × 64 RGBA**, centred with at least 4px clear margins; use
nearest filtering. They remain readable at 40px, which is included in
the review. The associated **128 × 128** illustration has a grounded
origin/pivot `(64,120)` and transparent margins. Do not use a centred,
independently fitted 64px icon to switch a world chest's state.

Individual drawings have at most **32 visible RGB colours**, except the
treasure-filled chest (at most **48**) to retain gold/gem colours alongside
the original wood/iron palette, reserving eight gold, four red and four
green colours for the contents. Alpha is a clean binary cutout. Imports
are lossless with mipmaps disabled. Local material shading remains in
the drawing; no emissive halo or free light is added.

For #42, choose catalog IDs in the actual currency/treasure model and
assign their `icon` paths. Keep values and inventory ownership in that
model. No SupplyItem/Equipment definitions or room events are added by
this art task: valuables need their own integration rather than being
mistaken for restorative supplies.

Four ready-to-instance `Node3D` scenes live in `art/props/treasure-v1`:
`coins-small.tscn`, `coins-heap.tscn`, `coin-purse.tscn`, `coin-sack.tscn`.
Place each root at the floor centre. Each has one lit, nearest-filtered,
Y-billboard cutout Sprite3D and no collision or pickup behaviour. Pixel
sizes give the visible illustrations approximate extents of 0.33m, 0.50m,
0.45m and 0.65m respectively; these are placement guides, not carry weights.
Scene illumination controls their brightness. Other 128px illustrations
are available for event detail; world placement/scale is not assigned to them.

`res://art/props/treasure-v1/chest.tscn` uses the **existing chest script**
and exact existing closed/empty textures. Call `set_state(&"closed")`,
`set_state(&"open")` (treasure remains), `set_state(&"empty")`.
The new `chest-full.png` supplies only the open treasure state; the tutorial's
open supply chest remains unchanged. SpriteFrames has one static drawing
per state, not a hinge animation. The 128px canvas, `(64,120)` pivot,
0.009375 pixel size and 0.525 child Y match the tutorial chest.

Use the room model to decide remaining treasure and when to remove a
pickup or change state. No light, collider, currency counter or loot
generation is attached to these art scenes. A generic heap inside the
chest does not track individual items as they are removed.

## Review, provenance and validation

[Dark overview](../art/concepts/treasure-v1/overview-dark.png),
[light overview](../art/concepts/treasure-v1/overview-light.png),
[64px/40px comparison with existing supplies](../art/concepts/treasure-v1/inventory-sizes.png)
and [chest state review](../art/concepts/treasure-v1/chest-states.gif).

Twelve unmodified **built-in image_gen.imagegen** outputs and their
[exact prompts/reference roles](../art/source/treasure-v1/generation-manifest.json)
are retained in `art/source/treasure-v1`. Eleven item masters were generated
separately using the approved rough knife and 64px oil flask as style
references. The treasure-filled chest edits the existing open supply
chest master, preserving its external construction. Two closed/empty
states are reused directly rather than regenerating the same box.

`tools/art/build_treasure_art.py` (Python/Pillow) rebuilds the icons,
illustrations, four pickup scenes, catalog and review boards. It uses
alpha bounds, nearest resampling, palette reduction without dithering
and a measured lower-box fit for the chest. No procedural replacement
drawings are substituted for the generated masters. Sources and existing
assets are never overwritten by the exporter.

[Asset validation](../art/concepts/treasure-v1/asset-validation.json) records
canvases, alpha, palettes, contact/registration and SHA-256 hashes.
[Godot validation](../art/concepts/treasure-v1/godot-validation.json) records
resource checks, real 64px/40px UI renders, floor pivots, static state swaps,
reuse of the exact old chest textures and bright/dim cave captures at
1280 × 720 and 1278 × 590: **213 passing checks and 20 captures**, with
Godot 4.7.2 Mobile/D3D12 on Windows. The final native icons, palette-corrected
chest and desktop/phone cave views were visually reviewed.
[World pickups](../art/concepts/treasure-v1/pickups-desktop.png) ·
[Treasure chest](../art/concepts/treasure-v1/chest-open-desktop.png) ·
[Dim phone view](../art/concepts/treasure-v1/chest-open-phone-dim.png).
Run `tools/art/check_treasure_art.gd` in Godot;
use `-- --capture` without headless mode to save the review images.

The 26 new textures use **992 KiB uncompressed RGBA**, before engine
overhead, excluding the two already-existing chest textures. Physical
iPhone performance and actual currency/room/event integration remain
checks for their implementation tasks.
