# Damp Caves surface foundation (#302)

Original surface assets for Claude's `docs/damp-caves-production-brief.md`, A1–A4. The PNGs are unmodified outputs from OpenAI's built-in image-generation tool. Full exact prompts, generated output paths, hashes, original dimensions and style-reference roles are recorded in `generation.json`; short prompt files accompany each texture. These are original generated images, not third-party CC0 files. No private or external stock sources were used. The base wall was the sole material/palette reference for its three siblings.

Runtime textures are limited by their Godot import files to **512×512 with mipmaps**; PNG originals remain full resolution and unchanged. No bitmap editing, quantization or claimed mathematical seam repair was applied. `catalog.json` records mounts, metric footprint, cost, roughness and specular.

| Asset | Use |
| --- | --- |
| `limestone-wall.tres` | Main wall, cold grey water-carved limestone |
| `limestone-wall-variant.tres` | Edge-compatible alternative, blending two existing textures in one opaque surface |
| `silt-floor.tres` | Flat wet rock/silt beneath later puddle surfaces |
| `seeping-ceiling.tres` | Quieter limestone/calcite pores beneath later 3D straws/drips |

Use full-face wall UVs at a 2m cell / 2.2m wall height. Base/floor/ceiling use linear mipmapped StandardMaterial3D, roughness 0.61/0.68/0.66 and dielectric specular 0.28/0.24/0.25. Variant is a fully opaque PBR ShaderMaterial, roughness 0.63/specular 0.28: it shares the base albedo at tile borders and blends 55% alternate rock toward the center over a 16% apron. It adds one texture sample on variant surfaces, no draw, extra map or light. Do not cast it as StandardMaterial3D or add ALPHA. No time-dependent shader terms, normal/emission/clearcoat, screen reads or new reflection passes.

Four square 512px RGBA8 textures with complete mip chains represent approximately **5.33 MiB before GPU format/engine overhead**. Each material is one draw per existing mesh instance. Existing wall boxes are 12 triangles; existing floor/ceiling planes are 2. No geometry or collision was added by this library.

Native review: `build/local-damp-caves-v1/inspector.html`. Reproduce with `tools/damp_caves/surface_check.gd` through the private-desktop launcher. **87 native checks / zero failures**, ten captures: neutral and warm room, 1278×590 and 844×390, grazing view, existing mine comparison, and each material in a 4×4 repeat. Includes rendered border comparison for the variant. The original generated edge mean RGB deltas are 0.013–0.022; repeating motifs/geological continuity still require visual review. Physical iPhone performance and owner style review remain.

No live theme assignment, dressing or game rules changed. These textures are a foundation; 3D growth, puddles, passages and wet effects are later brief sections. The texture's calcite pore marks do not substitute for 3D ceiling pieces. Preserve all original cave and fungal assets for their own areas.
