# Rat pilot, then shrine, well and cache (#252 / #251)

Owner requested this order on 2026-11-09. The new rat is a first review
candidate for #251's wider overhead combat library. The three event landmarks
complete another 3D conversion batch. Live resources, combat rules, placement
tables, event outcomes and named portraits remain unchanged.

Delivery branch: `codex/rat-landmarks-3d`.

## Review

Open `E:/GitHub/Depths/build/local-rat-landmarks-v1/inspector.html` for paused
render samples, fresh/resolved comparisons and actual combat-board captures.
`START_REVIEW.cmd` in that folder opens the isolated native Mobile review:
asset, camera, pose, light, state, Play, scrub and ± one 24fps frame. Turning
Play off retains the current pose/time. The Board view uses the live
TacticalView's 8m height, 3.4m setback and 50° perspective.

Local Blender masters retain the source rig/Actions and individual authored
landmark pieces under `build/local-rat-landmarks-v1/masters`. Source archives
stay in the repo because this rat is explicitly CC0; their extracted Blender
and XCF files are local in the review's `source` folder. No private body,
wardrobe or animation files are copied or uploaded.

## Rat contract

`art/enemies/rat-3d-v1/scene.tscn` is a floor-centred Node3D, front **+Z**.
The outer root is constant for every pose. One skinned surface, **270
triangles**, original **21 bones**, one lossless **128×128 / 32-colour** hide
plus the established world-space cave grain. Ordinary idle envelope is about
0.61m wide × 0.47m high × 1.66m long including the tail. All sampled clips fit
inside one 2m tile; callers should not add the old EnemyType sprite scale/tint
without review. Shadows are disabled on the small rat for phone cost/readability.

| Name | Duration | Behaviour |
|---|---:|---|
| idle | 0.667s | Loop; short source breathing/movement |
| attack | 0.667s | Source bite; returns to idle |
| hurt | 0.417s | Authored recoil from the idle baseline; returns to idle |
| fall | 0.667s | Source death, corrected to the floor; remains down |
| walk / run | 0.667s each | Optional in-place source cycles with added closing frame |

All clips are baked/imported at 24fps. Source walk/run ended on their last
unique sample (15); frame 16 now repeats frame 0 for a full continuous period.
The hurt begins at the same evaluated shape as idle. Source Actions and
constraints are preserved in the editable copy; glTF bakes the constraints.

The original fall crosses the ground. Derived Actions have sampled internal
root-height corrections and an 8mm skin-interpolation allowance, while the
outer floor origin stays fixed. Native checks evaluate skinned vertices through
the real skeleton and bind poses, including subframes for hurt. This is a
compact animation candidate, not a new physics/contact system.

Presentation API: `play("idle"|"attack"|"hurt"|"fall"|"walk"|"run")`,
`set_motion(enabled)`, `sample(pose, seconds)`. `sample` pauses exactly at the
requested time. Effects-off uses fixed poses (attack at 0.29s, hurt at 0.125s,
fall at its end), without time drift. Re-enabling motion restarts the current
pose. The `player` property exposes the imported AnimationPlayer for review.

**Integration remains caller work:** CombatScreen still assumes an
AnimatedSprite3D named Sprite. Do not point EnemyType.scene at this candidate
without adding model-aware dispatch for attack/hurt/fall, idle, fades, visual
height and facing. First-person encounter placement also adjusts sprite height
and setback to clear its action panel; the model should keep its feet on the
floor and use a deliberate framing solution. The rat is shown in both views
in the isolated fixture, but production animation dispatch is not changed here.
The current tags can partly cover the rat at distance; do not enlarge its mesh
to solve a tag/camera issue. Broader party/enemy coverage stays in #251.

## Landmark contract

`art/props/shrine-events-3d-v1/{defiled-shrine,fouled-well,buried-cache}.tscn`
uses a permanent Base and registered Fresh/Spent groups. Set `state="closed"`
for untouched, `state="empty"` for resolved. `open` aliases untouched because
these events expose only an unresolved/resolved outcome. `set_searched(bool)`
is also supported. `set_motion(bool)` is a no-op: all detail is intentionally
static. No world lights, collision, particles or added gameplay are included.

