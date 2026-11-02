# Editable Blender base contract · #210

Prepared2026-11-01 with the installed Blender5.2.3 LTS; Godot stays4.7.2/Mobile.
Local entry point: `build/local-blender-kit-v1/review/inspector.html`.
Editable masters: `build/local-blender-kit-v1/female_base.blend` and
`male_base.blend`. All supplied and derived art stays in ignored local storage.
Only reusable tools and this non-asset handoff are committed.

## Which bases these are

The authoritative sources are the owner's current **Base Female - Dying.fbx**
and **Base Male - Dying.fbx** under `G:/My Drive/3D Objects`. Their unchanged
copies and SHA-256 records are retained beside the masters. This is the actual
pair, not two appearances of #206's earlier female sample.

| Fit ID | Source body vertices / triangles | Bones | Source rest dimensions X/Y/Z |
|---|---|---|---|
| female-v1 |915 /1826|65|3.50796 /0.65657 /3.83443|
| male-v1 |450 /904|49|2.21795 /0.87627 /4.05937|

The female is in a T-like rest pose; the male has lowered arms. The female has
16 additional ring/pinky joints. The source metadata/import transforms produce
these dimensions in Blender units; no aesthetic human-height normalization has
been applied. Both use one Blender unit = one metre for export. Source feet are
slightly below zero (female-0.03870, male-0.03421). Do not move vertices or apply
the dying pose to correct that. Any later game display scale/root-placement
choice must be explicit and consistent, preserving the source bind spaces.

The supplied `Base Male Mesh.blend` has no rig/modifier despite retained groups;
its small same-named FBX is unweighted. Neither substitutes for the real rigged
male Dying FBX. The female source FBX has a stale external texture path. Its
existing packed1024×1024 texture is recovered from the supplied female `.blend`;
both UV maps are checked against that mesh before relinking. Original pixels,
body/face shape and source UVs are preserved. The male keeps its plain source
material; no face features, painting or hair are added.

## Shared authoring contract

- One authoritative rig per master: `rig.female.v1` / `rig.male.v1`. Preserve
  all bone names, parents, rest matrices, source object transforms and weights.
  Original `.fbx` files remain immutable. No Apply Pose as Rest Pose, automatic
  bone reorientation, transform application or destructive body masking.
- Scene/object custom property `fit_id` is `female-v1` or `male-v1`. Separate
  fitted objects are required; these IDs do not promise shared rest coordinates.
- Collections: `KIT_<fit>_v1`, `01_RIG`, `02_BODY`, `03_GARMENTS` with
  `garment.tunic`, `garment.belt`, `garment.trousers`, `garment.boots` children;
  `04_COVERAGE_REFERENCES` is reserved. `90_REVIEW` contains presentation only.
  Those garment collections are empty in #210; no clothing is claimed.
- Future object names: `garment.<piece>.<fit>.v1`, each with its matching
  `fit_id`, original-rig Armature modifier and deliberately authored weights.
  Keep left/right boots independently named. Never share a garment mesh across
  the two fits solely because bone names overlap.
- Shared material names: `cloth.tunic`, `cloth.trousers`, `leather.belt`,
  `leather.boots`. The initial datablocks are restrained rough palette templates,
  not finished textures. Body materials remain separate `source.skin.<fit>`.
- Empty `cover.tunic`, `cover.trousers`, `cover.boots` body groups establish a
  non-bone mask namespace. No faces are currently hidden. Later author coverage
  per garment, retain the full original body, and mask a derived export copy.
  Removing/re-equipping a piece must restore the correct body region. Do not
  let overlapping masks create a hole or export both full and masked bodies.
- Compact local manifest: `schema`, `blender`, `sources[{file,sha256,bytes}]`,
  `fits[{fit_id,master,master_sha256,source,rig_sha256,geometry_sha256,...}]`,
  `export`, `coverage`, `missing_or_pending`. Skeleton matrices, source geometry,
  animation data, textures, captures and derived files stay local.

## Rest mode, Action slots and animation findings

Each master opens with `Armature.data.pose_position=REST`, while its original
source Action remains assigned and has a fake user. Neutral modelling does not
change the rest skeleton or delete the animation. Switch to `POSE` to preview.

| Master | Preserved Action | Required existing slot | Range / timing |
|---|---|---|---|
|female|`Armature.001\|mixamo.com\|Layer0`|`OBSlot`|1–261 at60fps;4.333s elapsed|
|male|`Armature\|mixamo.com\|Layer0`|`OBSlot`|1–261 at60fps;4.333s elapsed|

