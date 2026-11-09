# Cave formation and growth source record

The rubble cluster reuses Kay Lousberg’s CC0 Dungeon Remastered 1.0 model
already retained in the project. Source and licence were checked against
the existing record on 2026-11-08.

- Official repository — https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0
- Pinned source revision — b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07
- Source — art/third-party/kaykit-dungeon-remastered/models/rubble_half.glb
- Source SHA-256 — 7514ccbda643c13d5a782579e4f01ee6402eec5519590d3f048d396cdaedec24
- Original licence — art/third-party/kaykit-dungeon-remastered/LICENSE.txt

The derivative centres the rubble at its floor origin, scales its width
to 72 cm and replaces colours with the shared cave palette and grain.
The original file retains its supplied bytes.

Mineral formations, flowstone, roots and fungal shapes are authored geometry
for Depths. tools/cave_growth/build_models.py reuses the existing mine mesh
exporter. Original cave-v1, landmarks-v1 and fungal dressing establish the
shape, scale and colour direction. The new geometry has metric floor/wall/
ceiling mounts, deterministic variation and optional cap emission.

Runtime models are static GLBs with palette UVs. Editable local Blender
masters retain individual pieces. No source character, rig or animation
clip is included. The catalog records source/export hashes and tool lineage.
