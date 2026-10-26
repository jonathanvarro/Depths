# Matching descent surfaces and remaining cave dressing

**Live integration, 2026-10-25:** the fungal surfaces and selected roots,
moss/fungus pieces are now used on floor two. [Fungal Caverns](fungal-caverns.md)
records placement, still mode and live review. Other families/pieces retain
their library status. The original #139 delivery is recorded below.

2026-10-21 · #139, refs #126/#128/#129/#132.

Twelve new floor/ceiling surfaces complete the six existing deeper wall families.
Twenty dressing entries fill the remaining second-batch and deeper-layer art
requests. This is a mounted asset library for Claude to integrate. Existing
wall files, themes, placement code, events, saves and party light/nerves rules
are unchanged. Proposed deeper floor numbers and story meanings remain unassigned.

[Offline inspector](../art/concepts/descent-finish-v1/inspector.html) ·
[surface overview](../art/concepts/descent-finish-v1/surface-overview.png) ·
[dressing overview](../art/concepts/descent-finish-v1/dressing-overview.png)

## Floor and ceiling families

[Surface catalogue](../art/textures/descent-surfaces-v1/catalog.json) lists each
existing wall and its new floor/ceiling textures and materials. All are native
128×128, opaque, at most 32 colours. Each pair uses its wall's **exact palette**.

| Family stem | Floor | Ceiling |
|---|---|---|
| `worked-cave` | Worn flat shale plates, compacted earth in shallow joints | Broad fractured shale underside |
| `goblin-hold` | Uneven cobbles and patched flags | Rough stone vault underside |
| `drowned-masonry` | Eroded slate paving and mineral-dark joints | Cold slate, shallow fissures and muted deposits |
| `fungal-stone` | Flat old stone with subdued olive crust | Broader continuous stone with quiet growth |
| `buried-city` | Worn limestone paving | Pale dressed stone and old plaster remnants |
| `sealed-temple` | Large recessed basalt flags | Heavy basalt courses |

Material paths follow `res://art/textures/descent-surfaces-v1/<stem>-floor.tres`
and `<stem>-ceiling.tres`. In a **future** EnvironmentTheme, assign these to
`floor_material` and `ceiling_material`, and the existing matching wall to both
wall material slots. Do not change a live theme just to preview this library.
The review fixture duplicates the cave theme in memory.

Materials use ordinary StandardMaterial3D, nearest sampling, repeat and roughness
1. No normals, emission, custom shader or baked light is added. Markings, loose
props, waterlines and luminous growth remain independent of the tiles.

## Dressing catalogue

Runtime files: `res://art/dressing/cave-v2/`. Each ID has a matching `.tscn`;
the [catalogue](../art/dressing/cave-v2/catalog.json) records the texture, mount,
pivot, metres, pixel size, suggested wall height, proposed range and hashes.

| ID | Mount | Visible size | Suggested setting |
|---|---|---|---|
| `moss-curtain` | Ceiling | 1.1 m wide | Damp/fungal cave |
| `old-remains` | Floor edge | 0.85 m wide | Anonymous old skeletal/rag heap; no loot |
| `mine-ring-chain` | Wall | 0.6 m high | Old mine, centre 1.4 m |
| `broken-rail-end` | Wall | 0.55 m high | Old mine, centre 0.6 m |
| `lantern-hook` | Wall | 0.35 m high | Old mine, centre 1.5 m; empty |
| `goblin-hide` | Wall | 0.8 m high | Hide stretched on a crude frame, centre 1.25 m |
| `goblin-banner` | Wall | 0.95 m high | Unmarked dull red cloth, centre 1.4 m |
| `wall-spikes` | Wall | 0.85 m wide | Three pointed iron spikes, centre 1.15 m |
| `chained-cage` | Ceiling | 0.65 m high | Small empty broken cage; no door or prisoner |
| `overhead-walkway` | Ceiling plane | 1.6 m wide | Plank underside, no traversable geometry |
| `waterline-stain` | Wall | 1.6 m wide | Drowned masonry, centre 0.7 m, 65% opacity |
| `mineral-crust` | Wall | 1.1 m wide | Drowned masonry, centre 1.4 m, 80% opacity |
| `drip-curtain` | Wall assembly | 1.1 m wide crust | Same crust plus existing drip; root at 1.4 m |
| `floor-fungus` | Floor edge | 0.3 m high | Existing neutral mushrooms, byte-exact reuse |
| `relief-fragment` | Wall | 1.0 m wide | Worn architectural carving, centre 1.3 m |
| `empty-lamp-niche` | Wall | 0.5 m high | Empty architectural recess, centre 1.2 m |
| `inscription-band` | Wall | 0.8 m wide | Abstract incisions, centre 1.45 m |
| `ward-niche` | Wall | 0.65 m high | Empty basalt recess, centre 1.25 m |
| `seal-ornament` | Wall | 0.35 m wide | Optional separate incised ornament, centre 1.25 m |
| `stranger-mark` | Wall | 0.32 m wide | Provisional scratch motif, centre 1.0 m |

The red goblin banner stays visually separate from the existing torn royal-blue
banner. The scratch has a matching native32 ink drawing (`stranger-mark-ink.png`)
for a future route-map clue, but neither version is wired to the story or map.
No prior canonical stranger drawing was found. Inscriptions, reliefs and the
seal have no assigned language, faction, religion, magic or relic meaning.
The niche names are art labels, not new interactive objects.