Object labels do not need to match the slot's identifier. The actual tested
assignment is `rig.animation_data.action=action`, then
`rig.animation_data.action_slot=action.slots[0]`. Reopening both saved masters
retains the proper Action/slot and animated deformation. Blender's
[Action-slot API](https://docs.blender.org/api/dev/bpy.types.ActionSlot.html)
describes the separate slot assignment.

The shared status list is [docs/animation-library.md](animation-library.md);
update it whenever a clip is tested or changed. The owner's
`Animations/Mixamo_Originals` folder contains34 FBX clips; all are
copied, hashed and audited locally. `clip-catalogue.csv` and `clip-audit.json`
record names, rig counts, FPS, ranges, slots and rest differences. Idle, Unarmed
Idle, Walking, Female Walk, Stand To Sit, Sitting, Sitting Idle, Sitting Talking
and death motions are available. Availability does **not** imply fit validation.

Actual direct assignment of Idle/Walking/Sitting Idle was tested on both bodies.
Compared with the source motion, upper-limb world-axis differences reach about
11–12° on female and37–52° on male; local rest-basis discrepancies reach about
43°/41°. Bone lengths and female finger coverage differ too. **Retarget these
clips separately for each fit before using them to accept garments.** Source
Actions remain unchanged; incompatible clips were not installed as approved
master animations. No custom animation library was invented to fill the gap.

## Beginner workflow

1. Open the desired local `_base.blend`. Use **File → Save As** to make a
   working copy before clothing edits. The originals remain the fit references.
2. Select `rig.<fit>.v1`. In **Armature Data → Skeleton**, choose **Rest
   Position** to model. Make the garment in its collection, set its `fit_id`,
   and fit/weight it against that body's actual shape. Faces stay unchanged.
3. To preview, choose **Pose Position**. The dying Action/`OBSlot` is already
   assigned. Play or scrub1–261; pause at awkward between-key frames. Return to
   Rest Position for modelling. Other supplied clips wait for retargeting.
4. Save the working `.blend`. Select only the intended rig and visible fitted
   body/garments for a glTF export. Keep helpers and unmasked duplicates out.
   Use the validated export profile below, or the reusable `export_current.py`
   helper in `tools/blender_kit/README.md`. The helper never saves the `.blend`.
5. Reimport the exported file independently and inspect rest **and** motion.
   Export success alone does not prove fit, skinning, orientation or animation.

## Export and checks

Validated profile: binary GLB, Blender Z-up → glTF/Godot Y-up, original object
transforms, `export_apply=false`, `export_current_frame=false`,
`export_rest_position_armature=true`, skinning/all influences enabled up to8,
no leaf-bone addition or hierarchy flattening, active Action sampling at one
source frame, clip start shifted to0 seconds. No camera/light exports. See the
[official exporter API](https://docs.blender.org/api/current/bpy.ops.export_scene.html).

`check_and_export.py` reopens each master and independently reimports each true
FBX. It compares topology/UV/weights/rest structure and source motion at1,32.5,
65.5,131,195.5,261; then independently imports the GLB. Rest and animated point
clouds round-trip with maximum error below0.00009 source units.92 checks pass.
`check_transfer.py` makes54 actual assignment/finite-axis checks while recording
why the other clips are unapproved for direct transfer.

The independent Godot4.7.2/Mobile smoke project preserves both full joint sets,
triangle counts, normalized eight-weight layouts,4.333s source clips and finite
between-frame motion and the packed female material:5323 checks, zero failures.
It never loads the live game or
player files. The restricted editor import emits its known preference safe-save
warning; isolated runtime checks are clean.12 actual Blender renders provide
front/side/back rest and three dying samples per body. Pose cameras follow the
unmodified source root motion to keep the fallen body in view.

The guide/review/catalogue/browser checks are local beside the files. Garment
fit, all-motion acceptance, hair/faces, full Godot wardrobe controls,96/192px
portrait acceptance and physical-iPhone performance belong to later work.

## Handoff

#211–#213 can now fit tunic/belt, trousers and boots to the separate masters.
#215 tracks target-specific retargeting; #214 needs that work before its full animation matrix
can be marked complete. Owner style acceptance remains separate. Source/derived
art stays local; no live portrait, companion, camp, equipment, save or engine
resource has been changed by #210.
