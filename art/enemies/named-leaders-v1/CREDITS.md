# Named leader variants

Original authored rigid details and palette variants by ChatGPT for Depths,
2026-11-22. No third-party downloads were added in this batch.

The scenes reference the project's existing animated models without copying or
modifying their GLB files, rigs, skin weights or animation tracks:

- Old Whisker: `combat-roster-3d-v1/great-rat.glb`, derived from the retained
  br-n518 CC0 rat; original archive/licence in `art/third-party/oga-rat-v1`.
- The Pale Spinner: `field-creatures-3d-v1/webspinner.glb`, derived from the
  retained br-n518 CC0 spider; originals/licence in
  `art/third-party/oga-creatures-v1`.
- Skarn: `goblin-elites-3d-v1/goblin-brute.glb`, the existing authored brute
  derived from that retained CC0 goblin family.
- The Hollow Foreman and Gristle: the existing authored `hollow-miner.glb`
  and `breach-hound.glb` in `early-creatures-3d-v1`.

The shared grain is the existing KayKit dungeon floor grain; its CC0 source
record remains under `art/third-party/kaykit-dungeon-remastered`.
Palette cell ordering is preserved; the spider's original 8×4 UV grid maps to
the occupied half of its new 8×8 texture. New details use the same grid.

`catalog.json` pins the detail GLBs and unchanged source GLBs by SHA-256.
Local editable detail masters: `build/local-puzzles-elites-v1/masters/leaders`.
The original animated masters remain in their earlier review folders.
