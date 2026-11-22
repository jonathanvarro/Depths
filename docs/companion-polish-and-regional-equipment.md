# Companion seat fit and regional equipment finish

Owner requested companion polish and regional equipment, then merge
(2026-11-22). Work stays on an isolated checkout; concurrent game-design
changes in the main working directory are not included.

## Companion garment polish · #218 / #220

Current private review:
`E:/GitHub/Depths/build/local-companion-polish-v1/review/inspector.html`.
The parent `START_REVIEW.cmd` opens the interactive outfit/pose reviewer when
the owner chooses. No automated check launches on the active desktop.

Both padded-jacket fits now have a shorter cutaway hem with smoothly
compressed panel rings and revised low-panel skin weights. The back blends
into the lower spine rather than being dragged only by the pelvis/thigh.
The fixed 43 cm stool, its once-chosen horizontal anchor, the floor, source
rigs and source animation curves are unchanged. The front keeps a lower hem
than the back; no animation-driven cloth correction or floor shift is used.

The new editable copies are in `editable/`; self-contained wardrobe GLBs and
jacket-only GLBs are in `assets/`. Original v2 masters and earlier assemblies
remain untouched. Body geometry, UVs, actual bone weights, skeleton hierarchy,
rest matrices, source Action keys/handles/slots and the original tunic,
trousers and boots are independently checked against their source. Only the
reversible upper-body visibility tag is revised around the new waist cut so
removing trousers does not leave a masked gap. Other coverage tags remain
unchanged, and removing all garments restores the full source body.

The source Dying Action/slot remains active at master save, as required by the
existing wardrobe exporter. It is not replaced by the last inspected chair
clip. Exports retain each body's original six motions and the existing
horizontal-only chair-sequence alignment. Private model/animation media stay
local and ignored; the public game companion art/bindings are not replaced.

Validation:

- **1,221 source-frame seat samples** (692 female, 529 male): every integer
  source frame of sit-down, hold and stand-up. Evaluated garment triangles are
  clipped against the fixed seat volume; no intersections remain. The older
  fits reached 131 / 89 triangle intersections in the sampled comparison.
  This is a concrete stool-volume check, separate from the earlier unreliable
  hand/leg inside tests. Front/side/back actual renders remain the visual check.
- **972** independent Blender export/reimport checks and **5,128** reopened
  lineage/component checks pass, including separate jacket-only exports.
- **6,488** native Mobile wardrobe checks and **4,082** headless checks pass:
  all clothing combinations, outfit swaps, actual input, deformation, portrait
  cards and desktop/phone shapes.
- **123** focused native checks pass with fixed stools, per-body phase timings,
  exact paused bones across outfit swaps and jacket-only coverage captures.
  Review images include both bodies' own early/late hold and rise samples.

These are garment/contact improvements, not a replacement animation library.
The previously documented source hand/foot/death-contact limits and decisions
about loop/in-place derivatives remain under #218. Playback still stops at
the true source endpoint; no source walk is silently looped or normalized.
Owner visual acceptance and physical iPhone review remain separate.

Reproduce with Blender 5.2 in background, `--factory-startup
--disable-autoexec --python-exit-code 1`, then:

1. `tools/padded_jacket/polish_contacts.py -- --workspace E:/GitHub/Depths`
2. `tools/padded_jacket/export_jacket.py -- --workspace E:/GitHub/Depths
   --review-folder local-companion-polish-v1`
3. `tools/padded_jacket/validate_jacket.py` with the same arguments.
4. Python `tools/padded_jacket/package_contacts.py --workspace E:/GitHub/Depths`.
   Import the private Godot project headlessly. Use the private-desktop launcher
   for its `check.gd` and `check_contacts.gd`; the former also runs headlessly.
   Rerun the package step after captures to refresh the gallery.

The full suite explicitly starts its neutral-height check in neutral, because
the stool reviewer deliberately opens seated. Its metric-height assertions
remain unchanged. Blender masters are excluded from Godot import, and the
standalone review disables Blender import just as the main project does.

## Regional production icons · #194 / #195

[Current review](../art/concepts/regional-equipment-v2/inspector.html) contains
the four old/new comparisons and the disposition of all 22 original concepts.

| Live item | Production adaptation |
|---|---|
| Quilted coat | Sleeveless dun quilting, bound armholes, uneven narrow channels, old patch |
| Studded jerkin | Short asymmetric hide vest, sparse hammered studs, oxblood lining |
| Goblin scale shirt | Short shoulder caps and hip hem, mismatched dished scales and worn backing |
| Goblin round shield | Round planked body, segmented iron rim, off-centre boss and old repair |

The four masters were edited with built-in ImageGen from the retained regional
drawings. Exact prompts, edit roles and input/output hashes are in
`art/source/regional-equipment-v2/generation.json`. Outputs are in
`art/items/regional-equipment-v2`: 128px plus directly exported compact64,
hard alpha, at least 8/4px padding, at most 64 visible colours. Original sources
and icons remain preserved.

Only the four base icon fields and the authored `padded_coat.tres` texture URI
change. The base IDs, descriptions, slots, stats, prices, regional pools,
quality/mastery/modifier rules and RNG are identical. Old generated gear
restores to the new pictures. The newer sling/bow/wand/staff production art
is retained; unused mine plate armour, short cape, heavy mace and tall shield
remain alternative concepts rather than becoming unapproved new item bases.

All four items pass **98 native checks**, including 24 actual Pack/loot/merchant
captures at 1278×590 and 852×393, all five quality rolls, saved instances and
inspection without spending time or altering equipment. Existing gear-model,
gear and save regressions report `fails=0`; gear/save fixtures retain their
pre-existing resource cleanup messages after assertions. Native runs use
private desktops and preserve foreground focus. Physical iPhone review remains.

Rebuild with `tools/art/build_regional_equipment_v2.py`; run
`res://tools/art/check_regional_equipment_v2.gd` with the absolute capture folder
after `--`. No further design or gameplay migration is implied by this art pass.
