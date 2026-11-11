# Stairs, cave transitions, passage blockers and regional materials

Owner-selected batches completed in order for #250 and #225, 2026-11-09.
Delivery branch is `codex/transitions-blockers-regional-3d`.

Local gallery is `E:/GitHub/Depths/build/local-transitions-regional-v1/inspector.html`.
`START_REVIEW.cmd` opens native selectors for all features/material sets, environment
or neutral lighting, three-quarter, eye-height and overhead views. Editable
separate-piece Blender masters remain in its `masters` folder. All rendered
reviews and masters stay local under build/.

These are reusable art libraries. No live theme, floor, encounter, passage,
collision, travel, arrival, story, saved-state or tactical-camera code changed.
Earlier painted feature scenes and the adopted floor-1 prop material are intact.

## Ten 3D feature scenes

Files are in `art/features/transitions-3d-v1`. Roots sit at the cell centre on
the floor, with -Z forward, matching EnvironmentTheme/LevelBuilder. A corridor
running east-west still rotates the complete feature by PI/2. Do not apply the
wall-prop +Z convention from the separate event-art families to these features.

| Scene | Form | Triangles |
| --- | --- | --- |
| stone-up | Worn stone flight, short parapets, jambs and upper throat | 1,470 |
| stone-down | Recessed stone flight and lined stairwell | 982 |
| fortress-up | Scavenged timber, crooked rails and iron repairs | 816 |
| fortress-down | Recessed timber flight and patched rails | 768 |
| cave-ledge-down | Broken lip, rough footholds and recessed shaft | 494 |
| root-climb-up | Curved roots/handholds and upper aperture cap | 1,526 |
| daylight-mouth | Rock cheeks/arch, hanging roots and fixed muted vista | See catalog |
| web-intact | Irregular radial/spiral silk strands | 1,120 |
| web-torn | Side/top fragments with a cleared centre | 196 |
| root-barrier | Dense crossed, curved roots spanning the passage | 2,212 |

catalog.json records actual exported metric bounds, hashes, triangle counts,
forward direction and descent aperture requirement. All features fit a 2m cell
and 2.4m wall envelope; recessed pieces reach about 0.94m below the floor.
These visible flights illustrate a transition, not a continuous full-storey
walkable staircase. Grid movement and the existing level prompt remain in charge.

LevelBuilder already omits its floor tile for STAIRS_DOWN. The three descending
scenes supply a complete 2m-square apron around an actual recessed well. Keep
that omission; adding a full floor plane would cover the steps. The ascent cell
retains the builder's floor. Its short flight disappears into an opaque upper
throat. No physical navigation/collision or camera climb animation is added.

Ground aprons use the scene's existing stone/fortress/cave floor material, copied
per instance and projected in world space at 2m repeat, so palette UVs cannot
collapse it to a single sampled pixel. Callers may set `ground_material` before
adding an instance to fit another theme. Never mutate the shared theme material.

The root climb's dark upper cap sits just under the normal ceiling. Cap/rim
geometry is separated into a Canopy mesh and tagged `ceiling` at ready, so the
existing overhead-view policy can hide it. Restore it when returning to eye
height. It masks the visual ceiling; travel to the next floor stays controller-owned.
The daylight mouth uses a fixed shaded rock frame, unshaded sky gradient and
shallow muted ridge/path backdrop. It has no new world light, animated glow,
billboarding, outdoor-level assignment or changed opening-escape trigger.

Use intact/torn web scenes for closed/opened passage presentation and the dense
root scene for blocked presentation. Their centre/root/scale remain registered.
The torn mesh clears its former silk centre. Cleared root blockages must continue
to follow the existing `marks["cleared"]` behavior, which leaves the way empty
rather than substituting torn web art. No scene opens, seals or resets a passage.
All features support the harmless `set_motion(bool)` interface and remain static.

## Three regional prop materials