Reuse `art/dressing/landmarks-v1` for roots and `art/dressing/cave-v1/wall-fungus`
with its existing ambient pulse for wall fungus. Those subjects were already
delivered and are not redrawn. The neutral floor mushrooms are also unchanged;
their legacy invisible RGB is preserved with the original bytes.

### Mounting

- World scale: **2 m cell / 2.4 m wall**. Size means the visible pixel bounds,
  not the padded canvas. All base cutouts are transparent 128px with at most 64
  visible RGB colours per piece, hard alpha and nearest sampling.
- Wall scenes face local **+Z**. Put the root on the wall face, rotate it into
  the passage, and use the catalogue's centre height. The sprite adds a
  0.012 m offset. Standalone fixture front wall is at `z=1.0`, facing +Z.
- Hanging scenes use the top of visible art as their anchor; floor-edge scenes
  use the bottom. Both use Y billboarding. Place at the ceiling or floor,
  respectively, clear of sight lines and combat/event cells.
- `overhead-walkway` is different: a fixed sprite rotated **+90° about X**,
  facing down, with its centre 0.012 m below the roof. It is a shallow underside
  decal. Do not treat it as a hanging vertical sign or walkable bridge.
- `drip-curtain` combines the mineral sprite with two instances of the existing
  64×128 `ambient-v1/drip.tres`. Keep its root at **1.4 m**: sprites are 0.85 m
  below the root at pixel size 0.008, putting the final splash near floor height.
  Existing drip artwork is unchanged.
- No scene has a collider, controller, interaction area or light node. Sparse
  seeded placement, exclusions and orientation belong in the existing dressing
  system. Review rooms deliberately collect pieces together for inspection;
  they are not recommended live placement density.

### Optional registered glow

`moss-curtain-lit.tscn` and `floor-fungus-lit.tscn` retain the ordinary shaded
base and add an unshaded AnimatedSprite3D. Each has a separate 128px emission
mask and an eight-frame 512×256 atlas, playing `loop` at **4 fps**. Only opacity
changes; pixels, scale and anchors stay registered. The mask touches source
pixels only. Fungus emission is confined to the caps, clear of feet/stems.

Use the ordinary scenes for neutral variants. Glow is faint mood art, adds no
Light3D and never calls supplies, light bands or nerves. Existing darkness and
settings controllers remain responsible for when these variants may be shown.
The inspector can turn glow off or pause/step every frame. The dim room places
neutral plants on the left and luminous counterparts on the right.

## Sources and reproduction

Created with the **built-in ImageGen tool**, one master per subject/surface.
There are 28 immutable generated PNGs: 12 surfaces and 16 dressing masters,
including the retained rejected blunt-spike candidate. Fifteen dressing
masters are selected. All original paths, exact prompts, explicit reference
roles and source hashes are in:

- [Surface prompts and hashes](../art/source/descent-surfaces-v1/generation.json)
- [Dressing prompts and hashes](../art/source/cave-dressing-v2/generation.json)

The original native SVG scratch, inscription band, seal and ink form live in
`art/source/cave-dressing-v2/native`. Glow masks/pulses are native pixel FX.
No generated subject is repainted by the exporter. Source and review directories
have `.gdignore`; runtime copies are independent and import normally.

Surface export uses BOX reduction, the existing six-pixel symmetric wrap apron,
and mapping to the matching wall's exact 32 colours without dithering. Opposite
edge pixels match. This removes border colour jumps; it does not guarantee every
geometric joint continues naturally. Inspect the separate 4×4 repeat sheets.
Cutouts use one alpha-bounds crop, proportional reduction into 112px content,
hard alpha and a 64-colour budget per piece. Native marks retain their canvas.

From the project root, using Python with Pillow/numpy and Godot 4.7.2:

```powershell
python tools/art/build_descent_finish.py
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/art/raster_descent_marks.gd
python tools/art/build_descent_finish.py
python tools/art/validate_descent_finish.py
Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/art/check_descent_finish.gd
python tools/art/build_descent_inspector.py
node tools/art/check_descent_inspector.cjs
```

Chrome/Playwright is used only for the last offline-inspector check. No web
service, Main scene, gameplay save, fuel system or generated campaign is loaded.
The exporter pins existing walls, themes, placement/level code and reused art
in `reused-inputs.json`; the independent validator also compares tracked inputs
against HEAD, tolerating ordinary text newline conversion.

## Verification and limits

- **328** source/export/palette/alpha/scale/preservation checks pass.
- **293** actual Godot scene/material/pulse checks pass; **32** captures cover
  every family under neutral/lantern/phone lighting plus seven mounted setups
  at desktop 1280×720 and phone 1278×590. Final import/render logs are clean.
- **49** browser checks cover paths, panel/family switching, pulse pause/step,
  separate glow and readable controls/layout at 844px and 390px widths.
- The 36 runtime PNG canvases total about **3.066 MiB RGBA** before engine
  overhead. Reused external wall and drip textures are not counted again.

The existing LevelBuilder BoxMesh UV atlas stretches/crops wall materials more
than its floor/ceiling planes. The actual captures show this density difference;
this art batch does not change geometry or UVs. Repeats remain visible in large
plain rooms. The captures establish art mounting and import, not live placement,
combat legibility with every enemy, physical iPhone recognition or frame rate.

Claude's next step is to integrate the new second-batch mounts into sparse
placement and use the matched surface sets when deeper environments are approved.
#128 remains open for that integration; this pack completes #139's artwork.
