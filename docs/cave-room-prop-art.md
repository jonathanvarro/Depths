# Cave room-event prop art · v1

Issue #75; placement and live state integration remain [#46](https://github.com/jonathanvarro/Depths/issues/46).

Five transparent 128 × 128 pixel-art exports cover four existing room events.
They use sparse clusters, muted materials, nearest filtering and real scene
lighting. These are reusable assets, ready for placement; the live event
selection, outcomes, costs and movement remain unchanged.

## Event-to-scene mapping

All paths below are relative to the project root; prefix with `res://` in Godot.

| Existing event resource | Scene in art/props/cave-room-props-v1 | Presentation |
| --- | --- | --- |
| data/events/chest_abandoned_pack.tres | abandoned-pack.tscn | Torn olive canvas, brown leather, chewed strap; flap closed |
| Same pack after a resolved search | pack-searched.tscn | Same scale, floor pivot and palette; open, empty interior |
| data/events/object_pale_idol.tres | pale-idol.tscn | Small worn pale stone figure, faceless head, folded hands and plain plinth |
| data/events/object_still_pool.tres | still-pool.tscn | Opaque dark water, irregular stone lip, horizontal floor card |
| data/events/rest_old_camp.tres | cold-camp.tscn | Cold ash hearth, blackened logs, torn bedroll and dented tin cup |

Choose the art by the selected **event resource identity**, not only the
DungeonMap content enum: both the pack and a treasure chest use CHEST; both
idol and pool use STRANGE_OBJECT; other rest events are not abandoned camps.
Do not turn every CHEST into a pack or every rest tile into this campsite.

## Placement and state

- Pack: root at its supporting floor, near a wall with clearance for the
  chewed strap. Call `set_searched(true)` only after the game resolves an
  actual search. Looking, prodding, leaving or opening an event panel alone
  does not empty it. The picture never reveals which random reward or
  ambush was selected. Reset with `set_searched(false)` only when the
  underlying event model resets.
- Idol: root at the support surface of a wall niche. Its default art scale
  is about 0.49 m high. The scene supplies the figure; level dressing must
  supply the niche/ledge and its placement. Floor-origin review captures
  check the art in isolation. Its warm-air clue has no visible magic aura,
  built-in light or promise of a beneficial result.
- Pool: root at floor centre. The child sits 0.012 m above the floor to
  avoid z-fighting, rotated -90 degrees about X, with billboarding disabled.
  Keep this orientation; the source is drawn exactly overhead. Retain the
  existing floor underneath. Its water centre is opaque. No descent shaft,
  collision, swimming, reflection shader or guaranteed healing is added.
- Cold camp: root at floor Y=0. It is a low, wide, pre-drawn group on an
  upright fixed-Y sprite, like the existing lying-body art. Do not rotate
  it flat. It has no embers, smoke, animation, particles or light. It is
  separate from the lit campfire/recruitment campsite and grants no new
  rest, food or safety rules.

Scenes add no collision objects. Let the existing level/event system decide
occupancy, interaction range, occlusion, visibility and persistence. Check
actual map-facing placement and HUD overlap during #46.

## Canvas, material and scale contract

| Asset | Visible colour limit | Pivot (native px) | pixel_size (m/px) | Child Y (m) |
| --- | --- | --- | --- | --- |
| Pack, both states | Shared 24 | (64,120) | 0.00625 | 0.35 |
| Pale idol | 16 | (64,120) | 0.0046875 | 0.2625 |
| Cold camp | 24 | (64,120) | 0.0125 | 0.7 |
| Still pool | 24 maximum; 15 used | (64,64) | 0.0140625 | 0.012 |

All canvases are RGBA 128 × 128 with binary alpha and transparent margins.
The upright exports' bottom visible row is y=120. Pack states share the
same normalization scale, offset, visible bounds and palette. They are
two static drawings, not a flap-opening animation; fine folds may vary.

Every sprite is shaded, nearest filtered, alpha-discard at 0.5; the three
upright prop types use fixed-Y billboarding. Imports are lossless with
mipmaps disabled. Solid art responds to lantern illumination; no emitted
light is baked into the scene. Pool surface highlights are sparse painted
material cues, not live reflections.

## Sources and repeatable export

Built-in **image_gen.imagegen** created the masters. Exact prompts,
transparent-background flags, reference paths and generated-file provenance
are in [generation-manifest.json](../art/source/cave-room-props-v1/generation-manifest.json).
The searched pack edits the unsearched master. The cold camp uses the
existing campfire base master as a style/shape reference; that earlier
master is unchanged. Original generated masters are preserved beside the
manifest and excluded from runtime import/export.

Run `tools/art/build_cave_room_props.py` with Pillow to recreate exports
and dark/light review boards. It uses nearest resizing, visible-pixel
palette quantization without dithering and an alpha threshold of 96.
It does not draw new replacement art. Registration, colour counts and
SHA-256 hashes are recorded in
[asset-validation.json](../art/concepts/cave-room-props-v1/asset-validation.json).

## Checks and review

Godot 4.7.2 Mobile/D3D12 imported all five textures without warnings/errors.
The isolated `tools/art/check_cave_room_props.gd` verifies canvas, alpha,
state changes, transforms, lighting materials, absence of lights/collisions,
and the pool's horizontal orientation and opaque water centre.

Its `-- --capture` mode uses the real cave theme/level builder with no Main
scene: **85 checks pass**, with **20 captures** at 1280 × 720 and
1278 × 590, each prop under normal and dim lantern light.
[godot-validation.json](../art/concepts/cave-room-props-v1/godot-validation.json)
records the result. The [overview](../art/concepts/cave-room-props-v1/overview.png)
and light-background sheet show native art enlarged 2× with nearest sampling.

These are simulated landscape-phone viewports on Windows. A physical
iPhone and the live event-placement lifecycle remain implementation checks.
