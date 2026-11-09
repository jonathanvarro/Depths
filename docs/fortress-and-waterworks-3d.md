# 3D fortress structures and waterworks machinery

Owner-requested art library, #246, 2026-11-08. Ten scenes and sixteen geometry
exports are in `art/props/fortress-waterworks-3d-v1`. The local review is
`E:/GitHub/Depths/build/local-fortress-waterworks-v1/inspector.html`.
`START_REVIEW.cmd` opens native mouse/touch/keyboard controls. The native
inspector starts still and includes a mechanical pose slider. Editable Blender
masters retain separate named pieces under the review's `masters` folder.

Delivery branch is `codex/fortress-waterworks-3d`. Live placement remains pending.
Existing painted scenes, themes, event resources and rules are preserved.

## Inventory and mounting

All dimensions are metres. Local +Z faces the open cell, +Y is up. Floor origins
are at ground contact, allowing small irregular stone/timber penetration.
catalog.json records actual exported bounds, per-scene fixed viewing envelopes,
component offsets and triangle counts. Machinery envelopes include raised states.

| Scene | Mount and intended use | Visible triangles |
| --- | --- | --- |
| palisade.tscn | Floor, 1.7m-wide short fence; intact and broken siblings | 964 maximum |
| watch-post.tscn | Floor, roughly 0.9m footprint and 1.8m high; wall alcove/edge | 1,480 |
| overhead-walkway.tscn | Ceiling, 1.8m span; lowest timber leaves at least 1.85m headroom at 2.4m | 1,060 |
| hanging-cage.tscn | Ceiling, about 0.55m diameter; empty side-alcove cage | 1,020 |
| hanging-bracket.tscn | Wall-centred hook/brace with riveted plate | 204 |
| throne.tscn | Floor; chair, ragged backing, platform and steps | 1,234 |
| sluice.tscn | Wall at floor height; side wheel, screw, guide frame, moving shutter | 2,272 |
| flow-gate.tscn | Wall at floor height; chain hoist, drum, moving shutter | 4,136 |
| broken-pipe.tscn | Wall-centred flange and bent hollow pipe, projects under 0.44m | 336 |
| wall-gutter.tscn | Wall-centred open U-channel with silt and bent lower lip | 84 |

Use exact catalog values when placing. The cage hangs down to about 1.27m at a
2.4m ceiling and must stay in a side alcove, outside the travel/sightline. The
watch post and throne occupy ground space; dressing placement must reserve it.
The walkway is a ceiling prop, not a new traversable level or climb action.
Chains, lock and brackets are decorative. There are no invented occupants.

Both machinery scenes fit one 2m wall cell and stay below 2.34m when fully raised.
Place the root on the floor, roughly 0.025m in front of an actual wall, with local
+Z into the room. An opaque dark outflow panel sits in front of that wall, behind
the shutter. The raised gate reveals an outflow throat, not a new walkable route
or a flooded party cell. Pipe/gutter can mount around y1.2m; give their projecting
geometry clearance from adjacent routes. Their drips/water simulation are absent.

## State and movement

```gdscript
var gate = load("res://art/props/fortress-waterworks-3d-v1/sluice.tscn").instantiate()
gate.state = "empty" # immediate restored open state, before adding
gate.animate_motion = reduced_effects == false
parent.add_child(gate)
gate.set_state("closed")
gate.set_state("open") # same raised drawing as "empty"
gate.set_motion(false) # finish the requested state immediately
gate.set_display_phase(0.5) # paused art inspection only
```

`closed` lowers the machinery shutter. `open` and `empty` raise it by 1.04m.
The side wheel or hoist drum turns once during a 0.65s eased transition. Frame,
threshold, screw and chains remain registered; chains have no rope simulation.
Interrupted requests continue from the current pose to the latest target.
Disabling motion cancels the tween and finishes the latest requested state.
Restoring state before `_ready()` applies immediately without replaying motion.
`set_display_phase()` is a preview override and does not update requested state.

Palisade `empty` selects the broken sibling. `closed` and `open` select intact.
The other props are static. Every scene shares the same presentation API for
callers; static props do not start a tween. No scene runs per-frame idle processing.

Existing fortress destruction, queen rewards, encounters, flood/drain flags,
quest stages, extra time/strain, sluice-to-stair replacement, reservoir remodel,
arrival, day reset and save/restore remain caller-owned. Pass the player's effects
preference on hookup. Do not use an art state change to resolve gameplay itself.

## Sources and materials

CC0 reuse starts from the official KayKit Dungeon Remastered chair, pinned to
commit b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07. Exact original bytes, included
licence, Git blob hashes and SHA256 are in `art/third-party/kaykit-fortress-v1`.
It is rotated, fitted, recoloured and gently warped beneath the throne additions.
All other geometry is authored with the earlier mine helpers, preserving their
default behavior. No shared helper was changed. Existing paintings are retained
as visual references. No character clips were added or tested in this task.

The shared 26-colour palette extends the earlier eighteen colours with rope,
faded red cloth, slate, silt and dark water. One palette material uses nearest
filtering, roughness 1, specular 0.1 and the existing grain's 2m world
repeat. Runtime meshes have one surface each, shared material and disabled shadow
casting. Whole scenes cost one to three draw calls, except the hidden palisade
sibling which renders only one. There are no new lights, emission or colliders.
These are conservative faceted props, not the more detailed painted concepts.

## Review and rebuilding

- Godot 4.7.2 Mobile/D3D12 passes 381 checks, covering actual imported bounds,
  palette UVs, source texture exclusion, per-mesh/per-scene budgets, wall/cell
  envelopes, raised ceiling clearance, default inactivity, fixed frame/root,
  interrupted movement, before-ready restore, paused poses and immediate still
  mode. The opaque outflow is checked in the imported geometry.
- 106 actual renderer captures cover three angles, neutral/environment lighting,
  intact/broken and closed/open/resolved states, six intermediate poses, both
  mounted room examples and 1278×590, 852×393 and 667×375 controls. Native controls
  retain 44px minimum height and simulated phone safe margins. Physical iPhone
  rendering is untested.
- Browser checks exercise lighting, angles, states, intermediate poses, batch
  filters, image loading, touch targets and overflow. Packaging verifies current
  builder/helper/source/model hashes against the native capture report and checks
  for an empty error log. See the local validation JSON files for exact totals.

Run from the isolated checkout, with `--workspace E:/GitHub/Depths`.

1. Blender 5.2 background, factory-startup, disable-autoexec and python-exit-code 1,
   using `tools/fortress_waterworks/build_models.py`.
2. Python `tools/fortress_waterworks/prepare_review.py`.
3. Godot 4.7.2 `--headless --editor --path <local review> --import`.
4. Native Godot `--path <local review> --script res://check.gd --quit-after 12000`.
   Require the fresh validation report and empty error log, not just exit zero.
5. Python `tools/fortress_waterworks/package_review.py`.
6. Node `tools/fortress_waterworks/check_gallery.cjs E:/GitHub/Depths`, with the
   bundled Node module path available.

The model builder writes catalog.json, GLBs and editable local Blender masters.
The preparer writes wrappers/material/palette and copies only review dependencies
to an isolated Mobile project. Blender import is disabled there. Packaging adds
the browser gallery; generated reviews/captures/masters remain local under build/.
