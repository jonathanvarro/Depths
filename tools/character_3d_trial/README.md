# Modular 3D companion trial · #203

This is an independent Godot **4.7.2** project. Open this folder's `project.godot` in Godot and press F5. It does not load the main Depths project, saves, preferences or companion resources. The folder's `.gdignore` excludes it from the main game's asset scan/export path.

Use Outfit, Utility, Pose, View and Angle to compare the two character studies side by side. Blink/talk runs very basic procedural facial movement. Both use exactly the same 16-bone rest skeleton and garment library. Rook/Branna labels describe broad identity inspiration only; these are not approved likenesses or new cast assignments.

- Three garments: travel cloth, quilted medium, heavy plates.
- Three mutually exclusive utility objects: shield, cape, frame pack.
- Standing, seated and reading pose definitions.
- Full-body and portrait cameras; front, three-quarter and back orientation.
- Original low-poly primitive meshes/materials, no downloaded or AI-generated raster/3D assets.

## Reproduce checks and images

With the Godot 4.7.2 console executable available:

```powershell
godot --headless --path tools/character_3d_trial --log-file E:/GitHub/Depths/build/character3d-review/headless.log --script check.gd -- out=E:/GitHub/Depths/build/character3d-headless
godot --path tools/character_3d_trial --position -10000,-10000 --log-file E:/GitHub/Depths/build/character3d-review/renderer.log --script check.gd -- out=E:/GitHub/Depths/build/character3d-review
python tools/character_3d_trial/package_review.py
```

Use a hidden background launch for renderer automation on Windows. `check.gd` checks all 27 outfit/utility/pose combinations for each identity, shared bone contracts, rest-relative pelvis height, mutually exclusive wardrobe groups, expression replacement, phone control sizes and nonblank native portrait rendering. It captures the actual Mobile renderer and saves two independent native `.tscn` models without the procedural script. Those exports retain hidden wardrobe variants and the skeleton; they are static snapshots, not a new animation-ready asset kit.

## What this trial does and does not establish

The assembly and camera pipeline works. One outfit/pose definition can serve both identities, and wardrobe changes can produce portrait and camp-like views from the same scene. There is only one shared body proportion set in this trial; different body shapes remain untested.

The geometry is intentionally a **technical blockout**, not a recommendation for the game's final face/style. Body parts are rigid bone attachments, not smooth skin-weighted meshes. Joint seams/gaps, the rigid cape, coarse hands and remaining pose/pack/bench overlaps are visible limitations. Facial movement is rudimentary; no emotion library, lip sync, cloth physics, texture painting, live wardrobe mapping, camp integration or portrait migration is claimed. Mesh count includes hidden variants; this is not a mobile-performance benchmark.

The next useful trial, if selected, is an authored skinned body and one carefully shaped face, three fitted garments and a hand/reading-pose cleanup. Compare that face with existing portraits at 96px before converting the cast. Existing approved 2D art remains authoritative.

Review gallery: `art/concepts/character-3d-trial-v1/inspector.html`; report: `docs/modular-character-3d-trial.md`.