| Scene | Mount | Untouched / resolved | Visible triangles |
|---|---|---|---:|
| defiled-shrine | Existing real wall anchor, **floor-height origin**, +Z inward | Black stone obscures the smeared miner carving / disturbed fragments and moved candle stub | 1268 / 1308 |
| fouled-well | Floor centre | Uneven stone courses, split bucket, frayed rope and fouled water / separated scum and static disturbed rings | 1956 / 2628 |
| buried-cache | Floor centre | Royal-stamped crate trapped below fallen rock / empty interior, shifted rubble and broken lid alongside | 1297 / 1249 |

Shrine back sits at local Z≈0 and projects into the room, as the existing
miners' shrine does. Use `prop_on_wall=true` and Main's real wall search/yaw;
do not lift the root to the previous sprite's centre height. The generic
resolved shrine does not claim the player blessed it: break/touch/cleanse have
different rules but share one used-state flag today.

The well is an opaque inset surface over a dark bowl. It covers the existing
floor without cutting a hole, adding transparent sorting or assuming a flood
state. The resolved pool is still dirty; no automatic purification is depicted.
The cache's decorative empty interior does not enumerate actual loot.

Nine GLBs, each with one shared-palette surface; 25 authored colours in a
256×128 palette. Materials reuse the mine props' rough, low-specular,
world-space grain treatment. Current paintings and event resources are intact.
When hooking up, update `tools/story/build_shrines.gd` alongside event URIs so
a later rebuild cannot restore the old art.

## Sources

The [rat submission](https://opengameart.org/content/rat-0) by br-n518 explicitly
declares CC0. Exact archives, unchanged extracted Godot files and a saved
declaration page are in `art/third-party/oga-rat-v1`; SHA256 and sizes are in
provenance.json. `prepare_rat.py` pins the source archives and texture before
derivation. It reduces/recolours the hide without changing UVs or weights.
All other new geometry is authored using prior project helpers; sources and
changes are recorded in each asset folder's CREDITS.md.

## Validation and rebuild

Godot 4.7.2 Mobile: 951 isolated native checks, 150 renders, and 37 live
placement checks with 20 additional captures. Checks include native skin
envelopes/loop endpoints, hurt registration, root stability, floor clearance,
2m tile bounds, pause/still/return-to-idle, imported mesh bounds/UVs/budgets,
state visibility, actual wall anchoring and 44px controls at 1278×590,
852×393 and 667×375. The live fixture injects candidates at runtime and
preserves current resources. The focused review has no runtime errors or
shutdown leaks. The full game fixture retains the existing one CanvasItem /
two ObjectDB shutdown warning, tracked separately in #249.
Physical iPhone and owner visual acceptance remain open.
Source/artifact verification passes for five retained originals and ten GLBs;
the browser gallery passes 38 interaction/image/phone-layout checks.

From this checkout, use the installed Python, Blender and Godot 4.7.2 binaries:

1. Extract `art/third-party/oga-rat-v1/rat_source.7z` with `tar -xf` into
   `E:/GitHub/Depths/build/local-rat-landmarks-v1/source` (create it first).
2. `python tools/rat_landmarks/prepare_rat.py`.
3. Blender background, `--factory-startup --disable-autoexec --python-exit-code 1
   --python tools/rat_landmarks/build_rat.py -- --workspace E:/GitHub/Depths`.
4. Same Blender invocation with `build_landmarks.py`.
5. `python tools/rat_landmarks/prepare_review.py --workspace E:/GitHub/Depths`.
6. Godot `--headless --editor --import --quit` on the local review, then native
   `--script res://check.gd`. Run imports and renderer fixtures sequentially.
7. Import this checkout, then run native `--script
   res://tools/rat_landmarks/live_check.gd --
   E:/GitHub/Depths/build/local-rat-landmarks-v1/live`.
8. `python tools/rat_landmarks/package_review.py --workspace E:/GitHub/Depths`.
   Browser verification is `node tools/rat_landmarks/check_gallery.cjs` with
   Playwright on NODE_PATH. Editable masters/captures stay ignored under build.

Optional `audit_rat.py --workspace ...` (through Blender) records the source
hierarchy, modes, Action ranges and frame rate without editing it. Godot's
generated .import/.uid siblings accompany the assets and new scripts.
