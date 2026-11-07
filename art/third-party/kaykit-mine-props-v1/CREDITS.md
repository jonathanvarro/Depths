# KayKit mine prop sources

Kay Lousberg created Halloween Bits 1.0. Its included licence is CC0 1.0
Universal, with optional attribution. The selected source files were verified
on 2026-11-07 against the official release’s Git blob hashes.

- Official repository — https://github.com/KayKit-Game-Assets/KayKit-Halloween-Bits-1.0
- Author’s pack page — https://kaylousberg.itch.io/halloween-bits
- Pinned revision — 6dc69bf6b2fa766a985754f35ec6a0324090e6c6
- Selected meshes — lantern_hanging, lantern_standing, candle, candle_melted.
- Included dependencies — their BIN files, halloweenbits_texture.png and LICENSE.txt.
- Exact source paths, byte counts, Git blob hashes and SHA-256 hashes — provenance.json.

The originals in halloween/ are preserved unchanged. Derived scenery is in
art/dressing/mine-3d-v1. Lanterns are scaled to 24 cm wide, mildly warped and
recoloured as worn iron, sparse rust and warm or extinguished panes. Fresh
and melted candles are rescaled for the shrine. Their original colours are
replaced with a shared 18-colour palette and the existing cave grain.
Exported geometry retains a separate glass mesh for visual state changes.

Depths’ support timbers, rough niche, carved miner and pick, cup, cloth and
mineral offerings are authored geometry. They are built by the same reusable
Blender script, with deterministic variation. Local Blender masters preserve
separate pieces. Runtime exports are static GLBs without embedded source
images, rigs or animation clips. Glow is a scene material effect.
