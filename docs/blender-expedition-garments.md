# Editable expedition garments · #211–#213

2026-11-02. Local review:
`build/local-blender-kit-v1/garments-v1/review/inspector.html`.
The two editable masters are `female_garments.blend` and `male_garments.blend`
in that same `garments-v1` folder. They contain separately named/fitted tunic,
belt, trousers, left boot and right boot objects on the actual #210 rigs.
Original sources, base masters, named faces and all live game resources remain
unchanged. Models, textures, animation data, exports and captures stay LOCAL.

## Design and interfaces

- **Tunic:** muted work-cloth, long sleeves cut at each body's actual wrists,
  modest neck, editable finished thickness and front/back split gores. The
  gores blend hips/upper-leg weights to clear the lap; this is independent
  geometry rather than recolouring a body. No padded jacket or cloth simulation.
- **Belt:** a separate leather ring and plain iron frame buckle. It sits outside
  the fitted tunic at the shared waist interface. Buckle and leather are one
  logical preview piece, with separately editable meshes/materials.
- **Trousers:** dark cloth with waist/seat/leg shapes, editable thickness and a
  continuous weighted crotch gusset. A direct nearest-body transfer initially
  stretched the female crotch in dying; the smooth hips/left/right blend fixes
  that without altering body geometry or source skin weights.
- **Boots:** individually named left/right mid-calf pairs, source-fitted shaft
  and foot, flared cuff and a closed shaped sole/welt. Shaft/ankle/foot/toe skin
  regions remain distinct; the whole boot is not attached to one foot bone.
  Trousers have three actual taper rings to fit inside the shaft. The shaped upper welt overlaps the leather
  arch/heel, avoiding a floating flat sole.

The original `fit_id` values remain `female-v1` / `male-v1`; see the
[base contract](blender-base-contract.md). A fit is not a uniform-scale copy.
Geometry, transferred weights, editable Solidify→Armature modifiers and exact
generation parameters/provenance are retained in the masters/manifests.

| Raw source-space interface | female | male |
|---|---:|---:|
| Tunic neck |3.09622|3.14224|
| Tunic hip opening |2.23061|1.99087|
| Tunic hem |1.80061|1.56087|
| Belt centre |2.35561|2.11587|
| Trouser waist |2.40061|2.16087|
| Boot cuff |0.67708|0.71540|
| Rest sole bottom |−0.09383|−0.09824|

These retain the source's approximately3.8/4.1-unit body heights and original
rig/object transforms; they are not silently resized human-height assets.
Body dimensions and feet offsets are already documented in #210. The floor
shown in boot details is a review-only plane at the outfit's rest sole level,
not an animation/root-motion correction by the footwear.

Shared garment materials are `cloth.tunic`, `cloth.trousers`, `leather.belt`,
`leather.boots`, `leather.sole`, `iron.buckle`. The current simple matte palette
is a candidate for owner review, not a newly approved game art direction.
The female source skin's redundant alpha connection is disconnected only in
the clothing copies: its original texture is fully opaque. This fixes glTF
transparent self-sorting artifacts in Godot, with every source RGBA pixel
verified unchanged. It is a material-depth repair, not face painting.

## Reversible coverage and removal

The full original body still exists in each `.blend`, with its vertices, UVs,
faces, original bone weights, bones and rest matrices unchanged. `cover.tunic`,
`cover.trousers`, `cover.boots` and side-specific `cover.boots.left/right`
groups define removable regions. `coverage.keep` drives a non-destructive Mask
before the original Armature modifier. Coverage retains the incident boundary
faces, so a long source triangle cannot cut the torso above a trouser waist.

`wardrobe_visibility.set_pieces()` recomputes coverage from the visible logical
pieces. All32 combinations are checked on both bodies; removing everything
restores the entire source body. The belt has no independent body mask. Group
weights are recomputed, not accumulated, so repeated switching cannot eat faces.

For Blender's Python Console, after opening a working copy:

```python
import sys
sys.path.insert(0, "E:/GitHub/Depths/tools/blender_kit")
from wardrobe_visibility import set_pieces
set_pieces("female", {"tunic", "belt", "trousers", "boot.left", "boot.right"})
set_pieces("female", {"tunic", "belt"})  # tunic/belt only
set_pieces("female", set())              # full source body restored
```

Use `male` for that fit. Use this logical-piece helper rather than hiding only
a cuff/sole mesh and leaving its body mask active. The review contains actual
removal renders. These are authoring/preview selections, not new gameplay slots.

## Temporary fitting motions and #215

The owner's 2026-11-02 decision is to re-download motions for each body and
verify those in #215. That plan remains authoritative. The following legacy-clip
retargets are temporary garment stress-test references, not replacements for
the expected per-body downloads or completion of #215.

Four existing supplied clips now have target-specific candidate Actions:

| ID | Supplied file | Source frames at60fps |
|---|---|---|
|idle|Idle.fbx|1–241|
|walk|Walking.fbx|1–53|
|sit_down|Stand To Sit.fbx|1–135|
|seated|Sitting Idle.fbx|1–616|

Names are `fit.<female or male>.<id>`, with explicit saved Action slots. Each
master also preserves its own original Dying Action/`OBSlot` (1–261). Only these
five intended Actions are exported; raw incompatible imported Actions are not
left in the authoring dropdown as misleading alternatives. Their immutable
original FBXs remain in the local source folder.

