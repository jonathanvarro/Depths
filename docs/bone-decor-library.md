# Bones and remains · #239

The owner supplied KayKit Halloween Bits 1.0 and Skeletons 1.0 in the shared
Drive Assets folder. This library prepares the loose-bone pieces and two
complete skeleton studies for scenery review.

The combined local review is
`E:/GitHub/Depths/build/local-bone-decor-v1/inspector.html`.
START_REVIEW.cmd in the same folder opens the actual Godot comparison.
Both views offer cave/neutral light and four camera angles.

## Reusable scenes

All four recipes are in art/dressing/bone-decor-v1.

| Scene | Contents | Triangles |
|---|---|---|
| scattered-bones.tscn | Four loose bone pieces | 848 |
| small-remains.tscn | Skull, ribcage and three loose bones | 2,212 |
| fallen-skeleton.tscn | Static Death_A_Pose study | 5,156 |
| seated-skeleton.tscn | Static Sit_Floor_Pose study | 5,156 |

The four loose models are also available separately as bone_A.glb,
bone_B.glb, skull.glb and ribcage.glb. Their widths are 34, 25, 20 and 34 cm
respectively. Every exported model has a floor-centred origin.
The GLBs carry geometry and atlas UVs. Apply material-halloween.tres when
placing loose pieces directly; the four recipes assign their shared material.

The complete skeleton studies are uniformly scaled from a 1.65 m rest height.
The fallen pose occupies approximately 1.74 × 1.67 m before its recipe's yaw.
The seated pose is approximately 1.28 m high. The owner's head correction
fits the skull and jaw to the existing character proportions. Their heavy
clothing and broad limbs retain the source style for review.
The separate glowing-eye mesh is omitted from the static scenery.

## Head proportion correction

The owner requested smaller heads on 2026-11-06. The source skull and jaw
together occupied about 45% of standing height. A local comparison with
the current male and female masters found head-weighted bounds of approximately
19.0% and 17.7% respectively. These bounds include some neck and are a style
reference for this scenery correction.

The derived skull and jaw now use one shared rest-space transform around
the head joint, with width/depth/height factors of 0.26/0.28/0.30 and a
0.113 m upward adjustment in source space. This retains their mutual fit and
places the spine inside the skull base above the collar. It is applied before
sampling either source pose. Final whole-body normalization then restores
the 1.65 m standing reference. The resulting head is 29.5 cm tall, or 17.9%
of standing height. The same correction is used for both scenery poses.

Native front, side, high and three-quarter views were inspected in neutral
and cave lighting for neck attachment, jaw alignment and floor contact.
The revised exports keep the original topology and UVs. The original CC0
rigged source and its Actions retain their supplied bytes.

The source poses are baked as single-mesh scenery, with one material surface
per model. Each pack uses a shared muted 256 × 256 atlas. The wrapper scenes
apply the same world-space multiply grain used by the existing cave props,
with crisp mipmapped filtering. Their material resources depend on the
existing grain-floor1.png under art/third-party/kaykit-dungeon-remastered.
The derived GLBs omit embedded materials/images so their instances share the
two external atlases.

The scene origin marks the floor contact. Placement should use actual room
clearance and wall anchors. Encounter rules, event state, named bodies and
floor assignments remain in the game controller.

## Source and licence

The selected originals and two CC0 licences are retained under
art/third-party/kaykit-bones-v1. CREDITS.md and provenance.json record the
author, official repository URLs, pinned revisions, exact source paths and
file hashes. All 13 selected source files match the official Git blobs.
The Drive originals are used as the intake source.

## Rebuild and review

1. Run tools/bone_decor/prepare_textures.py with the project's Python/Pillow.
2. Run tools/bone_decor/export_models.py in Blender with
   --background --factory-startup --disable-autoexec --python-exit-code 1.
3. Run tools/bone_decor/prepare_review.py --workspace E:/GitHub/Depths to
   generate the recipe scenes, shared materials and isolated review project.
4. Import that project with Godot 4.7.2, then run its check.gd with the actual
   Mobile renderer to capture the four arrangements in both light settings
   and all four angles.
5. Run tools/bone_decor/package_review.py --workspace E:/GitHub/Depths,
   then tools/bone_decor/check_gallery.cjs with the workspace argument.

The native checks cover static imports, metric dimensions, floor origins,
triangle/material counts, shared atlas/grain settings and phone-safe controls.
The gallery uses actual native captures. Character pack animation data is
retained in the original source, and the derived scenery exports are static.

The 2026-11-06 review passed 139 native checks, 100 source/artifact checks
and 17 browser checks. Its 33 native captures cover all light/angle combinations
plus an overview. Browser checks include 852 × 393 and 667 × 375 phone views.
