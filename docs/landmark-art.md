# Landmark art: roots, miners' shrine and collapsed cache

Delivery for #132, following the owner's later instruction that the shrine is
an interactive event for #133. The map glyph is connected. The new cave scenes
are ready for placement; this delivery does not add landmark kinds or change
event outcomes.

Open `art/concepts/landmarks-v1/inspector.html` for native previews, fresh/resolved
switches, candle pause/step controls and actual mounted-room captures. The
captures use the current cave theme in Godot 4.7.2's Mobile renderer. Phone views
are Windows renders at phone dimensions, not physical iPhone tests.

## Runtime library

`art/dressing/landmarks-v1/catalog.json` is a standalone sibling of `cave-v1`.
Every entry gives its source, source/export hashes, native canvas, crop/scale,
mount, pivot, physical size and inclusive floor range. Existing cave-v1 exports
and placement remain unchanged.

| Pieces | Mount / visible size | Floors |
| --- | --- | --- |
| `root-curtain-a` | Ceiling; 0.65 m high | 2–3 |
| `root-curtain-b` | Ceiling; 1.15 m wide | 2–3 |
| `wall-roots` | Wall; 1.3 m high | 2–3 |
| `root-foot-tangle` | Floor edge; 0.7 m wide | 2–3 |
| `floor-crossing-root` | Flat decal; 1.45 m wide | 2–3 |
| `miners-shrine`, `miners-shrine-used` | Wall; 1 m wide | 1–3 |
| `shrine-offerings`, `shrine-offerings-used` | Floor edge; 0.65 m wide | 1–3 |
| `collapsed-crates` | Floor edge; 1.1 m wide | 1–2 |
| `split-barrel` | Floor edge; 0.9 m wide | 1–2 |
| `fallen-banner` | Flat decal; 1.15 m long | 1–2 |
| `cache-rubble-planks` | Flat decal; 1.3 m wide | 1–2 |
| `cache-spilled-grain` | Flat decal; 0.85 m wide | 1–2 |

All fourteen textures are 128×128 RGBA, with hard alpha and one shared
64-colour palette. Transparent texels have zero RGB. The scenes use nearest
filtering, respond to scene lighting and add no collision. A cell is 2 m wide;
walls are 2.4 m high. Roots leave an open space below the fringe. Crates/barrel
are crushed under rock; they contain no loose loot or intact lids.

Wall roots/niches face local +Z: place their root against a wall, at the desired
centre height. Their built-in 0.012 m offset keeps them above the wall surface.
Ceiling roots anchor at the top of visible art; floor-edge pieces anchor at
the foot. Both use Y billboards. Decals are already rotated flat and offset
0.012 m above the floor. Rotate the parent around Y to match the surface.

The banner's separate `Seal` layer uses the existing canonical
`art/symbols/crest-v1/forked-seal.svg`. Its shape is unchanged; this does not
assign new faction or magical lore to the motif. The cloth master is retained
without the stamp, and the native seal layer can be reused or suppressed.

## Shrine event handoff

Use `art/dressing/landmarks-v1/miners-shrine-event.tscn`. It combines the wall
niche, floor offerings and optional two-frame candle accent. Its root belongs
at the intersection of wall and floor; niche centre is 0.95 m above the floor.
Face local +Z into the room. The existing pale seated idol has been replaced
visually by a dark wooden miner with a pick and a timber-topped stone niche.

The scene's `state` accepts the established `closed` and `empty` names:

```gdscript
shrine.state = "empty"             # consumed/resolved event
shrine.candle_glow_enabled = false # optional art setting
```

`empty` swaps both niche and offerings, removes the blue cloth, shortens the
candles, empties the cup and stops/hides the accent. `closed` restores the
original layers. Setting the state before `_ready()` works. Both state pairs
share one source crop, downscale, offset, physical size and pivot; no transform
changes during the swap.

`shrine-glow.tres` plays two frames at 2 fps from a registered 256×128 sheet.
The tiny native flames/low-alpha halo sit at the three offerings wick tips.
This is a visual accent with no Light3D, visibility reward or supply effect.
It never alters held-light rules. The niche's own spent stubs remain unlit.

Claude's #133 miners' shrine currently borrows `idol-niche.tscn`. Do not simply
replace that path in `object_miners_shrine.tres`: current
`Main._create_room_prop()` places props at cell centres. The new wall-mounted
scene needs a wall anchor and orientation chosen during placement. When that
is added, bind the scene in both the event resource and
`tools/story/build_shrines.gd`. Main's existing `_empty_prop()` can already set
`state="empty"`. Defiled shrine/well/cache event props remain separate future
art; the collapsed royal cache here is scenery, not #133's buried loot cache.

## Map glyph

`art/ui/backlog96-v1/map/landmark.png` is a 32×32 charcoal cairn from the native
SVG in `art/source/landmarks-v1/landmark.svg`. `Minimap._draw_landmark()` uses it
for the corner map, full map and Discoveries rail. Known/unknown rules,
geometry, icons for objects/rest/stairs and party movement are unchanged.
The inspector shows the mark at 10, 16, 20 and 32 pixels.

## Sources and rebuilding

Fifteen original built-in ImageGen masters, exact prompts, reference paths and
SHA-256 hashes are preserved in `art/source/landmarks-v1/generation.json`.
Fourteen masters are used; the first offerings candidate remains for history.
Source files are ignored by Godot and excluded by the Windows export preset.
Generated originals remain byte-exact copies. Native map/seal inputs have a
separate `native-inputs.json`; no fallback image API was used.

Rebuild native SVG exports with Godot:

```text
Godot --headless --path . --script res://tools/art/raster_landmark_native.gd
```

Then run the normal project Python environment:

```text
python tools/art/build_landmark_art.py
python tools/art/validate_landmark_art.py
python tools/art/build_landmark_inspector.py
```

The exporter only reduces, registers, quantizes and prepares native art
layers/mounts; it never redraws generated subjects. Shrines share union crops.
The shared palette reserves four colours for the native seal/candle accents.

## Checks

- 160 source/export checks: immutable originals, hashes/prompts, native size,
  alpha, shared palette, paired transforms, physical scale and canonical seal.
- 105 Godot checks with twelve actual room/map captures: imported textures,
  mount orientation, surface offsets, no colliders, shrine state restoration,
  optional glow and real Minimap/Discoveries rendering.
- 35 browser checks at 1280×720, 1278×590 and 844×390: selection, state swaps,
  pause/step controls, image loading, touch targets and no horizontal overflow.
- Final import/render logs are clean. Runtime texture canvases total
  1,118,208 bytes (about 1.07 MiB RGBA before overhead). Sparse placement still
  needs review in live floors; no performance claim is made for a physical phone.

Reports and captures are saved beside the inspector. The isolated Godot review
is `tools/art/check_landmark_art.gd`; the browser review is
`tools/art/check_landmark_inspector.cjs`. Neither opens Main nor writes saves.
