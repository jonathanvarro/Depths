# Additional valuables · eight-item expansion

Artwork for [#91](https://github.com/jonathanvarro/Depths/issues/91), extending
the [first treasure set](treasure-art.md) for [economy #42](https://github.com/jonathanvarro/Depths/issues/42).
Eight recovered objects in the same restrained worn pixel style.

| Visual ID | Drawing | Visual distinction |
| --- | --- | --- |
| gold-nuggets | Group of irregular raw gold lumps with mineral inclusions | Knobbly natural shapes, separate from minted coins |
| silver-ingot | Tarnished cast silver bar with sloping sides | Solid elongated trapezoid |
| pearl-necklace | Complete cream/grey pearl loop with a silver clasp | Open centre and visible bead rhythm |
| silver-locket | Closed oval silver case with bail, hinge and lid seam | Personal keepsake, no chain or exposed contents |
| military-medal | Worn bronze disc on a short faded crimson ribbon | Round medallion plus rectangular cloth/pin silhouette |
| small-reliquary | Closed wood/brass casket with a low gabled lid | Small architectural case, distinct from the broad supply chest |
| fine-cloth | Folded indigo cloth with a muted gold border and plain tie | Square textile bundle, distinct from dressings |
| spice-pouch | Flat oiled-cloth packet with crossed cord and an intact wax seal | Sealed rectangular trade parcel, distinct from coin bags |

The medal's abstract badge and the reliquary's ornament are visual motifs,
not named military units, religious factions, quest requirements or magic
effects. The locket stays shut. No values, rarity, drop rules, sale rules,
wearable effects or starting stock are assigned by this art delivery.
Fine cloth/spices are valuable illustrations, not new crafting/food rules.

## Catalog and files for Claude

The combined [catalog](../art/items/treasure-extra-v1/catalog.json) contains
**22 entries**: the original fourteen unchanged, plus these eight.
`new_ids` lists only this expansion. Existing paths still point to
`treasure-v1` and the reused tutorial chest states. The first catalog
remains available for code already using it.

New icons: `res://art/items/treasure-extra-v1/<id>.png`.
New illustrations: `res://art/props/treasure-extra-v1/<id>.png`.
Assign the catalog's `icon` path to the actual treasure item definition
in #42 and retain game-data values. No economy resources or gameplay code
are changed here. An illustrated nugget count does not determine currency.

All new icons are **64 × 64 RGBA**, centred with at least 4px clear
margins; nearest display is intended. Their **128 × 128** illustrations
share the first set's `(64,120)` floor/contact convention and retain
the complete canvas. Every drawing has at most **32 visible RGB colours**
with binary alpha, lossless imports and no mipmaps. Illustrations are
provided for detail views/future placements; no world scale, pickup scene,
collision or interaction is assigned to these eight.

The new sixteen textures total **640 KiB uncompressed RGBA**, excluding
engine overhead and the first set. Existing art is referenced, not copied
or regenerated. Preserve pearl/chain gaps when making later exports.

## Review and sources

[Dark overview](../art/concepts/treasure-extra-v1/overview-dark.png) ·
[Light overview](../art/concepts/treasure-extra-v1/overview-light.png) ·
[64px/40px alongside existing treasure](../art/concepts/treasure-extra-v1/inventory-sizes.png) ·
[All 22 visual IDs](../art/concepts/treasure-extra-v1/all-treasure.png).

Eight unmodified **built-in image_gen.imagegen** masters and
[exact prompts/reference roles](../art/source/treasure-extra-v1/generation-manifest.json)
are retained in `art/source/treasure-extra-v1`. Existing silver goblet,
signet ring and coin purse are style references only. Each new object
was generated separately with true transparency requested.

Rebuild with `tools/art/build_treasure_extra_art.py` and Python/Pillow.
It reuses the first exporter functions without running or modifying that
exporter: alpha bounds, nearest fitting, nondithered palette reduction,
64px icon centring and 128px contact registration. Generated drawings are
not replaced by procedural illustrations. Source files remain untouched.

[Asset validation](../art/concepts/treasure-extra-v1/asset-validation.json)
records bounds, palette counts, source/reference hashes and memory.
[Godot validation](../art/concepts/treasure-extra-v1/godot-validation.json)
records combined-catalog checks, actual resource imports and native
64px/40px renders at 1280 × 720 and 1278 × 590 on dark/light backgrounds.
Godot 4.7.2 Mobile/D3D12 passed **131 checks with four captures**; native
icons and dark/light desktop/phone renders were visually reviewed.
Run `tools/art/check_treasure_extra_art.gd` with `-- --capture` in graphical
Godot for the saved renders. Physical iPhone and actual loot/merchant
assignment remain checks for #42/integration.
