# Damp Caves creatures — #302 I

Four concepts were explicitly approved for modelling in chat on 2026-11-26.
Unchanged generated turnarounds, exact prompts, reference roles and hashes are
retained in `art/concepts/damp-creatures-v1/generation.json`. These are original
concept-based models, not downloaded anatomy or private character derivatives.

| Scene | Triangles | Bones | Skin draws |
| --- | ---: | ---: | ---: |
| pale-newt.tscn | 2064 | 24 | 3 |
| blind-crawler.tscn | 1726 | 24 | 2 |
| leech-swarm.tscn | 1800 | 25 | 2 |
| drowned-mother.tscn | 2362 | 24 | 3 |

Each adds one optional two-triangle contact plane. No lights or collision.
Metric floor origin, +Z front, fixed floor registration and a declared animated
envelope within a two-metre tile. Use the wrapper, not the naked GLB: it supplies
materials, loop/terminal behavior, fade support and framing bounds.

## Presentation API

- `play(clip)` uses the existing AnimTidy adapter and cross-fades.
- `sample(clip, seconds)` pauses at an exact time; the argument is seconds.
- `set_motion(false)` selects a readable exact still pose and stops animation.
- `set_opacity(a)` selects a cached/preloaded fade shader only below full
  opacity; 1.0 restores the exact opaque shader. Normal biology **never writes
  ALPHA**. Thin-looking skin comes from muted pigment and restrained sheen.
- `framing_bounds()` returns the union of all registered clip AABBs, so both
  ends of a cross-fade fit without a camera-bound jump;
  `metadata/visual_height` and `tag_clearance()` support existing presentation.

Common 24 fps clips: idle 2s, attack .75s, hurt .5s, fall 1s, walk 1s and run
2/3s. Newt/Mother add rear, submerge and emerge (1s). Crawler adds grab/release
(1s) and hold (1.5s loop). Swarm adds spread, regroup and burn (1s).
Idle/walk/run loop. Grab finishes into hold, release returns idle; fall and
submerge hold their last frame. Mother shares the newt's rig and clip roles,
with a separate heavier shape, scar, curled tail and attached flank leeches.

Submerge compresses the visible body beneath a **caller-provided pool surface**
while retaining floor registration. It does not hide a combatant, grant
untargetability or create water. The caller owns visibility, targeting, map
glow, patrol, encounter makeup, loot, damage and all other rules. Do not assign
the Mother a body light merely because named packs glow on the map.

The shader reads physical local coordinates and vertex colour; it does not
sample a palette atlas. Keep the opaque/fade distinction from #297. Existing
creatures and live enemy resources remain untouched.

## Sources and rebuild

Geometry and clips are original, using the existing project `Mesh` accumulator,
armature and per-key floor-fitting helpers in `tools/combat_roster` and
`tools/creatures_3d`. An examined CC0 crayfish scan on Sketchfab was unavailable
(403); it was **not downloaded or used**. No third-party rights are inferred
from search metadata. No external animation, private base body or named likeness.

Build with Blender 5.2 in background using
`--python tools/damp_caves/build_creatures.py -- --workspace E:/GitHub/Depths`,
then `python tools/damp_caves/prepare_creatures.py`. Blender version is a tool
version; the game remains Godot 4.7.2 Mobile. Editable separate masters stay
local in `build/local-damp-creatures-v1/masters`; they are never live imports.

Import headlessly, then run `tools/damp_caves/creatures_check.gd` through
`tools/testing/background_godot.py` on an isolated desktop/profile, with arguments
`<capture-folder> damp-creatures-v1`. It measures actual imported skin, joints,
clip seams, floor/framing, budgets, still mode, fade restoration, pose state
transitions and desktop/three landscape-phone silhouettes. Native review is
`build/local-damp-creatures-v1/inspector.html`. Physical iPhone performance,
owner style review and live/exported combat integration remain unverified.

Eight matching original SVG contours live in `art/ui/damp-creatures-v1`, and
eight hurt/death sounds in `audio/damp-caves-v1`. Catalogue records exact paths,
hashes, bounds and clips. See `docs/damp-caves.md` for the complete handoff.
