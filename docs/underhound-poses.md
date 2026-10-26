# Underhound · three-pose review

2026-10-25 · Refs #150 · [Paused review gallery](../art/concepts/underhound-poses-v1/inspector.html)

The approved idle now has matching attack and hurt drawings. The idle PNG,
decoded pixels and source master still match [approval.json](../art/enemies/underhound-v1/approval.json).
The owner liked the hounds and requested an open maw instead of the attack's
tongue-like projection. Idle/hurt remain accepted and unchanged; the revised
attack awaits visual review. No encounter is assigned.

## Visual review

- **Idle:** the accepted long blind head, high rib arch and low four-legged weight.
- **Attack, revised:** lowered shoulders and a broad hinged lower jaw, with two
  rows of teeth and a dark open mouth. No projecting strip or visible tongue.
- **Hurt:** the head and shoulders recoil, the near foreleg folds up, and the
  inner plate retracts. Three supporting legs remain visible.

Compared paused on dark and light backings, all three retain the same head,
tail, limb count, grouped hide and ivory ribs. The attack jaw and hurt gesture
are distinct at native128. At 64px the head/arch/recoil and dark maw remain
readable; individual teeth and lower opposed ribs are quieter. These are single authored
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
- Current built-in ImageGen outputs: `art/source/underhound-v1/attack-open-maw-master.png`
  and `hurt-master.png`. Earlier attack source/native pixels and exact prompt
  remain as superseded provenance. [poses.json](../art/source/underhound-v1/poses.json)
  retains exact prompts, source paths/hashes and reference roles. The open-maw
  edit uses the earlier attack as its target and approved idle master for
  identity/materials. Hurt uses approved master/native idle references for
  registration, palette and scale. No CLI/API fallback was used.
- All three actual source masters are **1254×1254**. The earlier idle handoff's
  1280px claim was incorrect; its source bytes/hash have not changed.
- Attack and hurt use one fixed full-canvas transform inherited from the
  approved idle crop `(59,236,1229,1168)` to native bounds `(8,32,120,121)`.
  Integer output rounding gives scale XY `(112/1170,89/932)`. Transparent
  padding permits the shared transform to include the higher hurt silhouette.
  There is no per-pose fitting or snapping to the lowest opaque pixel.
- Native exclusive bounds: idle `(8,32,120,121)`, attack `(7,36,120,122)`, hurt
  `(8,29,121,117)`. Hurt's lowest visible pixel rises to y116 as the nearest paw
  lifts; the revised attack's lowest pixel is y121, within one pixel of the
  original contact. The y120 origin stays fixed; neither pose is snapped on export.
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

**42 source checks** pass for accepted inputs, edit references, generated copies, exports,
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
