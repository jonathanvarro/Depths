# Native facial pixel repair · #121

Owner explicitly chose precise edits to the existing pixels, preserving the current faces. No new ImageGen artwork is used. The original resting character, neutral eyes/mouth, clothing, conditions and separate light masks remain unchanged.

Each face folder contains its exact composited resting reference, full192px edit masks and the fitted recipe/hash record. Runtime siblings are in that face's existing asset folder under `frames-pixel-v2/`. The reproducible native pixel-authoring source is `tools/art/repair_portrait_pixels.py`: individually fitted eye centres/socket interiors, lip seam anchors, native skin texture cloned from the same eye's cheek and shaded with that face's existing palette, modest lip openings and Corin's missing front tooth. No scaling, atlas alignment or facial deformation occurs.

Every new frame equals the resting character outside its fitted lid/lip mask. The unchanged broad patch borders therefore composite exactly onto the head. Original v1 PNGs and the rejected generated candidates remain preserved. See `docs/portrait-rig-families.md` for review and validation.
