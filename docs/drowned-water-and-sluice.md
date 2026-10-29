# Water surfaces and sluice wheel · #166

First delivery for the Drowned Galleries: two water surfaces and a registered
closed/open sluice. [Offline inspection](../art/concepts/drowned-water-v1/inspector.html)
includes native/96px art, 3×3 tiling, sixteen actual first-person captures and
a paused-by-default motion recording. Four built-in ImageGen masters and exact
prompts are retained separately; see [generation](../art/source/drowned-water-v1/generation.json)
and [prompts](../art/source/drowned-water-v1/prompts.json).

**Ready for Claude's hookup.** This delivery is an asset library, not a live
theme/placement change. Current water costs, flooded cells, draining, stairs,
quests, saves and existing art remain unchanged. Wet walls, dressing, keeper
and monster artwork remain separate work under #166/#168.

## Surfaces

| Asset | Read | Material / scene |
| --- | --- | --- |
| Shallow | Broad ripples over submerged grey-brown cave stone and grit | `art/textures/drowned-water-v1/shallow.tres` / `shallow.tscn` |
| Deep | Opaque black-green water; no visible bottom | `art/textures/drowned-water-v1/deep.tres` / `deep.tscn` |

Both are opaque **128×128**, at most **32 colours** each, nearest-sampled and
repeatable. Export resizes the original complete square, mechanically blends
the outer eight pixels toward their opposing edges, then quantizes without
dithering. Opposite edge rows/columns match exactly. The unmodified originals
are retained; edge matching is not claimed to be original generated pixels.
The 3×3 boards are provided for visual seam/pattern judgment.

Shallow water uses StandardMaterial3D with modest specular response. The deep
surface uses two slow samples of the same tile, world-registered in X/Z at 2m
per repeat. Adjacent cells therefore share phase. It has no transparency,
refraction, screen/depth read, normal map, extra light or emission. Local values
and ordinary scene lights define its visibility; there is no painted lamp glow.

Instantiate a scene and call:

```gdscript
var surface = load("res://art/textures/drowned-water-v1/deep.tscn").instantiate()
parent.add_child(surface)
surface.configure(cell, cell_size, animate_water)
surface.set_motion(false) # reduced effects: fixed texture phase, depth retained
```

Roots are MeshInstance3D, matching the current `Galleries.water_plane()` return
type. Geometry fills the exact cell footprint. Deep retains the placeholder's
y0.12; shallow sits at y0.018. This is visual height, not a new physical water
depth or collision. Shallow can also be used as a floor material in an authored
environment; `surface.gd` does not assign or mutate `DungeonMap.water`.

For live hookup, retain the game's existing flooded-cell authority. Shallow art
must not imply the deep-water time/strain/torch penalty. Preserve dry ledges,
event/arrival/stair cells and the complete removal of water after the existing
drain flag, including cached-floor revisits/restores. Avoid applying a permanent
shallow-water floor theme after draining. Pass the existing reduced-effects
preference and update `set_motion()` when that preference changes.

## Sluice scene and state

`res://art/props/drowned-water-v1/sluice.tscn` is a shaded, non-billboarded
wall prop with a floor origin and no collision. Its six-spoke side wheel,
threaded spindle and stone surround remain registered while the lowered iron
gate becomes a raised gate over an opaque dark drain aperture. Surrounding
details are closely matched generated art, not claimed pixel-identical.

The two **192×192 RGBA** drawings share a **48-colour** palette and hard alpha.
One full-square transform and the closed drawing's contact coordinate define
both states; no individual fitting, trimming, scale or origin change is used.
The existing container script supplies `state="closed"` and `state="empty"`
(open). A standalone caller can set either state before or after adding it.

For the current RoomEvent API, point `quest_sluice.tres`'s `prop` at the scene
and use `prop_on_wall=true` so Main places and orients it against a real wall.
The scene's full canvas is 2m wide; its visible surround fits within that width.
This readable grid-safe mounting makes the wheel smaller than the existing
clue's literal "taller than a man": adjust that presentation wording to
"a massive iron wheel" during hookup, or author a wider alcove before scaling
the whole assembly up. Do not enlarge it across neighbouring cell walls.

The live floor-five sluice becomes the floor-six stair when resolved. Preserve
that transition; showing the open drawing must not add a second passage,
duplicate the stair, block movement or change quest outcomes. This scene merely
provides the requested ready/resolved art. It does not drain water itself.

## Validation and rebuilding

- **53 source/export checks:** original-copy/prompts/hashes, reference
  preservation, native dimensions, palettes, exact periodic edges, distinct
  shallow/deep values, hard alpha, margin/registration, opaque open aperture
  and shader/state contracts.
- **18 headless scene checks:** material/mesh contracts, world-grid alignment,
  motion toggle, actual ready/resolved texture swap and fixed registration.
- **36 real-renderer checks / 16 captures:** Godot 4.7.2 Mobile/D3D12, desktop
  1280×720 and landscape 1278×590, original dry floor, shallow/deep comparison,
  both sluice states at two distances, dim light and still mode. Twelve real
  frames form the motion GIF. Animated pixels change; still-mode pixels remain
  identical with camera/light held fixed. Logs and shutdown are clean.
- **79 browser checks:** desktop/844px landscape/390px layouts, native and
  96px state views, all captures decoding, motion play/pause, touch target sizes
  and no horizontal overflow.

The four native textures total **416 KiB RGBA** before engine overhead. Physical
iPhone performance/readability remains #66. The current cell-boundary transition
is clear rather than a new shoreline system; no splash/shore geometry or sound
was added. This review uses existing cave walls for comparison, not a finished
Drowned Galleries environment.

```text
python tools/art/build_drowned_water.py
python tools/art/validate_drowned_water.py
Godot --headless --path . --editor --import --quit
Godot --headless --path . --script tools/art/check_drowned_water.gd
Godot --position -10000,-10000 --path . --script tools/art/check_drowned_water.gd -- --shots
python tools/art/build_drowned_water_review.py
node tools/art/check_drowned_water_review.cjs
```

Use headless checks by default. The screenshot run was launched hidden and
off-screen, per the owner's no-focus-stealing preference. It uses no Main,
player save, preferences or audio. Source/review folders have `.gdignore`;
runtime scenes/materials/textures are under props/textures. Editor-generated
UID/import files accompany the new assets.
