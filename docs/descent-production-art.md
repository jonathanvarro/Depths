# Stonework, Underhound and Borrowed Pack — #166 / #168

The requested production batch is ready as standalone libraries. The owner's
positive feedback on the generated drawings is recorded; complete exported
poses remain available for paused review. No EnemyType, quest, room-event,
placement, combat rule, save or existing artwork was replaced.

[Offline inspector](../art/concepts/descent-production-v1/inspector.html) includes
native128 and 64px pose comparisons, explicit stepping/play, the stonework's
separate pulse, light/dark backdrops and 52 actual renderer captures.

## Ancient stonework

`res://art/props/ancient-stonework-v1/scene.tscn` contains a 192px stone drawing
and a separately aligned sparse mineral pulse. The worn asymmetric grooves
and lower palm-polished depression imply ancient handling without assigning a
language, religious emblem or a visible creature. Its visible slab is 1.75m
high and about 1.1m wide. Root is floor-centred; local +Z faces the viewer. Place
it about 0.025m in front of a real wall, on a dry ledge, with the entire frame
inside one 2m cell. It is a fixed shaded sprite, not a billboard or a new doorway.

For `quest_stonework.tres`, Claude can assign `prop` and `prop_on_wall=true`.
Keep the existing choice, reservoir/touched flag and vision sequence authoritative;
the artwork does not trigger or resolve anything. Preserve floor-six placement
and return/restore handling. The vision still is separate #168 work.

The optional second sprite has no shadow, particle or added light. It modulates
a sparse blue-grey mineral mask between alpha 0.035 and 0.12 over eight seconds.
`set_motion(true)` enables this pulse; default is still at its faint minimum.
`set_motion(false)` restores that fixed phase. `set_effects(false)` hides the
overlay completely for reduced effects. Pass the current preference on creation
and when settings change; there is deliberately no Settings or world-light
dependency in this asset. Visibility pauses phase progression. Source mineral
marks remain in the stone even with the mood layer removed.

## Underhound sibling family

`res://art/enemies/underhound-v2/scene.tscn` has six distinct one-drawing states:

| State | Gesture |
|---|---|
| `idle` | Approved low weight, high rib arch, blind closed muzzle |
| `attack` | Existing open-maw ordinary bite |
| `hurt` | Approved recoil and lifted forepaw |
| `windup` | Braced shoulders, tense inner ribs and jaw extended before the lunge |
| `lunge` | Lowered arch, extended legs and broad open hinged maw; no tongue projection |
| `defeated` | Collapsed sideways, limp limbs and resting head |

The first three PNGs are byte-identical to `underhound-v1`. That entire older
family, approval record, exporter and earlier gallery remain untouched. The
sibling avoids the older exporter erasing the new coverage. It shares the
approved 32-colour palette, native128 canvas, `(64,120)` pivot, fixed sprite
position and `pixel_size=0.8/89`. Every new pose uses the same original source
window, not a bounding-box fit. The lunge deliberately lifts off the contact
band; the defeated source settles several pixels below the pivot. Do not snap
each state back onto a new baseline during playback. The registered defeated
source is a retained ImageGen edit; nearby rendering changed slightly, so it
is not described as a pixel-identical translation.

## Borrowed Pack family

`res://art/enemies/borrowed-pack-v1/scene.tscn` has distinct `idle`, `attack`,
`hurt`, `off-balance` and `defeated` drawings. The three blind heads are joined
by a single broad hide with stretched neck bridges and grouped supporting legs.
Native128, one 32-colour palette across all poses, binary alpha and one common
full-source transform determined from idle. One scale and `(64,120)` pivot are
fixed in its scene. Recoil raises the middle head and folds a forefoot; attack
opens all three maws; off-balance drops a limp centre head between two alert
outer heads. Defeat flattens the whole connected body rather than removing heads.

Off-balance is a transient head-loss gesture, not a full persistent head-count
sprite system. There are no separately targetable head layers or every
permutation of one/two dead heads. Keep the live shared health and head-count
rules authoritative; do not infer additional enemies or separate bodies from
the illustration. At 64px, silhouette and three neck masses carry identity;
individual teeth and smaller feet are quieter. Larger phone recoil retains
clearance under the actual name/intent tag.

