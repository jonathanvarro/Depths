# Complete portrait components · #121

Frozen native component sources for twelve existing faces. Original sources remain untouched. Clean plates, neutral components and mattes are reused exactly by [the v4 refinement](../portrait-drawings-v4/README.md). Rebuild live drawings with `refine_portrait_drawings.py --wire`, then `build_portrait_registry.py`; the older v3 builder protects these references while v4 is live.

Each face folder retains its immutable resting reference, clean reference, full eye/mouth erasure footprints, per-drawing ink/slit masks and recipe/bindings/source hashes. Skin fills use unmasked native boundaries and local cheek texture, snapped to the original palette. Every mask is clipped to the original silhouette. Clean plates remove the **whole** feature, including outer lashes and lip corners; neutral components restore it exactly. Animated drawings start on the clean surface.

Runtime PNGs live beside original assets in `frames-pixel-v3/`. These authoring images are excluded from Godot import/export. Original v1/v2 artwork remains as history. V2's small masks missed old features; its outside-mask invariant was insufficient. Full coverage, exact neutral reconstruction and independent feature regressions are checked by `validate_portrait_components.py`; held drawings still require visual review.

[Manifest and review](../../concepts/portrait-components-v3/README.md) · [handoff](../../../docs/portrait-rig-families.md).
