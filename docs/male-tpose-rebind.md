# Male T-pose rebind · #221

2026-11-03, Claude, at the owner's request: the male's T-pose is now his real
rest/bind pose, and his clothing and animation conversions are redone on it.

#210's male master kept the source FBX's lowered-arm rest. His per-body
Mixamo downloads rest in a T-pose, up to ~41° different at the arms. The
female already rests in a T-like pose. Everything below is new and local
(`build/local-blender-kit-v1/`, git-ignored); `male_base.blend`, `garments-v1`
and assemblies v1–v4 are unchanged.

## What was made

- **`male-tpose-v1/male_base.blend`** (`tools/blender_kit/rebind_male_tpose.py`).
  Each bone of his existing skeleton is turned, parent first, by the
  smallest rotation that points it the way the same bone points in the rest
  pose of his downloaded `idle.fbx`. No roll is added, so limbs don't twist.
  The body is baked into that shape and the pose becomes the rest pose. Bone
  names, hierarchy, lengths and skin weights are unchanged. Only the
  shoulders, arms, hands and some finger joints turned more than 5° (largest
  41.3°); legs and spine moved by a few degrees at most.
- **Dying** is rebaked as `Armature|mixamo.com|Layer0.tpose`: each frame keeps
  the old bone positions, only their channels change. The original Action
  is kept in the file. Against the old master, the body deforms within 0.002
  source units on average; the largest difference is ~0.07 at 4 shoulder
  vertices shared by two bones, which can't be rebound exactly (blended
  skin weights). Binding in a T-pose usually deforms shoulders better.
- **`male-tpose-v1/garments/male_garments.blend`**
  (`build_male_tpose_garments.py`): #211–#213's builder, unchanged, run on the
  T-pose body. It shapes and weights every garment from the body at rest, so
  the sleeves now follow the outstretched arms. The assembly then applies
  the same review-copy sleeve and boot repairs (`refine_review_fit.py`).
- **`assembly-v5`** (`prepare_wardrobe_v5.py`, `package_wardrobe_v5.py`):
  assembly-v4 (female chair hold, chair sequence, female hand lift) with the
  rebound male. Every male clip is converted afresh from his downloads
  (cached conversions belonged to the old rest). Gallery
  `assembly-v5/review/inspector.html`, launcher `assembly-v5/START_REVIEW.cmd`.

## Checks

- New rest matches the download rest directions within 0.000005.
- Male conversions match the Mixamo source within 0.000003 source units,
  no joint direction error.
- Animated male body, v4 vs v5, all five clips: mean difference 0.002, max
  ~0.075 at the same 4 shoulder vertices.
- Clothing in motion (idle, walk, sit-down, seated, stand-up; front and side)
  looks the same as v4: `male-tpose-v1/clothing-v4-vs-v5.png`.
- 778 Blender export/reimport, 3,273 native and 1,404 headless Godot 4.7.2
  Mobile checks and 514 artifact checks pass, no script errors. Male chair
  sequence joins are unchanged (0.906). Full male outfit 3,060 triangles
  (was 3,038).
- His rest stands 0.0044 source units taller (~1.9 mm on screen), from the
  small spine/neck/foot turns. `display_normalization.json` has a new
  `male-tpose-v1` entry (same scale, display height 1.8019 m); the
  `male-v1` entry is unchanged.

## Notes for the next assistant

- `prepare_current_wardrobe.py` gained `GARMENTS` (per-fit garment folder) and
  `NO_CACHE` (convert a fit afresh); both default to the old behaviour.
- Because `display_normalization.json` changed, the stored copies in
  assemblies v2–v4 no longer match the tool file byte-for-byte. Rerunning
  their artifact validation would flag that; the assemblies themselves work.
- Object names stay `rig.male.v1` / `body.male.v1`, since the tools look them
  up by name; the manifest's male `fit_id` is `male-tpose-v1`.
- Not done: owner review; physical-iPhone performance.
