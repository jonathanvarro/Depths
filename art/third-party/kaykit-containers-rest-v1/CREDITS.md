# KayKit container and rest sources

Kay Lousberg created Dungeon Remastered 1.0. The included licence is CC0 1.0
Universal, with optional attribution. All three selected source files match
the pinned official Git blobs, checked on 2026-11-08.

- Official source — https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0
- Author’s pack page — https://kaylousberg.itch.io/kaykit-dungeon-remastered
- Pinned revision — b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07
- Originals — chest.glb, bed_floor.gltf.glb, LICENSE.txt.
- Exact source paths, byte counts and hashes — provenance.json.

The original bytes are preserved. Derived models under art/props/expedition-3d-v1
sample source face colours into the shared Depths palette, add slight warping
and use metric dimensions. The wooden chest’s separate body, lid and hinge
are preserved in the new composition. Bed geometry is lowered, warped,
recoloured and combined with authored rumpled blankets and bindings.

The strongbox, pack, fire remains, workings, rails and small contents are
authored geometry for Depths, using tools/mine_props/build_models.py helpers.
Its command-line entry remains available, and the module can now be imported
by the new builder without generating the preceding asset batch.
Runtime GLBs contain static geometry and palette UVs. Scene code supplies
lid motion and state visibility. No source character rig or animation is used.
