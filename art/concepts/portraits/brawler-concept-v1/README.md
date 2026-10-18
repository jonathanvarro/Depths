# Bald Brawler portrait concept

2026-10-18 · #102 · Built-in ImageGen.

Owner's brief: bald adult male, conventionally unattractive, missing a tooth, with confident and straightforward enthusiasm; like a rough knight who enjoys clubbing things. The concept uses a thick neck, broad shoulders, battered nose, uneven features, short stubble and a relaxed tooth-gapped grin. Plain quilted clothing fits the existing starter roster. Soft neutral material shading avoids a permanent orange torch rim.

- `portrait-192.png`: transparent native portrait, 48 colours, binary alpha, nearest filtering.
- `portrait-96.png`: nearest party-card readability preview.
- `portrait-enlarged.png`: nearest ×4 presentation of the native portrait.
- `review-dark.png` / `review-light.png`: native and enlarged comparisons on both backdrops.
- `validation.json`: canvas, margins, palette and source/export hashes.

[Exact prompt and reference roles](../../../source/brawler-concept-v1/generation-manifest.json) · [Preserved generated master](../../../source/brawler-concept-v1/master.png). Rebuild with `python -B art/source/brawler-concept-v1/build.py`.

Static visual exploration only. Existing Brawler faces and live resources are untouched. This is not yet an animated/component-registered recruit: neutral expressions, a separate resting mouth, blink/talk drawings, condition layers, coordinated light passes and outfit registration still need authoring if this face is selected. The grin is an expression proposal, not a requirement for every condition. No class rules, fear, stats, background story, knighthood or equipment grant is settled by the portrait.