Retargeting copies the source world bone orientations into each unchanged target
rest space and reconstructs translations using target bone lengths. Root hips
displacement uses the target/source rest-hip-height ratio. An explicit target-only
vertical lower-toe trajectory reconciliation handles unequal leg lengths:
the largest adjustment is about0.0792 source units on female and0.00071 on male.
This is part of rest-space retargeting, applied before clothing; lateral source
travel is retained. It does not move the source or hide a boot-fit error.
There is no foot locking, floor/contact IK, seated-hand IK or invented motion.
Target-only ring/pinky joints retain their rest-relative relationship to the
animated parent. Source files/Actions and target rest skeletons are preserved.

Recorded limb-axis errors at start/middle/end are zero within the diagnostic's
floating-point precision. Complete keyframe data is retained, including
quaternion sign continuity. This is a fitted candidate, not owner acceptance.
`Stand To Sit` ends in a chair-height sit; the supplied `Sitting Idle` is a
reclined ground sit. They are useful separate garment stress tests, **not**
a verified continuous sit-down/hold sequence. Seat/hand contact and the final
matching animation selection remain #215/#214 work.
The [shared animation list](animation-library.md) distinguishes direct raw clips
from these corrected target-specific Actions. Other supplied clips remain untested.

## Actual checks and limits

-2961 Blender checks cover source/master preservation, normalized ≤8 influences,
  genuine leg/foot/toe weighting, editable thickness, all32 coverage combinations,
  saved Action slots and selected start/end/between-key frames of five motions.
  Opening-plane checks prevent removal gaps; finished hem checks prevent acute
  Solidify corner spikes. Gores are fitted outside each body's actual seat.
  Maximum checked edge stretch stays below3.5; actual maximum is about2.90.
-492 independent GLB reimport comparisons cover every body/garment mesh at rest
  and four samples of every exported motion. Maximum point-cloud difference is
  below0.00010 raw source units. Exports never save or flatten the `.blend` files.
-Godot4.7.2 Mobile/D3D12 checks all imported skin IDs/weights, original65/49 joints,
  exact triangle counts, opaque material behavior and five real motions. Native
  skin bakes agree with an independent CPU calculation, including between-key
  samples. World bounds include the preserved source import scale. Actual engine
  captures are linked beside the Blender views. Runtime checks exit cleanly;
  the restricted editor import retains its known preference safe-save warning.
-138 actual Blender renders cover rest plus start/middle/end front/side/back
  motion samples, removal states,12-frame walk sequences and boot/floor details.
  Camera reframing follows source motion; the GIF repeat is not a claim that
  the source is a seamless/in-place loop. No frames are synthesized or retouched.
-Sole/source-foot envelope samples are recorded per pose. Boot soles sit roughly
  0.001–0.119 raw units below the source-foot envelope over the chosen extremes.
  Fine hand/seat/ground contact and source movement drift remain visible polish
  work; there is no cloth collision simulation or guarantee for every possible
  future pose. Physical iPhone performance is not inferred from desktop checks.

| Candidate | Assembled triangles | Mesh surfaces | Garment-only baked triangles |
|---|---:|---:|---:|
|female|4198|11|3352|
|male|2654|11|2188|

Each assembled candidate retains its exposed head/hands body region. Female
uses the unchanged packed1024² source skin image; garments use simple materials.
Both kits have10 independently editable garment/detail meshes plus the body.

## Export and beginner handoff

Open the local review, then the desired `_garments.blend`. Save a **working copy**
before edits. Fit in Rest Position; switch the rig to Pose Position and choose
the named Action **and its slot** to preview. The masters default to neutral
modelling mode. No face/hair work or item rules are included.

`exports/<fit>_kit.glb` is a static assembled review candidate: its current body
mask and thickness are baked, while skinning/five motions remain real. Do not
remove a garment from that baked body and expect hidden faces to return.
`<fit>-tunic-belt.glb`, `<fit>-trousers.glb`, `<fit>-boots.glb` contain garment
parts and their real rig/motions, **without** a baked body. Later assembly must
use the retained full-body masters and proper runtime coverage handling.

The saved-working-copy `export_current.py` helper detects the garment profile,
recomputes its logical-piece coverage and bakes only non-skin thickness/masks
into a separate export. It never saves/overwrites the master. It exports the
currently selected Action; use the full-suite candidate builder for all five.

Reproduction from the repo root, using installed Blender5.2.3 and Python/Pillow:

```powershell
$kitBlender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$env:BLENDER_USER_RESOURCES = 'E:/GitHub/Depths/build/local-blender-kit-v1/blender-user'
& $kitBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/build_garments.py
& $kitBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/check_garments.py
& $kitBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/export_check_garments.py
& $kitBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/capture_garments.py -- --matrix --motion
python tools/blender_kit/prepare_garment_smoke.py
```

The builder protects existing garment masters unless explicitly passed
`-- --rebuild`; do not use that to erase later manual work. Blender's
`--python-exit-code` is placed **before** `--python` so script failures produce
a failing process result. Import/run the isolated generated Godot project, then:

```powershell
python tools/blender_kit/package_garments.py
python tools/blender_kit/validate_garment_artifacts.py
node tools/blender_kit/check_garment_review.cjs
```

Only generic tools/docs/non-asset summaries go to Git. #214's
[interactive wardrobe review](blender-wardrobe-review.md) now provides real
Godot controls,96/192 captures and landscape phone-shaped layouts. Final
animation/portrait acceptance and later live hookup remain separate. These files do not replace the
approved2D portrait/camp/equipment system or establish new story/class identities.
