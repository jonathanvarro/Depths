# Marrow Shepherd, unfinished hound and flow gate — #166 / #168

[Paused production review](../art/concepts/shepherd-gate-v1/inspector.html).
This delivery is an independent asset library for Claude's hookup, with no
changes to current EnemyType definitions, combat rules, quests, flooding, saved
state, room placement or existing art. Owner review of this set remains open.

## Creature scenes

| Family | Scene | Native canvas / states |
|---|---|---|
| Marrow Shepherd | `res://art/enemies/marrow-shepherd-v1/scene.tscn` | 192px: idle, tending, birthing, attack, hurt, defeated |
| Unfinished hound | `res://art/enemies/unfinished-hound-v1/scene.tscn` | 128px: idle, attack, hurt |

The Shepherd retains the concept's wide connected bone cradle, sleeping blind
hounds, narrow flesh body, long arms and clawed legs. Tending cups a cradle
occupant; birthing opens the abdominal cavity around an emerging hound while
the upper cradle becomes empty. Attack is a hooked claw sweep, hurt a backward
recoil, defeat a collapsed cradle and folded limbs. The unfinished hound shares
the blind head and dusty flesh, with a thin body, uneven shoulder and blunt
tail; it snaps with sparse teeth and recoils with a raised foreleg. It is
smaller and lacks the adult Underhound's external ivory rib arch.

Both families share one 32-colour kinship palette selected from their idle
drawings. Transparent margins, hard alpha, nearest sampling and ordinary world
lighting match the existing production contract. Each animation contains one
distinct authored drawing at 8fps; only idle loops. Every pose uses one fixed
family source transform, scale, sprite position and bottom-centred pivot:
Shepherd `(96,180)`, hound `(64,120)`. No independent bounding-box fitting or
per-pose grounding is applied. Gesture changes retain their source placement,
including lifted support limbs and the collapsed body's slightly higher contact.

The Shepherd's idle envelope is 1.06m high and the hound's is 0.42m. The boss
retains its 192px drawing budget but has a conservative world height: taller
drafts let the cradle touch the current clamped name tag on landscape phone
with Larger text. The final height clears every pose in that layout. The
existing pose-bounds helper supplies 0.12m of additional tag headroom. Full-party
and multiple-foe arrangements are separate from this one-hero art fixture.

### Hookup

Point the two existing EnemyType scenes at these complete families when Claude
connects the art. Reset/review their placeholder `tint` and `sprite_scale`:
the Shepherd currently has scale 1.35 and the hound 0.75 for borrowed art.
Authored scale 1.0 / white tint is the checked starting point for these scenes;
automatically stacking the old adjustments would undo the readability check.
Damage, initiative, summons, AI, rewards and encounters remain authoritative.

Current CombatScreen has no SHEPHERD rest-state mapping and normally plays
`attack` for an action. Map `tending` / `birthing` to the existing summon intent
and resolution, and select `defeated` before the existing fade if desired.
Do not generate an extra hound from the artwork: the small creature inside the
birthing drawing is a visual cue, while CombatState owns the actual new foe.
The source art illustrates occupied cradles and one transfer; it does not
provide every persistent 0/1/2/3-charge permutation or independent cradle layers.
Remaining charges must continue to come from game state, not counting painted
occupants. Birth timing, the three-summon limit and its pause/restore handling
are unchanged. Neither source studies nor export creates an additional enemy.

## Reservoir flow gate

`res://art/props/reservoir-flow-gate-v1/scene.tscn` supplies closed/open native192
drawings using the existing visual container API:

```gdscript
gate.state = "closed" # lowered shutter, ready to haul
gate.state = "empty"  # raised shutter, resolved
```

Both work before or after adding the node. Same transform and silhouette in
both states. The hauling chains, slate uprights, rollers, header and threshold
are byte-identical outside the registered aperture `(50,37)-(142,168)`.
The raised shutter reveals opaque black water in an outflow throat, not a
transparent hole through the level wall or a new walkable route. The earlier
corridor-like open study remains as source provenance; the final master
replaces those receding ledges with dark water. No ripple shader, particles,
new lights, refraction or flowing-water simulation is added by this prop.

