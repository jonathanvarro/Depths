# Editable wardrobe review · #214

2026-11-02. The isolated Godot/Blender review is ready locally. **#214 remains
open for #215's final per-body animation verification.** The owner's new
[private Drive request folders](mixamo-animation-requests.md) now contain both
source models/instructions, and the owner has now returned27 clips. The
[received-animation gallery](received-animation-library.md) reviews eight new
candidates separately. This interactive reviewer retains its earlier fitting
clips until the quiet female chair hold and final sequence/contact checks are
complete. No custom performance or final motion approval is implied.
Owner art acceptance remains separate.

## Open and use

Local entry point:
`E:/GitHub/Depths/build/local-blender-kit-v1/assembly-v1/review/inspector.html`.

Double-click `START_REVIEW.cmd` in the parent `assembly-v1` folder to run the
native Godot4.7.2 Mobile review. It uses the owner's existing local engine.
Alternatively open that folder's `project.godot` and press F5. No live Main,
game settings, player save or companion resources are loaded.

- **Fit:** compare both bodies or inspect either separately.
- **Clothing:** tunic, belt, trousers and left/right boots toggle independently.
  All/None resets the entire preview. Highlighted buttons show present pieces.
- **View and angle:** full figure/portrait; front, three-quarter, side and back.
  Cameras follow the actual source motion without editing the rig/root.
- **Timeline:** play/pause, drag/tap to seek, or −1f/+1f to move one60fps source
  frame. Between-key samples are supported. Playback stops at its real endpoint;
  unverified clips are not silently looped or chained together.
- **Controls:** fold the tool rows for a larger model area on smaller screens.
- **Details:** scrollable source/Action/FPS/range/root/contact limits and current
  geometry/material/texture counts. Escape closes it. Standard native focus and
  menus remain keyboard accessible; unhandled Space/Left/Right/Home/End control
  playback, frame steps and clip endpoints.

The browser gallery contains actual renderer views, all required sampled
angles, removal examples, motion GIFs and native96/192 cards. It is a capture
viewer; the running Godot project provides free garment/animation interaction.

## Editable files and reversible exports

`masters/female_review.blend` and `masters/male_review.blend` are byte-identical
copies of #211–#213's editable garment masters. Each retains the original body,
UVs, weights, unchanged65/49-joint rest rig, original Dying Action/slot, four
temporary fitting Actions and separate garment objects with editable modifiers.
Save a working copy before manual edits. The preparer refuses to overwrite a
review master that no longer matches its recorded hash. Masters are hidden from
Godot's importer so the review does not invoke Blender on every editor scan.

`assets/female.glb` and `assets/male.glb` are self-contained skinned review
exports. Unlike #211–#213's baked full-kit mask, they preserve all original
body faces as disjoint coverage regions: six regions on female, five on male.
Every source face belongs to exactly one region, with its existing UVs/skin.
A region hides when any garment covering it is present. This matches Blender's
Mask at all32 selections; no cumulative cutting,32 duplicated bodies or
per-frame geometry generation. Boundary vertices carry identical source weights.
The belt has no independent body mask and is fitted over the tunic.

All ten garment/detail meshes share that fit's one original skeleton. Removing
a logical boot removes its shaft, cuff and sole together. Hidden meshes still
occupy memory; this is a review implementation, not a final runtime performance
decision or new gameplay equipment-slot system.

| Full kit | Female | Male |
|---|---:|---:|
| Visible triangles |4,198|2,654|
| Visible mesh surfaces |11|11|
| Materials |7|7|
| Original joints |65|49|
| All stored body + garment meshes |16|15|
| Skin textures |one1024×1024|none|

Visible counts update when clothes change. Bare-body triangles are1,826/904,
exactly matching the supplied sources; their split regions use more surfaces
than a monolithic body. The female texture is unchanged RGBA data:4MiB at an
RGBA8 base level, excluding mips/format/renderer overhead. GLBs are approximately
4.34MB/3.12MB on disk; animation storage is included. Source body height, object
scale and proportions remain unchanged. The review's common presentation parent
now scales these to about1.70m/1.80m and puts each fixed rest-sole reference at
y=0. No bind/pose changes or animated floor corrections are applied; see
`tools/blender_kit/display_normalization.json`. These are display references,
not character-height stats. Portrait framing uses the same common factor.

## Animation and fit acceptance still pending

