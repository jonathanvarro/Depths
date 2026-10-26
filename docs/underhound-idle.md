# Underhound · first production checkpoint

2026-10-25 · Refs #150 · [Review gallery](../art/concepts/underhound-idle-v1/inspector.html).

**Owner accepted this idle:** “This will work.” The accepted pixel/source hashes
are pinned in [approval.json](../art/enemies/underhound-v1/approval.json).
It is now the identity, palette and registration reference for attack/hurt.

**Current family:** attack and hurt are now authored and reviewed alongside this
unchanged idle. See [three-pose handoff](underhound-poses.md) and its paused
gallery. The idle-only scene/coverage below describes the original checkpoint.

The owner selected checkpoint 1: establish the idle at native128. One new
transparent drawing was made with the built-in ImageGen tool, using the chosen
Underhound sheet for identity and the current breach-hound idle for production
pixel scale/framing. The long blind wedge of a head, high ribbed shoulder arch,
low four-legged weight and tail are retained. The jaw is a narrow tooth seam;
the sliding inner plate is mostly concealed in this state.

The shoulder arch and long head read at 64px; the lower counter-curving ribs
are quieter at that size. This is a review point for the owner, rather than
approval of the complete creature. At small size the jaw currently reads as a
tooth seam; the later attack must make its independent movement clear.

## Files and production contract

- `art/source/underhound-v1/idle-master.png`: unaltered generated 1254×1254 RGBA
  source. [generation.json](../art/source/underhound-v1/generation.json) retains
  the **exact final prompt**, original generated path, explicit reference roles
  and SHA-256 hashes. No CLI/API fallback was used.
- `art/enemies/underhound-v1/idle.png`: 128×128 RGBA, 32 visible RGB colours,
  hard alpha, invisible RGB cleared in the file. Bounds `(8,32)` to `(120,121)`
  exclusive; lowest planted pixel y120; pivot `(64,120)`.
- Proportional export fits the whole silhouette once into a reserved envelope,
  using BOX reduction, binary alpha at 128 and visible-pixel median-cut palette
  mapping without dithering. It does not redraw anatomy, invent another pose,
  remove the tail or independently resize limbs. The transform and provisional
  palette are recorded for the later family.
- The idle-only scene uses the existing pose-aware bounds script, shaded art,
  nearest filtering, hard alpha and no cast shadow. A 0.8m body envelope keeps
  its apparent height comparable to the breach hound. Godot's standard importer
  may extend invisible RGB at the edge; native file RGB remains cleared and
  imported alpha stays binary. No mipmaps or lossy texture compression.

## Review and checks

`native-review.png` shows dark/light backings at 3× nearest, native128 and 64px.
Six Godot views show the idle alone against cave/fungal materials and beside
the existing breach hound, at desktop 1280×720 and phone-shaped 1278×590. The
fixture uses the existing Party camera/lantern and LevelBuilder, with the
candidate at a 2.4m viewing distance. These are **isolated art reviews**, without
Main, combat controls, actual encounter assignment or saves.

The export validates source/reference hashes, exact canvas, margins, contact,
binary alpha and palette limit. **21 Godot checks** cover the imported texture,
PNG bytes, palette/alpha, registration/world height, idle-only coverage and
complete first-person framing, with clean import/render/exit logs. The gallery
passes 14 browser checks for exact zoom, image decoding and responsive layout.
[Recorded results](../art/concepts/underhound-idle-v1/godot-validation.json).
Physical iPhone appearance and final combat-tag/HUD clearance remain untested.
One uncompressed native RGBA texture is 64 KiB before engine overhead.

## Next

Idle acceptance is complete. Steps 2 and 3 are now delivered in
[the family review](underhound-poses.md), using this same head, limbs, ribs,
palette, scale and pivot. Owner acceptance of the two new poses remains open.
There are no EnemyType/stat/floor changes.
