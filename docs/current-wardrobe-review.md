# Current per-body wardrobe review · #214 / #215

2026-11-02. The editable kit and received-animation verification candidate are
ready for review. A calm female seated idle is not required to test clothing:
her existing seated conversation is clearly labelled as a stress test. Remaining
animation presentation work is [#218](https://github.com/jonathanvarro/Depths/issues/218),
alongside this kit/verification candidate and owner style acceptance. #214 and
#215 remain open because their final animation acceptance criteria are incomplete.

Open `build/local-blender-kit-v1/assembly-v2/review/inspector.html` for the gallery;
double-click `assembly-v2/START_REVIEW.cmd` for the interactive Godot review.
The older `assembly-v1` and all intake/base/garment masters remain unchanged.
All models, textures, animation data and captures stay local and ignored.

## What is ready

- Two editable Blender masters in `assembly-v2/masters/`, with separate tunic,
  belt, trousers and left/right boots, preserved source body/rest rigs and original
  Dying Actions/slots. `editable-inputs/` retains the source assembly copies.
- Two independent rigged GLBs with disjoint body regions. All 32 garment selections
  remove/restore exactly the original body faces, including after repeated switching.
- Each body has its own pack idle/walk, sit-down, seated and stand-up clips, plus
  its original Dying. Female seated is Sitting Talking; male seated is chair Sitting
  Idle. No legacy ground-sit fitting clip is substituted into this candidate.
- Mouse/touch body, motion, clothing, angle and portrait/full-figure controls;
  pause, seek, source-frame steps and keyboard endpoints. Playback uses original
  seconds/FPS and stops at the real end. Each matrix render samples its body's
  own start/middle/end; different clip lengths are not silently treated as equal.
- 181 actual Godot captures, including 24 native 96/192px cards, desktop and
  landscape-phone shapes, seven pose sheets and two actual-frame walk GIFs.
  GIF repetition is inspection convenience, not approval of source loop boundaries.

The male source fit exposed forearms through the initial sleeve surfaces and
calves/trousers through the boot shafts in bent poses. Only the new review copy
is refined: editable radial forearm sleeves add clearance, and calf shafts/cuffs
use deliberate lower-leg weights and cloth clearance, with matching tucked
trouser weighting. Source skin/UVs/body weights, skeleton/rest, Actions, female
garments and the earlier garment masters stay unchanged. These repairs were
checked in actual native rest, walking and seated/bent views.

| Full outfit | Triangles | Visible surfaces | Materials | Source joints |
|---|---:|---:|---:|---:|
| Female | 4,198 | 11 | 7 | 65 |
| Male, refined | 3,038 | 11 | 7 | 49 |

Female retains the exact embedded 1024² source skin pixels (4 MiB at RGBA8 base
level; GPU compression/mips excluded); male uses plain source materials without
textures. One common display wrapper gives approximately 1.70m/1.80m and fixed
rest-sole references. No body reshaping, new faces or live bindings are included.

## Verification and explicit limits

3,323 reopened Blender fit checks, 780 independent export/reimport comparisons
and 2,853 actual Godot 4.7.2 Mobile checks pass. The latter exercises real mouse/
touch/keyboard controls, exact coverage, native deformed surfaces, body-specific
times, captures and phone-safe layouts. Independent maximum deformation errors
remain below 0.00010 source units. Source rigs, full fingers, original Dying slots
and downloaded root/timing curves are preserved; no source assets were modified.
1,392 headless control/coverage, 460 source/export/capture integrity and 125
browser gallery checks also pass. Reports are beside the gallery. All 39 initial
sources, 27 first-batch files and two follow-up source copies remain unchanged.
Desktop phone shapes do not establish physical-iPhone performance.

The review candidate advances #214's matrix/engine handoff and #215's received-
clip verification with known incomplete choices visible. It does **not** complete
their final animation acceptance criteria; both issues remain open. #218 records
the remaining work without waiving those criteria:

- Female conversation is not a calm chair idle, and its crossed legs do not match
  the transition endpoints. No quiet hold or new custom animation was invented.
- Sit/hold/stand placement needs explicit runtime registration and possible
  blending/seat/hand work. Raw offsets remain visible; no seamless chaining is claimed.
- Both pack walks travel. Loop boundaries and any separately named in-place
  derivative remain unapproved; playback does not silently repeat them.
- Against fixed rest-sole references, sampled non-dying visible envelopes are
  about 0.005–0.015m above the floor. Original Dying still intersects it by about
  0.023m female / 0.021m male. This is not foot locking or proof of exact contact.
  Source curves and the fixed floor are not changed to hide these differences.

## Reproduce or continue

With the existing local intake available, run Blender 5.2.3 with
`--python-exit-code 1` before `--python tools/blender_kit/prepare_current_wardrobe.py`.
The assembly reuses exact verified Actions when source/rig/skin/master identities
match, and converts the new male stand-up using source-world matrices. The full
suite is independently exported/reimported. Manual edits to generated masters
are protected; choose another output version rather than overwriting them.

Import the isolated `assembly-v2` Godot project, then run `--script check.gd`
in native Mobile and headless modes. Native logs belong in `assembly-v2/native.log`
and `native-errors.log`. Reopen/fit checks use `check_garments.OUT` pointed at
`assembly-v2/editable-inputs`. Finish with `package_current_wardrobe.py`, then
`check_wardrobe_gallery.cjs build/local-blender-kit-v1/assembly-v2`.

Save a working copy before editing clothing in Blender. The source bodies/rest
contracts remain [the base contract](blender-base-contract.md); [the animation
catalogue](animation-library.md) records per-body status. No live camp/HUD/portrait/
equipment/save changes or new gameplay slots follow from these preview toggles.