The [animation list](animation-library.md) remains authoritative. Temporary
Actions are `fit.<body>.idle`, `.walk`, `.sit_down`, `.seated`, derived from
the existing `Idle.fbx`, `Walking.fbx`, `Stand To Sit.fbx`, `Sitting Idle.fbx`.
Each source duration/FPS/frame range and exact Action name is in `manifest.json`
and the Details panel. Each body's own original `Base … - Dying.fbx` Action
is retained and tested. Extra female finger joints follow their original
rest-relative parent relationship. The original source files remain unchanged.

The fitting retarget's explicit vertical toe-height reconciliation remains
documented in [the garment handoff](blender-expedition-garments.md); lateral
source movement remains. There is no foot locking, floor/seat/hand IK or cloth
collision simulation. The static ground reference exposes contact/drift rather
than moving the rig to conceal it. Small seam/contact polish remains subject
to the final body-specific clips. **Chair sit-down and reclined ground idle
are not a continuous transition/hold.** Do not mark #215 or the final #214
animation acceptance passed from these candidate captures.

The native report records96 actual visible-envelope/hips samples. Against the
fixed review floor, sampled female walk bounds reach−0.0353 source units;
male ground-seated bounds reach−0.1031; original dying reaches−0.0514/−0.0481.
Negative values indicate intersection with the reference plane. These contact
limits remain part of #215/#214's unfinished animation acceptance, not passed
collision/grounding tests. Rest sole clearance is0.002 source units on both
fits (about0.000887 display metres). The normalized report includes display
and source-unit gaps/hips; its presentation reference is fixed across poses.

96/192 portraits judge the supplied geometry and clothing readability only.
The featureless source heads are preserved; no face painting, named likeness,
hair or facial animation is introduced. Physical-iPhone performance and final
portrait/style approval are not inferred from desktop renders.

## Evidence and reproduction

-684 Blender preparation checks compare all32 coverage selections, independent
  disk-reimported GLB surfaces and all garment/source deformations at rest and
  four samples of every clip, including between keys. Maximum geometric error
  remains below0.00010 source units. Both source and review `.blend` bytes stay
  unchanged; the copies are actually reopened during preparation.
-2,599 native Mobile checks cover real imported rigs, visible surfaces, repeated
  forward/reverse wardrobe switching, the animation/angle matrix, actual mouse
  and touch buttons/slider/menu input, pause/endpoint behavior and screen bounds.
  Desktop1440×900, phone shapes1278×590/1334×750 and compact852×393 are captured.
  Controls have at least44px targets and simulated44px side/20px bottom margins.
-163 actual Godot captures include24 native96/192 cards, the sampled motion
  matrix, six removal states per fit, seven UI views and24 gait frames.
  Two12-frame GIFs and six contact sheets use only those actual images.
-395 artifact checks verify all39 copied sources, exact master/export hashes,
  embedded original skin pixels, GLB rig/motion/counts and complete nonblank
  capture coverage. Native runtime logs are clean. The restricted editor import
  retains its existing preference safe-save warning.
-1,354 headless control/coverage checks and115 browser gallery checks also pass.
  The generated one-click launcher was exercised directly. Browser controls,
  links and native-card sizing are checked at desktop and phone widths.

Run from the repo root (installed Blender5.2.3; Godot4.7.2 unchanged):

```powershell
$wardrobeBlender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$env:BLENDER_USER_RESOURCES = 'E:/GitHub/Depths/build/local-blender-kit-v1/blender-user'
& $wardrobeBlender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/blender_kit/prepare_wardrobe.py
$wardrobeGodot = 'E:/GitHub/Depths/build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
& $wardrobeGodot --headless --path build/local-blender-kit-v1/assembly-v1 --editor --import --quit
& $wardrobeGodot --path build/local-blender-kit-v1/assembly-v1 --script check.gd
python tools/blender_kit/package_wardrobe.py
python tools/blender_kit/validate_wardrobe.py
node tools/blender_kit/check_wardrobe_gallery.cjs
```

The checks render the isolated project, not the live game. Headless checks use
their own report and do not replace native image evidence. Treat any script
error in the process log as a failed check even if Godot returns exit0.
Node uses the installed Playwright/Chrome; Python packaging uses Pillow.

All models, skin/animation data, `.blend` files, exports, manifests and captures
stay LOCAL in ignored `build/local-blender-kit-v1`. Only reusable tools and
non-asset documentation are committed. No approved2D art, item rules, camp/HUD,
save system, named characters or engine version is replaced.
