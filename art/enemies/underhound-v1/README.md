# Underhound · idle candidate

Refs #150 · Owner requested checkpoint 1 on 2026-10-25.

`idle.png` is a 128×128 transparent RGBA candidate, 32 visible colours, with
planted contact at y120 and the common `(64,120)` pivot. `scene.tscn` mounts it
with nearest sampling, hard alpha and the existing pose-aware bounds script.
The body envelope is 0.8m. `frames.tres` contains **idle only**.

This is ready for idle review; it is not a complete production pose family.
Attack/hurt are not authored or aliased, and no EnemyType, encounter, floor,
sound, movement or combat rule uses this scene yet. Existing breach hounds
remain unchanged. Review the opposed rib structure before authoring more poses.

- [Native, 64px and actual first-person review](../../concepts/underhound-idle-v1/inspector.html)
- [Handoff and export limits](../../../docs/underhound-idle.md)
- [Unaltered built-in ImageGen master and exact prompt](../../source/underhound-v1/generation.json)
- [Production brief](../../../docs/underhound-production.md)

Rebuild with `tools/art/build_underhound_idle.py`, then import in Godot 4.7.2
and run `tools/art/check_underhound_idle.gd`. The palette and transform are
recorded in `catalog.json`; use this candidate as the reference for later poses
after owner review. Preserve common scale and registration across that family.
