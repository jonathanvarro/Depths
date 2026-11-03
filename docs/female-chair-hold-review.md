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
- Done in assembly-v3 (below): engine export/checks, wardrobe review and
  the sit-down → hold → stand-up placement.
- Not done: a crossfade at the joins, hand/seat contact review against a real
  chair, walk/idle loop decisions, and owner style approval.

Reproduce the intake with Blender 5.2.3 from `E:/GitHub/Depths`:
`blender --background --factory-startup --python-exit-code 1 --python
tools/blender_kit/review_female_hold_intake.py -- --build --capture`.
It audits first, refuses to replace a manually edited `female_hold.blend`,
and never writes outside its intake folder.

## Assembly-v3: wardrobe review with the hold and a chair sequence

`build/local-blender-kit-v1/assembly-v3/` is a new copy of the current
wardrobe review. assembly-v2 is unchanged. Open `review/inspector.html` for
the gallery, or double-click `START_REVIEW.cmd` for the interactive Godot
review. Everything in it stays local and ignored.

- **Clips:** the same as assembly-v2, except the female *Seated* motion is now
  the chosen hold (`Sitting.fbx`, 1–421) instead of Sitting Talking. Male
  seated stays chair Sitting Idle.
- **Chair sequence:** a new review motion that plays sit-down, seated and
  stand-up back to back for each body. At each join the reviewer moves the
  whole model sideways so the hips continue from where the previous clip
  ended. It never moves her up or down, so the floor stays fixed and any
  seat-height difference stays visible. The source curves are unchanged.
  This placement is the reviewer's (`wardrobe_actor.gd`, `align_sequence`),
  which is the pattern a game scene would follow.
- **Measured joins** (source units; one unit ≈ 0.44m at display scale):

  | Body | Sit-down → seated | Seated → stand-up |
  |---|---|---|
  | Female | shift 1.073, height gap 0.0013 | extra shift 0.0006, height gap 0.00001 |
  | Male | shift 0.906, height gap −0.0011 | extra shift ~0, height gap 0.00001 |

  The second join's total placement is about the same as the first because
  the hold ends where it started; only a tiny extra shift is needed. After
  alignment the hips continue exactly (residual 0). The remaining
  difference at joins is pose: mostly the right hand (female ~10° into the
  hold, ~18° out of it), which shows as a small snap without a crossfade.
- **Checks:** 778 independent Blender export/reimport checks (largest
  deformation error below 0.0001 source units), 3,273 native Godot 4.7.2
  Mobile checks and 1,404 headless checks, 514 artifact/lineage checks, all
  passing with no script errors. 215 actual captures, including 16 frames
  either side of both joins (`chair-sequence-joins-sheet.png`). Seated and
  sequence frames keep a 0.011–0.015m visible gap above the floor; that
  is the source pose, not foot locking. The gallery was checked in the
  built-in browser (every capture loads, all links resolve, no overflow);
  the Playwright gallery script wasn't run because Playwright isn't
  installed on this PC.

### Owner review (2026-11-02)

The owner watched the chair sequence: "quite smooth", no visible jump or pop
at either join, and the clothing "looks great". So no crossfade is needed for
now. They noticed **her arm passing through her leg**. Measuring the female
master (hand/forearm and sleeve points against the trousers, every second
frame; renders `review/arm-leg-*.png`):

- **Correction:** a first measurement reported fingertips ~0.015 inside the
  trousers while seated and ~0.05 at stand-up frame 105. Those came from a
  faulty inside test (one sleeve point 0.1–0.2 away from the cloth was
  counted as inside). The corrected test (`review/arm-leg-intersections-v2.json`)
  only counts a point as inside when it lies behind the nearest surface.
- With the corrected test, no hand or finger point enters the trousers or the
  thighs in sit-down, hold or stand-up. Only the tunic sleeve touches the
  trousers, by up to ~0.006 source units (~3 mm on screen).
- So the clipping the owner saw is not yet located by measurement. The next
  step is for the owner to name the motion, moment and view (and whether
  clothes were on) so it can be measured there.

A hand-lift correction (`tools/blender_kit/hand_lift.py`, local and not yet
used) is ready for when the real contact is found.

Rebuild: Blender `--python tools/blender_kit/prepare_wardrobe_v3.py`, copy
the updated `wardrobe_actor.gd`/`wardrobe_review.gd`/`check_wardrobe.gd` in
as `actor.gd`/`review.gd`/`check.gd` if `prepare_wardrobe` copied older
ones, import the project in Godot, run `--script check.gd` native and
headless, then `python tools/blender_kit/package_wardrobe_v3.py`. The shared
reviewer scripts gained the optional sequence support, so assembly-v2's
stored copies no longer match the tools byte-for-byte; rerunning v2's
validation would flag that, but v2 itself is unchanged.
