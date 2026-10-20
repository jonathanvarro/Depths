# Cave dressing and ambient art handoff

2026-10-20 · #128 and #129, refs #96/#117/#126.

The first eleven wall/ceiling dressing categories, all nine floor categories,
and all eight ambient-effect categories have an asset library. These are
**ready for Claude's placement and state integration**. No live floor themes,
events, saves, collision rules, party light or nerves were changed by this pack.

## Review

- `art/concepts/cave-dressing-v1/dressing-overview.png`: all 32 native cutouts.
- `art/concepts/cave-dressing-v1/inspector.html`: play, pause, frame stepping,
  strength and native/2×/4× views. Includes the static dressing. It uses a fixed
  room image, not a live light/nerves simulation.
- That folder also holds actual Godot desktop and 1278×590 phone-shaped views
  of old workings, damp cave, goblin wall, floor decals and close wall fixtures.
  They are isolated art fixtures, not a proposed density or seeded placement.

## Dressing catalogue

`art/dressing/cave-v1/catalog.json` gives every texture, scene, mount, pivot,
pixel size, physical size, proposed floor range, opacity and source hash.

| Category | Asset IDs |
|---|---|
| Hanging limestone | `stalactite-single`, `stalactite-pair`, `stalactite-cluster` |
| Standing limestone | `stalagmite-stub`, `stalagmite-tall`, `stalagmite-broken` |
| Wall age and damp | `flowstone`, `cracks-rubble` |
| Webs | `corner-web`, `web-strand` |
| Mining supports | `mine-support`, `mine-post-left`, `mine-post-right`, `mine-crossbeam` |
| Wall fixtures | `burnt-sconce`, `goblin-torch-base`, plus `goblin-torch-lit.tscn` |
| Survey marks | `chalk-arrow`, `chalk-cross`, `chalk-tally` |
| Goblin occupation | `goblin-daubs`, `hanging-trophies` |
| F1–F4 | `puddle-small`, `puddle-wide`, `floor-gravel`, `mine-rails`, `tracks-drag` |
| F5–F9 | `pale-mushrooms`, `rat-nest`, `floor-crack`, `goblin-litter`, `old-scorch` |
| A7 neutral base | `wall-fungus` |

All cutouts are transparent 128×128 with at most 64 RGB colours. Chalk retains
its native 64px drawing on that canvas. World scale follows the current 2m cell
and 2.4m wall. Scenes have no collisions, interaction areas or loot hooks.

Wall pieces face local +Z, with the root at the back centre; rotate that root
to face into the passage. Ceiling roots are at the attachment/top edge, standing
pieces at the foot, floor decals at their centre with a 0.012m surface offset.
The corner web has its root at its retained upper-left attachment. The complete
support is a floor-origin structural frame. `cracks-rubble` has a suggested
mount height of 0.5m so its loose stones meet the floor.

Ceiling formations and ordinary floor-edge cutouts use Y billboarding. Wall
marks, floor decals and structural timbers stay fixed. The three support
components retain their shared canvas and pixel size; `family_origin_offset`
reassembles them exactly into the full support. The full frame is also provided
for an easy first integration. There is no door or opening interaction.

Puddles are shallow low-opacity films without a raised bowl edge. The floor
crack is narrow; scorch marks have no crossed firewood or rest-site props.
Use their supplied opacity values. No object changes a tile's traversability.

The lit goblin torch is the unlit base plus **four registered flame frames**,
one combined smoke/ember sprite, and a small shadowless local light. Its glow
is **mood only**, as decided by the owner. No carried-light or strain methods
are called. Base anchor (64,14) is the flame seat. Use `goblin-torch-base.tscn`
for the unlit state; the separate dead mining sconce remains cold.

## Ambient catalogue

`art/effects/ambient-v1/catalog.json` gives sheet dimensions, columns, frame
size/count, speed, blend and placement notes. Each animation has a ready
`SpriteFrames` resource with animation **`loop`**. Filtering is nearest.

| Brief | Files and use |
|---|---|
| A1 fog | `fog-strip.png` is 256×64 and wraps exactly in X; three 128×64 room patches. `fog-scroll.gdshader` scrolls the strip at 0.01 cycles/s. Plain alpha, low opacity. |
| A2 eyes | `eyes-rat`, `eyes-cluster`, `eyes-unknown`: 32×16, 12 frames at 8fps. Fade/hold/half-close/fully hidden/reopen/fade. Additive glints; play once then remove. |
| A3 darkness | `darkness`: 640×360, 8 frames at 6fps, four columns. One strong alpha loop; fade to 0.2/0.5/1 for hint/medium/strong. The central rectangle (192,108)–(448,252) is fully transparent in every frame. Place below the HUD. |
| A4 dust | `dust`: 64×64, 8 frames at 8fps; a handful of drifting specks, plain alpha. |
| A5 drips | `drip`: 64×128, 8 frames at 8fps; falling drop and a small projected splash/ring. First and last frames are empty. Plain alpha. |
| A6 smoke/embers | `smoke` 64×128 and additive `embers` 32×64; also `torch-smoke-embers` 64×128, combined alpha for one extra sprite. All eight frames at 8fps. The lit torch example uses the combined version. |
| A7 fungus | `fungus-pulse`: 128×128, 8 frames at 6fps, an additive emission mask registered to the neutral `wall-fungus.png`. It adds appearance, not party light. |
| A8 shadow | `shadow`: 64×64, 8 frames at 8fps; an indistinct passing shape with empty endpoints. Plain alpha. |

Eyes are **pure atmosphere**, unrelated to encounter cells or safety, per the
owner. They belong beyond carried light, in Dim/Out light or Shaken nerves,
and vanish if that light reaches them. Shadows are rarer and Dim/Out only.
Dust belongs in good light. The darkness controller should ease its strength
with carried light/nerves and respect reduced-motion/screen-flash settings.
Those rules remain for Claude to wire; the inspector does not simulate them.

This pack uses small sheets rather than particle swarms. All 32 dressing
textures and 16 effect textures together decode to **10.852 MiB RGBA**, before
engine overhead, and the largest atlas dimension is 2560px. That is a texture
budget, not a physical-iPhone performance measurement.

## Provenance and rebuilding

`art/source/cave-dressing-v1/generation.json` contains the **27 built-in
ImageGen calls**, exact prompts, input references, original output paths and
hashes. Masters were copied byte-for-byte. Two initial decal candidates are
retained; the exporter explicitly selects the revised shallow puddle and
stick-free scorch stain. The corner web reuses the existing expedition source.
Chalk is native SVG, and the fog, glints, darkness, motes, drips, smoke, embers,
flame and glow mask are authored procedural pixel effects in GDScript. No
external image-generation API was used.

1. Run `tools/art/build_ambient_atlases.gd` through headless Godot to raster the
   native chalk sources and effect sheets.
2. Run `tools/art/build_cave_dressing.py` to reduce/quantize the image masters,
   register mounts/components, and rebuild the dressing catalogue/overview.
3. Run the ambient builder again if the neutral fungus source changed.
4. Import with Godot 4.7.2, then run `tools/art/check_cave_dressing.gd` with the
   real Mobile renderer for actual mounted-room views.
5. Run `tools/art/review_cave_dressing.py` for source/export/alpha/palette/wrap/
   component checks and a refreshed inspector, then `check_cave_inspector.cjs`
   for desktop/phone pause/step/loop/layout checks.

The source and review folders have `.gdignore` files. The assets do not alter
Claude's concurrent combat-stage work. Physical iPhone review, live sparse
seeded placement, state controllers and the remaining second-batch/later-layer
ideas in the briefs remain separate work.
