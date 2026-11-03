# Padded expedition jacket · #220 first draft

2026-11-03. Owner requested drafting this garment while Claude finishes #218.
Work is isolated on `codex/padded-expedition-jacket-draft`; no current model,
reviewer, rig, animation or live game file is replaced. All images/models/captures
stay local in `E:/GitHub/Depths/build/local-padded-jacket-v1`.

Open `review/inspector.html` there. The original construction concept is
`concept-v1.png`; exact built-in ImageGen prompt is `concept-prompt.txt`, with
hashes/input roles in `concept-provenance.json`. It was generated from text only;
no private model, source image or existing character capture was uploaded.

## Design proposal

Village-made olive/dun canvas, broad vertical quilt channels, a modest padded
collar, three worn leather/wood closures, hip-length split hem and roomy elbows.
An imperfect repaired elbow and softened edges provide wear without making the
garment shredded or ornate. Same practical design for male/female fits: no breast
cups, corset, metal plates, insignia, new face or class/stat assignment.

The concept sheet defines the intended materials/construction. The two actual
Blender blockouts are a rougher geometric starting point, not a claim that their
materials, topology or texture detail already reproduce the painting.

## Editable drafts and preserved interfaces

- `female_padded-jacket_draft.blend` and `male_padded-jacket_draft.blend` are
  separate saved working copies of the stable assembly-v2 editable inputs.
- Original body geometry, UVs, source skin weights, bone names/hierarchy/rest
  matrices and existing Actions/slots remain intact. Input-master hashes are
  pinned and checked unchanged. Neither rig is normalized or rebound.
- Each jacket is a separate copied shell with editable thickness, loose torso
  padding and separate skinned quilt/closure/collar details. The existing tunic
  and belt are hidden in the working copy; source masters are unchanged.
- Existing tunic coverage is reused provisionally for preview. This is not a
  new gameplay slot, final wardrobe-switching implementation or approved mask.
- Twelve actual Blender renders cover each fit's front/side/back source rest,
  idle, walk and sit-down end. Source-pose samples are provisional and use the
  older assembly-v2 clips, not Claude's changing #218 hand/contact corrections.
- Draft checks verify preserved source rig/skin and normalized garment/detail
  weights. Local packaging checks pin both drafts and source masters and verify
  all captures. These are not final independent export/Godot fit checks.

## Next production work

Review the silhouette and construction, then refine collar/shoulder joins,
sleeve bulk, side/hem openings, quilt topology, closure structure and elbow patch.
The generated concept has richer wear/materials than the blockout. Final
fit/skin/coverage, reversible garment swaps, full #218 motion/contact tests and
independent Blender/Godot exports follow once the target rig state is settled.
Keep #214/#215/#218 open according to their own criteria; this draft closes none.

Claude can produce a male reference T-pose without changing the bind/rest rig.
A permanent T-pose rest change is a separate normalization/rebinding task and
requires clothing and animation rechecks. Do not apply Pose as Rest Pose as an
incidental jacket edit. These drafts deliberately keep the original rigs.

## Reproduction

In the isolated checkout, run Blender 5.2.3 with `--python-exit-code 1` before
`--python tools/padded_jacket_draft/build_draft.py -- --workspace E:/GitHub/Depths`.
Then run `package_draft.py --workspace E:/GitHub/Depths` using Python/Pillow.
Existing inputs must already be present. Generated masters are guarded against
overwriting subsequent manual edits; use a sibling output version for a new pass.
The exact concept prompt is preserved separately and uses built-in ImageGen.

Only reusable tools and this non-asset handoff are committed. No live game,
Godot version, source animation, paid asset, lore or named portrait changes.
