# CC0 KayKit bones and skeleton source record

Kay Lousberg created both source packs. The owner supplied them through the
shared Drive asset library. The included licences and 13 selected original
files were checked on 2026-11-06 against the official repository releases.
Every selected file matches an official Git blob, including both licence files.
File hashes, exact source paths and pinned revisions are in provenance.json.

## Halloween Bits 1.0

- Official source — https://github.com/KayKit-Game-Assets/KayKit-Halloween-Bits-1.0
- Pinned revision — 6dc69bf6b2fa766a985754f35ec6a0324090e6c6
- Author's pack page — https://kaylousberg.itch.io/halloween-bits
- Licence — CC0 1.0 Universal, preserved in halloween/LICENSE.txt.
- Selected models — bone_A, bone_B, skull and ribcage, each with its original
  glTF/BIN and shared halloweenbits_texture.png.

## Skeletons 1.0

- Official source — https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0
- Pinned revision — 15b62b9bad122f72926c10fb14d622c73819fa54
- Licence — CC0 1.0 Universal, preserved in skeletons/LICENSE.txt.
- Selected source — Skeleton_Minion.glb and skeleton_texture.png.

The original files are retained unchanged under the two source subfolders.
The game library in art/dressing/bone-decor-v1 uses uniformly scaled exports,
two muted 256 px atlases and the existing cave-prop grain. Death_A_Pose and
Sit_Floor_Pose are sampled into static meshes. The separate emissive eye mesh
is omitted from the scenery versions. Their clothing and exaggerated head
proportions are retained for style review.

Rebuild using tools/bone_decor/prepare_textures.py, followed by Blender running
tools/bone_decor/export_models.py. The derived catalog records each pose,
scale, triangle count and output hash.
