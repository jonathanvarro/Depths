# Stone texture library — first test

Four 64 × 64 colour textures: `wall_plain.png`, `wall_worn.png`, `floor.png`, and `ceiling.png`. Each has a reusable Godot StandardMaterial3D `.tres` with nearest-neighbor sampling and full roughness. No normal maps or expensive effects. Materials keep neutral colours so the existing lantern supplies the warm light.

The dungeon uses both wall variants with a stable coordinate-based distribution. This does not alter floor generation or consume random values. Floor and ceiling materials are shared across cells. The current BoxMesh walls use Godot's default box UV layout; they stretch/compress the stone pattern differently than plane surfaces. Consistent physical texel scale remains a later geometry/UV improvement.

`in-game-preview.png` is an actual Windows Mobile-renderer screenshot of the fixed debug corridor, not generated concept art. Asset import and the rendered scene ran successfully on Godot 4.7.2. iPhone appearance/performance is not tested. The initial restricted validation had editor settings permissions errors; the normal-access import and rendered run passed.

## Art direction

Simple block shapes, sparse surface damage, subdued grey, readable mortar, and generous darkness. One coordinated material family, not random mixes of unrelated textures. Future families can provide coordinated wall/floor/ceiling replacements and separate stains, symbols, or moss details.

These are generated prototype textures: inspect repetition over larger rooms and make a seam-cleanup pass before treating them as final production art. The source atlas's quadrants are not guaranteed perfectly seamless or interchangeable along every mortar course. The screenshot proves loading and basic appearance, not universal seam compatibility.

## Provenance

Generated using the built-in image-generation tool. Prompt: a square 2 × 2 atlas, no gaps or labels; upper-left plain staggered charcoal stone blocks; upper-right matching worn/cracked masonry; lower-left worn flagstone floor; lower-right rough stone ceiling. Flat orthographic surfaces, seamless-repeat intent, restrained pixel art for 64 × 64 tiles, large clusters, sparse detail, shared neutral grey palette, no baked torch illumination, perspective, objects, text, or photorealism.

`source-atlas.png` preserves that output. Quadrants were cropped at the image midpoint and exported to 64 × 64 using nearest-neighbor sampling. Individual textures are the runtime assets; source and preview images are reference only.
