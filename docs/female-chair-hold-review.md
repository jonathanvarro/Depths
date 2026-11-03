# Female chair hold candidates · #218

2026-11-02, Claude. The owner uploaded two seated clips on the female body to
`Animation Requests - Depths/Base Female/Downloads/`: **Sitting.fbx** and
**Sitting Idle.fbx**. Both are copied unchanged to the ignored
`build/local-blender-kit-v1/animation-requests-v1/female-hold-intake-v1/`,
with Drive IDs and SHA-256 in its `source-manifest.json`. Earlier intakes,
masters, assembly-v2 and the Drive files are untouched.

They are compared with the female chair transitions from
[the transition review](female-chair-transition-review.md): the last frame of
Stand To Sit (sit-down) and the first frame of Sit To Stand (stand-up).

**Owner decision (2026-11-02): use Sitting.fbx as the female chair hold.**
Sitting Idle stays in the intake as a retained alternative, not in use.

## Findings

Both: 60fps, all 65 female joints, bone lengths/hierarchy match her body
(relative length error below 0.00002). Legs never cross in any sampled frame
(every 10 frames). Each clip's last frame equals its first, so both loop
without a jump in pose or position.

| | Sitting.fbx | Sitting Idle.fbx |
|---|---|---|
| Length | 1–421, 7.00s | 1–179, 2.97s |
| Largest body movement (fingers excluded) | head turns up to 53°; arms/hands 20–30° | about 1° (breathing) |
| Hips drift during the clip | 0.015 source units | 0.0008 |
| Seat (hips) height vs sit-down end | −0.001 | **+0.096 higher** |
| Lowest toe vs sit-down end | −0.0001 | +0.0004 |
| Legs vs sit-down end | within 4–9° | knees ~18°, feet 11–15° |
| Arms/hands vs sit-down end | right hand 10°, rest ≤3° | hands 24–39°, shoulders 16–25° |
| Hips placement: sit-down end → hold start | 1.073 apart | 1.056 apart |
| Hips placement: hold end → stand-up start | **0.002 apart** | 0.102 apart |
| Hold end → stand-up start, worst joint | right hand 18° | right hand 35° |

**Sitting.fbx is the recommended hold.** It is upright, uncrossed, sits at the
same seat height with the feet on the same floor as the sit-down, and its legs
match within a few degrees. Its placement lines up with the stand-up almost
exactly. It isn't motionless: she looks around and shifts her arms, then
returns to the start pose, while the lower body stays still. That reads as a
natural seated idle rather than a held pose.

**Sitting Idle.fbx is the stiller alternative.** It barely moves, but it sits
about 0.1 source units higher with different knee and hand positions, so
chaining it to the transitions needs a visible blend or it will pop.

The sit-down's placement differs from both holds by about 1.07 source units,
the same offset already recorded between sit-down and stand-up. That is a
placement difference to align in the scene/controller, not a pose mismatch;
source curves are not edited to hide it.

## What is done and what isn't

- Done: source audit, comparison with both transitions, loop boundary, root
  drift, seat/toe height. Both clips converted from source world joint
  matrices into a new editable copy, `female_hold.blend`, made from the
  chair-intake `female_chair.blend` (body, rig, garments, Dying and both
  transitions unchanged). Converted joints match the source within 0.000008
  source units; actions `received.female.hold_sitting` and
  `received.female.hold_sitting_idle`. 16 actual Blender renders (front/side)
  are in `review/`, with `hold-comparison-sheet.png` putting sit-down end,
  both holds and stand-up start side by side. There is no chair prop, so she
  sits on air in the renders.
- Not done: independent GLB export/reimport and Godot native checks (the
  pipeline ChatGPT ran for earlier clips), adding the hold to assembly-v2,
  the explicit placement/blend for sit-down → hold → stand-up, hand/seat
  contact review, and owner style approval of the finished sequence.

Reproduce with Blender 5.2.3 from `E:/GitHub/Depths`:
`blender --background --factory-startup --python-exit-code 1 --python
tools/blender_kit/review_female_hold_intake.py -- --build --capture`.
It audits first, refuses to replace a manually edited `female_hold.blend`,
and never writes outside its intake folder.
