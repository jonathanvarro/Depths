# Regional prop materials

Depths #225, 2026-11-09. Three derived atlas/detail sets for the unchanged CC0
KayKit Dungeon Remastered meshes and UVs. Original geometry/atlas record is
art/third-party/kaykit-dungeon-remastered/CREDITS.md.

tools/transitions_3d/build_regions.py deterministically tints the existing
texture-floor1.png into 32-colour 256px atlases, and derives 32-colour 64px
world-space stain/grain from the existing fungal, fortress and waterworks
wall art. No source picture, mesh, UV, placement or floor-1 material is changed.
No new generated painting or external texture was introduced.

catalog.json records every source/output/tool hash and three rendered source
model hashes. One shared StandardMaterial3D per selected region; no added
emission, lights, geometry, collision, particles or reflection effects.
skins.gd is an optional caller-owned material helper, not a floor dresser.
