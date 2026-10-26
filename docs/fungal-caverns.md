# Fungal Caverns · completed environment

2026-10-25 · Refs #126, #128, #129, #139.
[Actual Godot review gallery](../art/concepts/fungal-caverns-v1/inspector.html).

The current second floor now has a coherent visual set: moss-stained stone,
matching floor/ceiling, roots, hanging moss, shelf and floor fungi, mineral
streaks, subdued puddles and occasional drips. This develops the existing
floor-two damp/fungal direction. Campaign length, story and encounters remain
as before. The upper mine, goblin outskirts and fortress keep their current sets.

## Integration

`themes/fungal-caverns.tres` binds the delivered fungal-stone materials and
current web/roots passage states. A small inherited pit scene gives its ground
the matched floor. Hanging roots remain the way up.

The optional `EnvironmentTheme.dressing_script` selects a cosmetic dresser;
empty retains `scripts/dressing.gd`. The fungal theme uses
`scripts/fungal_dressing.gd`. Custom themes and debug layouts are respected.
Restore now selects the saved floor's theme before rebuilding. Old floor-two
saves gain the new appearance without a save-format/version change.

This theme opts into full-face wall UVs: each face receives the whole 128px
tile instead of a stretched section of BoxMesh's atlas. The same 24 vertices,
12 triangles and wall instance count remain. Other themes retain their old UVs.

## Composition and motion

Subdued olive and stone colours warm beneath the existing carried lantern.
Broad wall shapes remain quiet; small growth supplies scale, while the existing
landmarks provide stronger navigational set pieces. Materials retain nearest
sampling, full roughness and their recorded shared palette.

The scatter has its own site/depth seed and places at most one piece in each
chosen cell. Entire encounter rooms, events, passages, stairs, arrivals, solid
cells and reserved landmark cells stay clear. It does not mutate map data or
consume gameplay RNG. Roof anchors sit at 2.38m; floor-edge pieces sit 0.76m
from cell centres in the current 2m grid. Return visits and restore remain stable.

Moss and some floor fungi reuse their registered neutral/glow layers. Shelf
fungi reuse the existing pulse; some flowstone receives the existing drip.
Initial frames are seeded. With screen effects disabled, pulses hold still and
drops disappear; changing the setting live resumes the same drawings. These
pieces add neither lights nor colliders. They cannot change carried light or
nerves. Existing exploration fog/darkness, music, ambience and footsteps remain;
this task does not replace those audio recordings.

## Sources

No new raster art was generated or repainted. Original runtime PNGs and source
masters remain unchanged. The three native128 surface textures total about
0.1875 MiB RGBA before overhead; existing cutouts/FX are shared. Puddles receive
a quiet olive tint in this dresser, preserving their original transparency.

- [Wall masters/prompts](../art/source/cave-walls-v1/generation.json)
- [Floor/ceiling masters/prompts](../art/source/descent-surfaces-v1/generation.json)
- [Moss/fungi and registered pulses](descent-surfaces-and-dressing.md)
- [Cave dressing](cave-dressing-assets.md) and [roots](landmark-art.md)
- [Reused asset hashes](../art/concepts/fungal-caverns-v1/reused-assets.json)

## Verification and limits

Godot 4.7.2, Mobile renderer, Windows AMD RX 9070 XT:

- `tools/art/check_fungal_caverns.gd`: **221 passing checks**, twelve captures,
  clean exit. Forty-eight generated maps/2,173 pieces: exclusions, sparsity,
  stable visits, unchanged map data, surface/UV contract, matched pit ground,
  live/still transitions and no added lights/colliders. Uses the existing Party
  camera/lantern. The labelled neutral review is brighter than live exploration.
- `tools/art/check_fungal_caverns_main.gd`: **23 passing checks**, six Main
  captures, including the same phone position before/after. Covers routing,
  exclusions, oil/time/strain/RNG independence, restore, custom/debug themes,
  other floors, phone safe areas and Normal/Larger text.
- Existing dressing, Continue/save and fortress checks pass (**64 assertions**).
  The gallery passes 26 browser checks. Continue initially
  failed during parallel renderer runs; unchanged HEAD and current code both
  pass when run alone. Run these legacy fixed-delay Main fixtures sequentially.
- [Isolated results](../art/concepts/fungal-caverns-v1/validation.json),
  [Main results](../art/concepts/fungal-caverns-v1/main-validation.json),
  [regressions](../art/concepts/fungal-caverns-v1/regressions.json).

Fixtures use ignored project-local saves and in-memory settings. The isolated
fixture exits cleanly; Main's existing shutdown warnings remain (1 CanvasItem
RID, 32 objects, 27 resources in this run). Physical iPhone appearance and
performance remain untested. Repeats remain visible in broad plain rooms.

The first tracking-issue creation was blocked by automatic approval review's
account usage limit; work is recorded under the related art issues and NOTES.md.
No alternative route was used to create that issue.
