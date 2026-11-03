# Female chair transition follow-up · #215

2026-11-02. The owner uploaded female `Sit To Stand.fbx` and re-uploaded
`Stand To Sit.fbx`. Both are retained separately from the earlier 27-file batch:
`build/local-blender-kit-v1/animation-requests-v1/female-chair-intake-v1/`.
No Drive files or earlier local masters were replaced.

Review: `review/inspector.html` in that folder. The saved editable candidate is
`female_chair.blend`; independent full-kit/garment exports are in `exports/`.
It contains the original Dying Action/slot and two new transition Actions.
The pack idle/walk and conversation candidates remain in their earlier review.

## Findings

- Both clips are 60fps with all 65 female joints, matching her original bone
  lengths/hierarchy. Mixamo still rebases rest orientations; direct Action
  assignment is unsuitable. Source-world conversion preserves the original
  body, UVs, weights, bind/rest rig, garments and animation timing/root curves.
- Sit-down is frames 1–135 (2.233s); stand-up is 1–136 (2.250s).
- The re-uploaded sit-down has different bytes but identical world-joint poses
  at the audited start, middle and end. This is sampled motion equivalence,
  not a claim that the two entire FBXs are identical.
- Sit-down end and stand-up start have similar posture: head/hips and left
  lower leg/foot differ by less than 0.8°, right lower leg about 3.7°, right
  foot about 5.8°. Some finger joints differ more (maximum about 16.3°).
  Hips-aligned maximum joint-position difference is about 0.076 source units.
- Their raw hips positions differ by about 1.074 source units. A scene/controller
  must explicitly align clip placement before chaining; the source curves were
  not edited to hide this jump. No seamless blend, seat/floor contact or loop
  acceptance is claimed.
- **A quiet female seated hold remains missing.** Neither transition supplies
  the period spent resting. The existing Sitting Talking is still a separate
  crossed-leg conversational pose. Obtain a quiet upright chair hold on the
  female body, judging its preview against these transition endpoints rather
  than its filename alone. No new custom hold was synthesized.

## Checks and next step

Two converted motions preserve sampled source-world joint positions within
0.000012 source units, with zero measured limb-axis error at diagnostic precision.
158 independent export/reimport checks and 8,517 actual Godot 4.7.2 Mobile checks
pass, including three retained motions, 11 surfaces and native skin bakes.
Maximum exported motion error is below 0.00010 source units. There are 18 actual
Blender captures (two transitions × three times × three angles) and an actual
Godot import render. 92 integrity checks preserve the two intake files, earlier
27-file batch, original 39 sources, garment master and reviewed candidate/export.
The generic checker also passes the earlier two-body/five-motion native case
(14,417 checks), so its defaults remain compatible. Physical-iPhone performance
and final owner animation approval remain untested.

The next production step is the complete #214 wardrobe review using the chosen
pack idle/walk, sit-down, matching seated hold, stand-up and original Dying:
switch garments on/off, pause difficult frames, then assess contacts, loops and
whole transitions at desktop and phone sizes. #214/#215 remain open. The older
interactive reviewer is unchanged; these new files are a separate candidate.
No live camp, portrait, equipment, movement or save bindings changed.

Reproduce with Blender 5.2.3 (`--python-exit-code 1` before `--python`):
`review_female_chair_intake.py -- --build --capture`. Connector-materialized
inputs and source metadata must already be present. The tool audits before
building and refuses to replace a manually edited candidate. For native checks,
use `prepare_received_smoke.main(fits=('female',), motions=3,
capture_clip_contains='stand_up')` with its `OUT` and `TARGET` pointed to this
isolated intake folder; import/run the resulting Godot project. Finish with
`package_chair_intake.py`. All models, source manifests, captures and animation
data stay in ignored local output; only tools and non-asset docs go to Git.
