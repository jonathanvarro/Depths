# Herbs, traps, strange sites and exploration mist

Owner-selected batch, #244/#247, 2026-11-08. Delivery branch
`codex/traps-sites-mist-3d`. The herb resource and exploration ambience are wired
on this branch. Seven new 3D event scenes remain a reusable library awaiting
event hookup. Current event resources, trap outcomes and navigation are preserved.

Local review is `E:/GitHub/Depths/build/local-traps-sites-mist-v1/inspector.html`.
`START_REVIEW.cmd` opens native controls for state, lighting, angle, light band,
mist and motion. Editable per-piece Blender masters are in its `masters` folder.
All rendered reviews and model masters remain local under build/.

## Calming herbs

The new item is a twist of dried sage/olive leaves, bruised brown edges, visible
stems and flax binding. Its exposed fan silhouette distinguishes it from the
antidote's paper packet. Runtime files are `art/items/field-kit-v1/calming-herbs.png`
and its `compact64/` sibling. These are separate direct-source 128px/64-colour and
64px/32-colour reductions, with hard alpha, zero invisible RGB and 8/4px margins.

`data/items/calming_herbs.tres` changes only its icon URI. Effect, amount, use time,
price, combat availability, description and identity are unchanged. The immutable
generated master, exact built-in ImageGen prompt, original path, source/export
hashes and nonvisual resource hash are in `art/source/calming-herbs-v1`.
`tools/art/build_calming_herbs.py` reuses the existing field-kit fitter without
changing or regenerating the earlier library/catalogue. No fallback image API.
Three actual Pack captures verify the binding at desktop and phone widths.

## Seven 3D event scenes

Runtime family is `art/props/traps-sites-3d-v1`, with twenty geometry exports.
Metric bounds, export hashes, palettes and recipes are in catalog.json. The
shared 25-colour palette extends the mine props' eighteen colours. Roughness 1,
low specular, nearest palette sampling and the existing 2m world grain retain
the earlier faceted/worn direction. Meshes cost 124–1,168 triangles per state;
only one state is visible. A pool adds one water surface; dart ports add one
small independent wall mesh. No new lights, collision, occupants or character
clips. These are 3D interpretations of the preserved painted designs.

| Scene | closed | open | empty | Mount |
| --- | --- | --- | --- | --- |
| tripwire | Taut wire | Released/coiled wire | Snapped wire and fallen stones | Floor, about 1.5m wide |
| bell-alarm | Set line and one-clapper bell | Disconnected bell and coiled line | Snapped/slack line | Floor, about 1.3m wide |
| snare | Set noose | Released rope coil | Drawn noose on sprung peg | Floor, under 0.8m footprint |
| dart-plate | Raised pressure slab | Wedged slab | Depressed slab and spent darts | Floor, separate knee-height wall ports |
| hollow-floor | Cracked slabs | Collapsed | Collapsed | Floor, under 1.6m footprint |
| idol-niche | Idol present | Idol removed, pale footprint | Idol toppled in front | Actual wall at floor height, +Z facing room |
| still-pool | Calm water | Disturbed water | Disturbed water | Floor, under 1.4m footprint |

Set `state` before adding a scene to restore it immediately, or call
`set_state(&"empty")` afterward. `set_motion(false)` freezes the pool's optional
slow surface motion at its current phase. Ready pools and other props do not
process every frame. The static ripple outlines remain visible in still mode.
Trap versions are distinct static drawings in geometry; no trap-firing animation
or timing is introduced. The wire is thin physical geometry and still relies on
the existing clue UI for discovery, especially at phone distance.

Choose a version from the actual outcome. A consumed event alone does not prove
that a trap fired or an idol fell. No new flags, damage, costs, knowledge, rewards,
water safety, drowning, flood or persistence rules are supplied by this library.
The collapsed floor uses an opaque dark inset above the existing floor, plus
broken rim geometry. It does not excavate a floor mesh or change traversability.
The pool is also opaque and shallow in geometry; it does not make a flooded cell.

The dart scene retains `mount_in_cell(map, cell, cell_size)` compatibility. Its
ports stay hidden until mounted against a real wall, y0.48m, with +Z into the
room. A review-only placement shows them behind the slab. The niche should use
the actual wall anchor on hookup; do not place it as a free-standing billboard.

