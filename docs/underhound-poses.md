# Underhound · three-pose review

2026-10-25 · Refs #150 · [Paused review gallery](../art/concepts/underhound-poses-v1/inspector.html)

The approved idle now has matching attack and hurt drawings. The idle PNG,
decoded pixels and source master still match [approval.json](../art/enemies/underhound-v1/approval.json).
The two new poses await the owner's visual review; idle acceptance does not
automatically approve them or assign a new encounter.

## Visual review

- **Idle:** the accepted long blind head, high rib arch and low four-legged weight.
- **Attack:** lowered shoulders and planted contact; a toothed inner plate
  extends forward/down from the almost closed outer muzzle.
- **Hurt:** the head and shoulders recoil, the near foreleg folds up, and the
  inner plate retracts. Three supporting legs remain visible.

Compared paused on dark and light backings, all three retain the same head,
tail, limb count, grouped hide and ivory ribs. The attack jaw and hurt gesture
are distinct at native128. At 64px the head/arch/recoil remain readable; the
small jaw teeth and lower opposed ribs are quieter. These are single authored
state drawings, not a newly interpolated animation sequence.

The gallery starts paused with one drawing. Previous/Next and explicit pose
buttons allow stepping; Play is a comparison loop. Optional idle ghost and
origin guides are off initially. Every draw clears the canvas, so previous
features or whole bodies are never unintentionally composited underneath.

## Files and fixed registration

- Runtime drawings and scene: [art/enemies/underhound-v1](../art/enemies/underhound-v1/README.md).
  Three distinct 128×128 RGBA textures share the approved 32-colour palette,
  binary alpha and `(64,120)` origin. Invisible file RGB is cleared. The scene
  uses nearest sampling, hard alpha and the same pixel scale for every state.
- New unaltered built-in ImageGen outputs: `art/source/underhound-v1/attack-master.png`
  and `hurt-master.png`. [poses.json](../art/source/underhound-v1/poses.json)
  retains the exact prompts, source paths/hashes and both reference roles:
  approved master for identity/registration, approved native idle for palette
  and pixel scale. No CLI/API fallback was used.
- All three actual source masters are **1254×1254**. The earlier idle handoff's
  1280px claim was incorrect; its source bytes/hash have not changed.
- Attack and hurt use one fixed full-canvas transform inherited from the
  approved idle crop `(59,236,1229,1168)` to native bounds `(8,32,120,121)`.
  Integer output rounding gives scale XY `(112/1170,89/932)`. Transparent
  padding permits the shared transform to include the higher hurt silhouette.
  There is no per-pose fitting or snapping to the lowest opaque pixel.
- Native exclusive bounds: idle `(8,32,120,121)`, attack `(8,36,121,121)`, hurt
  `(8,29,121,117)`. Hurt's lowest visible pixel rises to y116 as the nearest paw
  lifts; the coordinate origin remains y120. Do not shift it down on export.
- The original 0.8m idle envelope and `pixel_size=0.8/89` remain. Pose-aware
  bounds follow each silhouette. Asset-local `mount.gd` retains actual height
  as `art_height` and adds 0.12m to tag headroom because CombatScreen centres
  its label on the anchor. This prevents the Larger phone label touching the
  high shoulder without shrinking or shifting the artwork. The shared
  monster bounds script is unchanged.

`frames.tres` has distinct idle/attack/hurt textures: idle loops, attack/hurt
do not. Each contains one drawing at 8fps, using existing combat presentation.
Three uncompressed native RGBA canvases total **192 KiB** before engine overhead.
No EnemyType, AI, damage, sound, lore, floor or encounter table is assigned.
Existing breach hounds remain unchanged.

## Checks and limits

The isolated Mobile-renderer fixture uses the real BattleStage, CombatScreen,
fonts and a Mara PartyCard at desktop 1280×720 and landscape 1278×590, with
Normal and Larger UI text. It copies breach-hound numbers only in memory to
exercise existing UI; they are not proposed Underhound stats. It holds each
pose without taking a turn, loads no Main scene and touches no saves.

**92 Godot checks pass**, with twelve retained combat captures: all three poses
in four viewport/text combinations. Tests cover texture distinction, palette,
alpha, registration, physical scale, pose-aware bounds, full framing, label
clearance and separation from the fixture's portrait/actions. The original
idle fixture also passes **21 checks**. Final renderer logs exit cleanly.
This one-hero fixture does not audit full-party Larger layouts. Physical iPhone
appearance/performance remains untested.

**38 source checks** pass for approved inputs, exact generated copies, exports,
palette, registration and capture coverage. **31 browser checks** pass for
pixel-identical paused frames, stepping/clearing, explicit ghost removal,
exact zoom sizes, playback/pause, twelve decoded captures and responsive widths.
Reports are retained alongside the gallery.

Rebuild with `tools/art/build_underhound_poses.py`. The older
`tools/art/build_underhound_idle.py` now preserves shared family metadata and
dispatches to this exporter, so it cannot silently reset coverage to idle-only.
Validate with `tools/art/validate_underhound_poses.py`,
`tools/art/check_underhound_pose_review.cjs` and the Godot fixture
`tools/art/check_underhound_poses.gd`. The browser checker serves only project
files over loopback while running, allowing same-origin canvas pixel inspection.
