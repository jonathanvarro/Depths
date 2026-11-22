# Puzzle fittings and named elite leaders

Owner-selected order: puzzle props, then elite leaders (2026-11-22).
Delivery branch: `codex/puzzle-props-and-elite-looks`. Issues #281 and #282,
following the live puzzle and named-pack systems in #275 and #277.

Local review: `E:/GitHub/Depths/build/local-puzzles-elites-v1/inspector.html`.
It contains 81 actual Godot Mobile captures: isolated assets, open/closed
states, inherited poses, patrol and combat, plus phone-shaped viewports.
Editable separate-piece Blender masters stay in its `masters/puzzles` and
`masters/leaders` folders. The earlier model masters remain unchanged.

## Puzzle fittings

`art/props/puzzle-fittings-v1` supplies two doors, a wall-mounted lever and a
recovered key. Seven original static mesh exports share the existing
worked-prop material families: physical wood grain, worn iron, stone and brass.
The door has uneven separate planks, straps, rivets, pulls and a recessed
keyhole plate. The one-way bar is on the actual bolt face. The lever has
bearing blocks, a bound grip, a tally plate and interlocked chain links. The
key has a real open bow and separate ward teeth.

| Mesh | Triangles |
|---|---:|
| Door frame | 800 |
| Door leaf | 1,613 |
| Bar and keeper fittings | 516 |
| Lock plates | 140 |
| Lever base and chain | 2,168 |
| Lever handle | 364 |
| Recovered key | 382 |

`scripts/puzzle_props.gd` now instantiates these scenes and retains the original
corridor-axis, bolt-side, wall-offset and swing conventions. The existing
chain gate and CC0 seated skeleton are reused. The key's existing glint goes
away with the key; its light energy/range are unchanged. No new lights or
collision objects were added.

The prop API is `set_open(opened, animate=true)` and `set_motion(enabled)`.
State requests before tree entry are retained. Immediate restore and still
mode snap to the requested result; reversing a tween starts from its present
transform. Main/Puzzles still own interaction, solvability, reward and save
flags. The door frame stays stationary while its leaf swings on the original
hinge. `catalog.json` records exact bounds, material groups and export hashes.

## Elite leaders

`art/enemies/named-leaders-v1` contains five lightweight wrappers around the
**unchanged original animated GLBs**. Each gets a separate worn palette and
original rigid details attached to existing bones. There are no new bones,
skin weights, Actions or animation tracks.

| Leader | Original family | New identifying details | Added triangles |
|---|---|---|---:|
| Old Whisker | Great rat | Ash pelt, ragged ridge, long uneven whiskers, muzzle scars | 366 |
| The Pale Spinner | Webspinner | Chalk shell seams, dark joints, old silk bundles | 592 |
| Skarn | Goblin brute | Uneven shoulder plates, three spikes, red trophy cloth and teeth | 404 |
| The Hollow Foreman | Hollow miner | Battered helmet, cut tally plate, keys and belt lamp | 884 |
| Gristle | Breach hound | Crooked hide ridge, scar patches and broken restraint | 462 |

The wrapper extends the existing combat-roster actor. It samples idle t=0 to
bind details in metric actor space, then restores the requested pose. This
accounts for the different internal skeleton scales and rest poses; callers
may position/rotate/scale the actor or request a pose before adding it to the
tree. Attachments follow their bones during all inherited clips. Existing
AnimTidy cross-fades, held poses, still mode and equipment visibility APIs
remain available. The spider retains its 8×4 palette UV contract via an
explicit scale/offset into the new texture, including glTF's vertical flip.

`Elites.types(id)` gives only the first member a shallow private EnemyType
copy with the variant model. Both Main's patrol and combat use that method.
Followers remain their original shared resources. Sprite fallback still uses
the original art when 3D enemies are off. Pack names, stats, compositions,
spawn odds, patrol rules, marks, rewards and saved flags are unchanged.
The Foreman's belt lamp is geometry only; the existing pack glow owns light.

## Verification and limits

- 73 native puzzle-art checks: mounts in all wall directions, corridor axes,
  bolt faces, hinge states, reversal, pre-ready restore and still mode.
- Existing `tools/puzzles_check.gd`: 1,200 generated floors, solvability from
  both stairs, unsolvable-case detection and real key/door/lever/save flow;
  `fails=0`.
- 678 leader-art checks: original resource fields/followers, pose inventory,
  clip lengths/tracks, finite and bone-following transforms at beginning,
  middle and end of every clip, early pose requests, caller transforms and
  exact still mode; no failures.
- 60 real-game checks and captures: all five patrol variants, their existing
  pack lights, first-person combat leaders, desktop/phone shapes and models-off
  fallback; no failures.
- Existing `tools/named_elites_check.gd`: 2,000 seeded floor selections plus
  beaten-kind gating, elite marks/health, patrol, retreat and gold-hoard
  persistence; `fails=0`.

GPU review used Godot 4.7.2 Mobile on a private desktop, with an isolated
APPDATA profile. Every run reported no test foreground window and unchanged
foreground. Physical iPhone testing and owner visual acceptance remain open.
The existing combat action panel can cover part of a low creature at adjacent
range, especially on the smaller phone shape; screenshots preserve that
layout rather than hiding it for presentation. No global combat UI changes
are included here.

## Rebuild and provenance

Run Blender in background with `--factory-startup --disable-autoexec
--python-exit-code 1`, then `--python tools/puzzle_art/build_models.py --
--workspace E:/GitHub/Depths` and separately the equivalent
`tools/elite_art/build_models.py` command. `--workspace` selects the local
master destination; runtime exports go to the invoking checkout. Run
`python tools/puzzle_art/prepare_scenes.py` after the puzzle mesh build.

Use headless Godot import, then `tools/testing/background_godot.py` for
`res://tools/puzzle_art/check.gd`, `res://tools/elite_art/check.gd` and
`res://tools/elite_art/live_check.gd`, passing the local captures directory
after `--`. Rebuild the HTML with `python tools/puzzle_art/package_review.py
--output E:/GitHub/Depths/build/local-puzzles-elites-v1`.

The mine-polish builder's export block is now under `main()` so the puzzle
builder can reuse its mesh helpers without rewriting the earlier assets.
Its CLI export body is otherwise unchanged. No earlier GLBs, source archives
or palettes were regenerated. New catalogues and per-folder CREDITS files
retain hashes and the existing CC0 source chain; no new downloads were used.
