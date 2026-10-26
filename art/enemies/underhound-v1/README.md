# Underhound · idle / attack / hurt

**Owner approved, 2026-10-25:** “This will work.” [approval.json](approval.json)
pins the accepted source/native pixels as the reference for attack and hurt.

Refs #150 · 2026-10-25. New attack and hurt drawings await owner review;
they are distinct textures, not aliases.

All three are 128×128 transparent RGBA, share the approved 32-colour palette and
`(64,120)` coordinate origin, and use one fixed source-to-native transform.
Attack keeps planted contact at y120; hurt lifts the nearest paw, with lowest
visible pixel y116. Do not recrop or ground each pose independently.

`scene.tscn` mounts all three with nearest sampling, hard alpha and the original
0.8m idle scale. Asset-local `mount.gd` extends the current pose-aware bounds
with additional label headroom. No EnemyType, floor, encounter, sound or rule
uses this family yet; existing breach hounds remain unchanged.

- [Paused three-pose / native64 / actual combat review](../../concepts/underhound-poses-v1/inspector.html)
- [Family handoff, registration and checks](../../../docs/underhound-poses.md)
- [Exact attack/hurt prompts and generated masters](../../source/underhound-v1/poses.json)
- [Unaltered built-in ImageGen master and exact prompt](../../source/underhound-v1/generation.json)
- [Production brief](../../../docs/underhound-production.md)

Rebuild with `tools/art/build_underhound_poses.py`, import in Godot 4.7.2 and run
`tools/art/check_underhound_poses.gd`. The older idle builder also preserves
and rebuilds the complete family. Palette, transforms, bounds and hashes are
recorded in `catalog.json`. Three native canvases total 192 KiB uncompressed.
