# Wet walls and waterworks dressing — #166

Two wet-wall siblings and three separate dressing sprites complete this portion
of the Drowned Galleries request. [Offline inspector](../art/concepts/waterworks-v1/inspector.html)
includes native/64px views, light/dark backdrops, 3×3 repetition and eighteen
actual first-person Godot captures. This is an asset library for Claude's live
hookup, with no theme, floor, quest, water-state or placement changes.

## Assets

| Asset | File | Placement |
|---|---|---|
| Plain wet slate | `art/textures/waterworks-v1/wet-plain.tres` | Dominant wall material |
| Channelled wet slate | `art/textures/waterworks-v1/wet-channelled.tres` | Sparse variant with mineral grooves and small drain slit |
| Dripping stone channel | `art/dressing/waterworks-v1/dripping-channel.tscn` | Fixed wall mount, origin at canvas centre |
| Broken iron pipe | `art/dressing/waterworks-v1/broken-pipe.tscn` | Fixed wall mount, origin at canvas centre |
| Silted dead lamp | `art/dressing/waterworks-v1/silted-lamp.tscn` | Floor origin, bottom of sediment at y0.008 |

All paths are project-relative (`res://`). Shared catalogue:
`art/textures/waterworks-v1/catalog.json`. Runtime art is native128; every image
has at most 32 visible colours. Wall tiles are opaque; props use hard transparent
alpha, nearest sampling, ordinary world lighting, no billboard, shadow casting,
collision, emission, extra light, particles or script. Drops are static drawing
details, not an animation or water simulation. The lamp has a black dead wick;
its painted glass highlight is not emitted light or a usable supply pickup.

## Mounts and integration

Use the plain tile for most faces. The channelled tile's drain is an intentionally
recognizable accent, so avoid long rows of identical drain slits. Its 3×3 board
shows the repetition cost. The existing `wall_variant_material` selector chooses
roughly one wall in five; a bespoke dresser can be sparser if needed. Both new
materials use specular 0.28 / roughness 0.82, giving a modest damp response without
reflection, normal maps or an additional shader. Existing cold slate walls are
unchanged. Generated siblings share construction and scale, not identical blocks.

Set `EnvironmentTheme.wall_face_uv=true` so a full tile covers each wall face;
the legacy BoxMesh atlas would crop/stretch it. Match to existing
`descent-surfaces-v1/drowned-masonry-floor.tres` and `-ceiling.tres` and the
already delivered `drowned-water-v1` surfaces. This handoff assigns no new live
theme. Damp stone can remain after draining, but the art must not change the
existing water grid, drain flags, deep-water penalties or dry ledges.

Wall roots are centred with local +Z facing into the open cell. Place them about
0.025m in front of a real wall and rotate the root with the wall normal. These
are fixed flat sprites; do not attach them to the camera or use billboard mode.
The channel's full canvas is 1.8m square (visible stone is much narrower); centre
it around y1.23 in the 2.4m wall. The pipe's full canvas is 0.8m square; a centre
height around 0.8–1.0m works. Keep their full visible bounds inside the wall cell
and clear of passage openings, stairs, event props and the sluice wheel.

The lamp's full canvas is 0.65m wide. Set its root at floor y0; the scene already
registers its sediment base. Put lamps on dry ledges or drained floor, clear of
the walking route. The review's deep-water view deliberately shows occlusion
when a floor lamp is left in a flooded cell; it is not a recommended live
placement. Do not lift it onto the water plane to make it float. Keep these
background props less prominent than actionable chests and room events.

Sprites are single planes with painted depth. Check oblique wall angles during
live placement; do not expect the pipe to have a three-dimensional back. No
placement scheduler, persistent IDs, drops, drip audio or interaction added.
The separate ancient stonework landmark and monsters remain future #166 work.

## Sources and validation

Five built-in ImageGen masters, exact prompts, original paths and hashes are
retained in `art/source/waterworks-v1/`. `prompts.json` records generation and
`generation.json` records native exports and the unchanged existing wall hash.
Source and review folders have `.gdignore` files. Runtime textures, materials
and scenes are separate, with editor-generated import/UID files included.

The exporter BOX-downsamples the complete square to 128px. Walls receive an
eight-pixel periodic apron blend, then 32-colour quantization without dithering;
opposite edge pixels match exactly. This is mechanical export work, not a claim
that all generated masonry joints continue perfectly across repeats. Prop alpha
is thresholded at 128, quantized from visible pixels only, and hidden RGB zeroed;
no background removal or silhouette redraw was needed. Native overview and
repetition were visually inspected, alongside the actual renderer views.

- 51 source checks pass: retained sources/prompts/hashes, native dimensions,
  palette, opaque/periodic walls, prop alpha/margins, and material/mount contracts.
- 26 headless Godot checks pass: loaded resources, nearest sampling, lighting,
  fixed mounts, hard alpha and one-sprite scene budgets.
- 47 renderer checks pass, including 18 captures at 1280×720 and 1278×590 using
  Godot 4.7.2 Mobile/D3D12: plain/channelled walls, dry/shallow/deep/dim and close
  mounts, with existing sluice and matched floor/ceiling. Clean logs and exit.
- 32 headless Chrome review checks pass: five assets, native/distant/enlarged
  sizing, backdrops, all captures, touch controls and no horizontal overflow at
  1280/844/390px. Reports and `browser-review.png` sit beside the inspector.

Checks load no Main, player saves, preferences or audio. Screenshot runs use a
hidden off-screen process to avoid visible game windows/focus stealing. Physical
iPhone performance and live floor placement remain separate checks.

```text
python tools/art/build_waterworks.py
python tools/art/validate_waterworks.py
Godot --headless --path . --editor --import --quit
Godot --headless --path . --script tools/art/check_waterworks.gd
Godot --position -10000,-10000 --path . --script tools/art/check_waterworks.gd -- --shots
python tools/art/build_waterworks_review.py
node tools/art/check_waterworks_review.cjs
```
