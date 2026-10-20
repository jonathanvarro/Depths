# Complete facial components v3 · #121

Historical duplicate-feature repair. Clean/neutral components and mattes remain live; flat v3 animation is superseded by [the textured v4 refinement (#124)](../portrait-drawings-v4/README.md).

[Mara before/after](mara-before-after.png) · [held drawings](all-faces.png) · [enlarged feature removal](feature-removal-enlarged.png) · [Godot registration](godot/registration-0.png) · [runtime motion](godot/motion.gif) · [paused inspector](../portrait-rigs-v1/inspector.html)

V2 left an old outer eye/lash beside closed lids and resting lips around the rounded mouth. V3 removes resting features from the underlying character, then supplies complete neutral/animated components. Neutral exactly reconstructs the original 192px face. Round mouths have retracted corners, not a hole punched into the old lips. Closed lids have one connected drawing per eye.

`components.json` records original hashes, explicit replacement bindings, masks and 87 runtime exports for 12 faces. `pixel-validation.json` tests source preservation, palette/canvas/alpha, exact resting reconstruction, all simultaneous blink/talk combinations, clean underlayers and independent landmarks. The `godot/` report/contact sheets/GIF come from the actual renderer; individual motion captures are ignored intermediates. Static expressions, lighting/condition passes, families and gameplay remain unchanged.

[Rebuilding/handoff](../../../docs/portrait-rig-families.md) · [authoring contours and masks](../../source/portrait-components-v3/README.md). Historical v2 reports remain, but their small-mask checks did not establish absence of duplicate features.