## Claude hookup

The production scenes expose an AnimatedSprite3D named `Sprite` with idle,
attack and hurt for the existing scene contract, plus the new named states.
Idle loops; other states are single non-looping drawings at 8fps. Pose-aware
bounds use the existing mounted tag-headroom helper. No aliases were used.

Current `CombatScreen._rest_pose()` has no LUNGER/HYDRA mapping, ordinary
attacks play `attack`, and defeat fades a sprite without selecting `defeated`.
Hook up windup/lunge/off-balance/defeated explicitly during Claude's presentation
work; the hound's `windup` identifier differs from the older brute's `wind-up`.
Do not change rule timing to accommodate the art. Replace current borrowed
breach-hound scenes only when connecting the complete sets. Their placeholder
EnemyType tint/scale currently distort reused art: reset or deliberately review
them with these authored scenes, rather than stacking 1.35 scale or coloured
tint automatically. Keep AI, rewards, encounters and sound independent.

## Provenance and validation

All eleven returned ImageGen masters are copied unaltered into
`art/source/descent-production-v1/`; `.gdignore` excludes source/review art
from import. `lineage.json` records every original filename and reference role.
Exact prompts are in `prompts.json`, `additional-prompts.json`,
`registration-edit.json` and `pack-registration-edit.json`. A tool-host restart
lost the first defeated-Pack result; the identical prompt was rerun. No CLI/API
fallback was used. Initial higher-floating defeated studies are retained beside
their selected registration edits. `generation.json` pins all retained masters,
native output bounds/hashes, fixed transforms and old hound hashes.

The builder thresholds alpha, resamples and quantizes without dithering.
Invisible RGB is zero. Stone retains source aspect within a 192px canvas and
uses 48 visible colours; the pulse selects only bluish mineral pixels within
that silhouette. It is a separate presentation layer, not generated new stone.
No faces, limbs or source silhouettes were procedurally painted.

Checks completed:

- 93 source/export checks: original copies/hashes, approved hound preservation,
  native canvases, palettes, hard alpha, margins, unique states, common transforms
  and pulse containment.
- 44 headless resource checks: complete states, fixed node origins, tag headroom,
  world shading/filtering and explicit pulse/still/effects controls.
- 173 Underhound and 146 Pack renderer checks, with 24 and 20 real combat captures
  respectively at 1280×720 / 1278×590, Normal/Larger text. Actual BattleStage,
  CombatScreen and a Mara PartyCard; existing hound numbers copied in memory
  solely for UI review, no Main or player save/preferences loaded.
- 14 stone renderer checks with 8 captures: still/peak/off/dim at both sizes,
  fixed still-mode pixels and a visible independent overlay. Actual wet walls,
  matched floor/ceiling and existing sluice provide context. Logs/shutdown clean.
- 83 headless Chrome checks: paused frame identity and clearing, playback/pause,
  exact scale choices, off/still/peak pulse, all 52 captures decoding and
  responsive review at 1280/844/390px with touch-size controls.

All screenshot processes were hidden and off-screen to preserve the owner's
no-focus-stealing preference. The combat fixture covers one hero; full-party
Larger layouts, physical iPhone performance and live placement remain separate.
Family-review pixel data is small; this is not a measured mobile frame-rate claim.

Rebuild: `tools/art/build_descent_production.py`. Validate with
`validate_descent_production.py`, headless `check_descent_library.gd`,
`check_descent_combat.gd` (add `-- --pack` for Pack),
`check_ancient_stonework.gd` for renderer captures, then rebuild the inspector
and run `check_descent_production.cjs`. Renderer fixtures need the actual
renderer and must be launched hidden/off-screen, not as routine visible tests.

The next creature batch is Marrow Shepherd plus unfinished hound (#166).
Reservoir surfaces, flow gate, vision, ending and exposed stairs remain #168.