`art/materials/regional-props-v1` contains fungal, scorched and waterlogged
StandardMaterial3D resources. Each region uses one shared 256px/32-colour atlas
plus one 64px/32-colour world-space stain/grain texture. The original KayKit
mesh bytes, UVs, scales, source record and floor-1 atlas are unchanged.

| Material | Read | Roughness / specular |
| --- | --- | --- |
| fungal | Damp olive wood, subdued moss staining | 0.96 / 0.10 |
| scorched | Smoke-darkened wood and charcoal/brown staining | 1.00 / 0.08 |
| waterlogged | Cold damp timber, silt/mineral staining | 0.82 / 0.18 |

`tools/transitions_3d/build_regions.py` follows the earlier native recolour
workflow. It tints the existing floor-1 atlas while preserving its layout and
derives region-specific world grain from existing fungal/fortress/wet-wall art.
No new bitmap painting, geometry, normal/emission map, reflection effect, light,
collision, particles or loot highlight is added. The world detail keeps the
existing 2m density. Three representative original pieces (barrel, crate, bottle)
are rendered in every material; actual imported vertex/index/UV signatures match.

```gdscript
const Skins = preload("res://art/materials/regional-props-v1/skins.gd")
var shared = Skins.material("fungal") # once for the floor's KayKit pieces
Skins.apply(piece, shared)
```

The helper loads no static material cache and changes only mesh overrides/shadow
casting, as in the existing pilot. It is for the original KayKit gradient-atlas
UV family, not the palette-point UVs of authored mine/transition props. Applying
it to the latter would select incorrect colours. Placement, region/floor choice,
density, seed/RNG and keeping props out of event/travel cells remain caller-owned.
No live dresser or theme has been expanded to another floor in this delivery.

## Sources and verification

Two suitable CC0 KayKit Dungeon Remastered originals (stone and timber stairs)
were fetched from pinned official blobs at commit
b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07. Original bytes, licence, paths, lengths,
Git blob hashes and SHA256 are in `art/third-party/kaykit-transitions-v1`.
Flights are oriented, fitted, recoloured and gently warped; added framing,
shafts, cave forms, strands and roots use authored geometry and the unchanged
mine helpers. No character mesh or animation clip is added or tested.

- 323 Godot 4.7.2 Mobile/D3D12 checks pass with a clean native error log. These
  cover actual imported bounds, budgets, UVs, floor/ceiling envelopes, static
  behavior, stair tread heights/direction, recessed centres, torn-web clearance,
  canopy hide/restore, identical regional geometry/UVs and shared materials.
- 105 actual native captures cover all features/skins in both lighting modes and
  three views, phone controls at 1278×590, 852×393 and 667×375, and six real
  LevelBuilder fixture cases at eye height and overhead. The fixture tests both
  corridor orientations and checks that the descent cell has no covering floor.
- Browser checks exercise all image combinations, three batch filters, touch
  selectors and overflow. Packaging verifies the current source/helper/builder/
  mesh/runtime/material hashes against the native capture report and confirms
  the original prop files and floor-1 atlas remain unchanged.

These are desktop renders in phone-shaped windows, not physical-iPhone performance
or live-game integration acceptance. The actual reports are beside the gallery.

## Rebuild

Run from the isolated checkout. Where accepted, use `--workspace E:/GitHub/Depths`.

1. Blender 5.2 background/factory-startup/disable-autoexec/python-exit-code 1,
   with `tools/transitions_3d/build_models.py`.
2. Python `tools/transitions_3d/build_regions.py`, then `prepare_review.py`.
3. Godot 4.7.2 `--headless --editor --path <local review> --import`.
4. Native Godot `--path <local review> --script res://check.gd --quit-after 12000`.
   Require the fresh validation report and clean error log, not only exit zero.
5. Python `tools/transitions_3d/package_review.py`.
6. Node `tools/transitions_3d/check_gallery.cjs E:/GitHub/Depths`, using bundled
   Node modules. Gallery and captures remain under build/local-transitions-regional-v1.