Full canvas is 2m wide, with the threshold registered to floor y0.015. Mount
root at floor height, about 0.025m in front of an actual wall; local +Z faces
the open cell. It is fixed and shaded, not billboarded. Keep the frame within
the wall cell and clear of neighbouring routes. For `quest_flow_gate.tres`,
use the scene and `prop_on_wall=true` when replacing the placeholder. Existing
"Haul the chains" wording matches this design; this gate has no handwheel.

Preserve the existing `drains`, `reservoir/diverted`, quest stage, extra time
and strain, floor-six remodelling, stairs reveal, day reset and save/restore
logic. Artwork swaps never drain the map themselves. The dark water painted
beyond the raised shutter belongs to the outflow throat; it does not declare
the party's cell flooded after the wing drains. Exposed stairs are separate
#168 artwork, not included in the aperture. No collision or navigation added.

## Exact sources and rebuilding

Twelve returned built-in ImageGen masters are retained unaltered in
`art/source/shepherd-gate-v1/`. Each `<id>-prompt.txt` contains its exact prompt,
and `<id>-original.txt` the returned original filename. `generation.json`
records original paths, source/output hashes, reference paths/hashes, shared
transforms, palette/export contracts and gate registration. Pose edits reference
their own idle master; gate opening references closed, with a second local edit
for the black-water interior. No CLI/API fallback was used. Existing concept,
Broodmother and Underhound reference files remain unchanged.

`tools/art/build_shepherd_gate.py` thresholds alpha before resampling, maps to
the fixed idle palette without dithering and zeroes invisible RGB. Some raw
masters contain bright fringe RGB at alpha 1–5; the ordinary hard-alpha export
removes that near-transparent fringe rather than painting it into the sprite.
Boss and hound keep their separate native budgets. The gate shares 48 colours
across both states; export copies only the generated open-aperture rectangle
onto the closed frame, so the surroundings cannot wobble. The rest of that
open source remains intact in provenance. No anatomy is procedurally redrawn.

Source and review folders have `.gdignore`; runtime PNGs, scenes, frames and
editor import metadata are separate. The inspector is generated from
`art/concepts/shepherd-gate-v1/layout.html` with embedded native PNGs.

Checks completed:

- 95 source/native checks pass: originals/prompts/hashes, unchanged references,
  dimensions, 32-colour kinship palette, 48-colour gate palette, hard alpha,
  margins, distinct drawings, fixed transforms and exact surrounding gate frame.
- 39 headless resource checks pass: complete animation sets, fixed origins,
  pose-aware tag clearance, shading/filtering and gate state before/after ready.
- 173 Shepherd renderer checks with 24 actual combat captures, plus 92 hound
  checks with 12 captures, at 1280×720 / 1278×590 and Normal/Larger text. All
  drawings held independently in actual BattleStage/CombatScreen with Mara's
  PartyCard; existing hound numbers copied only in memory, not proposed tuning.
- 13 gate renderer checks with 10 first-person views: closed/flooded and
  open/drained demonstrations at near/far distances, plus dim views, using
  existing wet walls and matched surfaces. No live flood flags touched.
- 82 headless Chrome review checks pass: exact paused drawing identity,
  clear/step/wrap, play/pause, native/half/double scale, all 46 captures decoding
  and responsive 1280/844/390px layouts with 44px controls.

Final renderer logs and exits are clean. Screenshots used hidden off-screen
processes to preserve the owner's no-focus-stealing preference. No Main,
player saves or disk preferences loaded. Physical iPhone, full-party/multiple-foe
Larger layouts and the live combat/event hookup remain separate verification.

Rebuild with `build_shepherd_gate.py`; validate with
`validate_shepherd_gate.py` and headless `check_shepherd_library.gd`.
Renderer fixtures: `check_shepherd_combat.gd` (add `-- --hound` for the small
hound) and `check_reservoir_gate.gd`, launched hidden/off-screen. Rebuild the
inspector after captures and run `check_shepherd_review.cjs` headlessly.

Remaining #166 work includes intent/status symbols and live hookup. Reservoir
surfaces/open-water treatment, vision/ending and exposed stairs remain #168.
