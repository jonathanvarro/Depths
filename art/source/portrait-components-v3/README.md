# Complete portrait components · #121

Owner-authorized native pixel edits of twelve existing faces. No generated redraw, scaling or new design. Original sources remain untouched. Rebuild with `tools/art/build_portrait_components.py --wire`, then `build_portrait_registry.py`.

Each face folder retains its immutable resting reference, clean reference, full eye/mouth erasure footprints, per-drawing ink/slit masks and recipe/bindings/source hashes. Skin fills use unmasked native boundaries and local cheek texture, snapped to the original palette. Every mask is clipped to the original silhouette. Clean plates remove the **whole** feature, including outer lashes and lip corners; neutral components restore it exactly. Animated drawings start on the clean surface.

Runtime PNGs live beside original assets in `frames-pixel-v3/`. These authoring images are excluded from Godot import/export. Original v1/v2 artwork remains as history. V2's small masks missed old features; its outside-mask invariant was insufficient. Full coverage, exact neutral reconstruction and independent feature regressions are checked by `validate_portrait_components.py`; held drawings still require visual review.

[Manifest and review](../../concepts/portrait-components-v3/README.md) · [handoff](../../../docs/portrait-rig-families.md).
