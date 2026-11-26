# Rat and bat adversarial-review follow-up (#292)

The owner selected all six review recommendations on 2026-11-24. New live
assets are in `art/enemies/creatures-refined-v2`; earlier libraries are retained.

1. First-person field combat now eases the camera down to keep floor-level
   rats and landed bats above the action controls. It fits the current pose's
   envelope and accounts for taller visible neighbours. FOV widens only when
   necessary (maximum 88 degrees); pitch is bounded. Exploration restores its
   exact previous camera. Tactical board and dark-stage cameras keep their
   existing authority. Creature cells, origins, reach and movement never shift.
2. Bat membranes cup in depth. Separate shoulder, elbow, wrist and finger
   joints fold them; shared station weights keep colour-boundary seams closed.
3. Bat head has recessed ears, brow, small eyes, nose leaf, teeth, hinged jaw,
   hooked thumbs and feet. Flight, swoop, landed and bite remain distinct.
4. Rat has a fuller muzzle, small eyes, rounded pads, incisors, toe/claw paws
   and a curved thinner tail. Source rig and animation roles remain.
5. Great rat has a heavier shoulder/hump silhouette and low bristle fans in
   place of pebble-like dorsal details. Old Whisker uses the same revised base
   with her ash coat and fitted uneven whiskers/scars; the obsolete detached
   ear patch/high mane is removed in the new copy.
6. Vertex colours and per-surface shaders distinguish rough fur, smoother
   skin, eyes/claws and opaque curved membranes. Fine restrained fibres replace
   stone grain. One soft contact plane adds grounding without extra lights.

## Asset and animation contract

| Model | Triangles, excluding contact plane | Bones | Skinned draws |
|---|---:|---:|---:|
| Rat | 2,876 | 21 | 3 |
| Great rat | 2,918 | 21 | 3 |
| Cave bat | 1,226 | 13 | 4 |

Whisker's small rigid muzzle details add 144 triangles in one draw.
Every model retains a constant metric floor origin, +Z front, a 2m tile
envelope (with conservative animation tolerance), `play`, `sample` and exact
`set_motion(false)`. Each surface owns its material instance; `set_opacity`
supports the existing ambient wildlife fade. Ambient animals suppress contact
ink; combat contact is restrained and uses no new light or collision node.

Rat clips: idle, attack, hurt, fall, walk, run at their existing durations.
Bat clips at 24fps: idle/landed/fall/fall-ground 24 frames (1s),
attack/swoop/bite 18 (0.75s), hurt/hurt-ground 12 (0.5s). Grounded hurt/fall
are selected only when already landed. Swoop, bite and grounded hurt return
to landed; grounded fall remains down. The external combat intent/API remains
unchanged. Live tag clearance follows each pose's height.

`rat.tres`, `great_rat.tres`, `cave_bat.tres`, Old Whisker's model mapping and
mine wildlife select these assets. Enemy numbers, tactics, encounter counts,
rewards, sounds and saves are unchanged. The tutorial's intentionally separate
starved-rat sprite and the Settings sprite fallback remain intact.

Source/rights and adaptation details: the new library's `CREDITS.md`; the
retained br-n518 source is CC0. No private character assets are involved.

## Review and validation

Local gallery: `E:/GitHub/Depths/build/local-creatures-refined-v2/inspector.html`.
It contains untouched baseline captures, new neutral studio angles/poses and
actual native Mobile first-person phone-shape captures. Editable masters live
beside it in `masters`. Captures use the isolated private-desktop launcher;
the owner's windows, input and saves are not used.

`tools/creature_refinement/check.gd` passes 1,132 checks, evaluating imported skin across
nine samples of every clip: finite bounds, floor/tile registration, declared
envelopes, loop seams, bones, triangle budgets, material ownership, exact still
mode, opacity and grounded reactions. Real field encounters test 1280×720,
1278×590, 844×390 and 667×375, Normal/Larger interface scales and simulated
safe areas, plus mixed rat/goblin framing and board/exploration restoration.
`review.gd` captures neutral angles and real encounters. The existing
`enemy_models_check.gd`, `mine_life_check.gd` and
`animation_smooth_check.gd` cover integration, fallback and animation APIs.

These are desktop native Mobile-renderer checks. Physical iPhone performance,
touch/comfort and owner likeness/style acceptance still require owner review.
The higher triangle/material count is recorded for that assessment; no device
performance claim is implied by passing desktop checks.

Rebuild from an existing local rat master:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python tools/creature_refinement/build.py -- --sources E:/GitHub/Depths
```

Use Godot 4.7.2 headless `--import` after rebuilding. Run native checks through
`tools/testing/background_godot.py`, passing `--script
res://tools/creature_refinement/check.gd -- <absolute-output-folder>`. Generate
studio images the same way with `review.gd`, then run `gallery.py --review
<review-root> --baseline <rat-bat-review-root>`. Do not run GPU checks on the
interactive desktop.