Geometry is authored using the established mine helpers; no suitable existing
pack pieces were needed for these small mechanisms/carving/basin. The unchanged
helpers and exact builder hashes are recorded. Prior CC0/source families remain
intact. No new third-party licence or private model upload is introduced.

## First-person mist

`art/effects/exploration-mist-v1/mist.tscn` replaces Ambience's former single
ground plane in `scripts/ambience.gd`. It is explicitly for the first-person
dungeon, per the owner's clarification. It does not draw on the parchment map.
The existing controller still hides ambience in combat (including an overhead
combat view), the opening, camp/ending and absent levels.

Three world-registered 11m sheets at y0.10/0.29/0.48m sample the existing authored
256×64 fog-strip alpha twice each, with different offsets and a slow whorl.
Their edges fade between 2.8m and 5.4m from the party. Normal depth testing keeps
them behind walls. There is no volumetric fog, depth/screen read, refraction,
particle system, world light, collider or extra gameplay concealment. Cost is
three transparent draw calls / six triangles, with ordinary transparent overdraw.
Physical iPhone performance is untested.

The controller passes the existing light-band factor (and the earlier floor-1
attenuation), dimming both mist colour and opacity as the lantern fails.
`set_motion(false)` freezes its explicit phase, with no shader TIME dependency.
The existing Settings `flashes` preference controls that motion; other ambience
rules are unchanged. Hidden mist stops processing and resumes from its held phase.
Moving the party relocates the sheets/edge envelope while UVs remain in world
space. Camera height/turns never tilt the sheets or lift them from the floor.

Standalone callers can use `set_centre(world_position)`,
`set_light_strength(0.0..1.0)`, `set_motion(bool)` and
`set_display_phase(seconds)` for paused art inspection. These methods hold no
saved gameplay state. The player remains free to inspect traps and room features.

## Verification and rebuild

- 387 isolated Godot 4.7.2 Mobile checks pass for actual imported bounds, UVs,
  budgets, floor mounts, exactly one visible state, immediate restore, real dart
  wall anchoring, pool motion/still mode, native phone controls, fog processing,
  light parameters and pixel-exact frozen fog versus visibly changing phases.
- 154 native library captures cover three angles, cave/neutral lighting, every
  API state, desktop/852×393/667×375 controls, ready/resolved room compositions,
  clear/mist/later-phase/low-light comparisons and twelve mist motion samples.
  The GIF uses the native samples at their 0.6s spacing, a 7.2s loop. Geometry
  does not loop spatially at the GIF seam; it is a motion preview.
- 15 live Pack checks pass, with three real captures. Seven live Main/Ambience
  checks pass for attachment, drift, reduced-effects freeze, bright/out light
  and combat gating, with one real dungeon capture. The Main teardown log
  reports a TextureRect/Object orphan warning, tracked in #249; the isolated review and Pack
  checks have clean error logs. No new mist node allocates a CanvasItem.
- Browser tests cover state/light/angle combinations, room/mist views, motion,
  image loading, batch filtering, touch targets and overflow. Packaging verifies
  source/builder/helper/GLB/runtime-script hashes against the native report.
  Exact machine reports are beside the local gallery.

From the isolated checkout, use `--workspace E:/GitHub/Depths` where accepted.

1. Python `tools/art/build_calming_herbs.py` exports/binds the icon.
2. Blender background/factory-startup/disable-autoexec/python-exit-code 1 with
   `tools/traps_sites/build_models.py` builds geometry and local editable masters.
3. Python `tools/traps_sites/prepare_review.py` composes scenes and the fixture.
4. Godot 4.7.2 `--headless --editor --path <review> --import`, then native
   `--path <review> --script res://check.gd --quit-after 12000`. Require the fresh
   report and clean native error log rather than exit zero alone.
5. Import the isolated game checkout, then run native
   `res://tools/calming_herbs_check.gd` and `res://tools/exploration_mist_check.gd`.
6. Python `tools/traps_sites/package_review.py`, then Node
   `tools/traps_sites/check_gallery.cjs E:/GitHub/Depths` with bundled modules.
