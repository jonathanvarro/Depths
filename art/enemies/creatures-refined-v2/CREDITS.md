# Refined rats and cave bat (#292)

Rat and great rat derive from **Rat by br-n518 (2018), CC0-1.0**:
https://opengameart.org/content/rat-0 . Original downloads, licence page and
hashes remain in `art/third-party/oga-rat-v1`. No new external downloads.

Changes: one surface subdivision, shaped muzzle and curved tail, new rooted
ears, eyes, whisker pads, teeth and articulated paw details. Great rat adds
shoulder mass and low tapered bristle fans. The original 21-bone rig and six
24fps clip roles remain; the derived skin receives fresh floor corrections.
Old Whisker reuses the revised great rat with an ash coat, uneven whiskers
and healed muzzle scars fitted from the project's named-leader design.

The cave bat is **original Depths geometry and animation**, replacing the
project's earlier five-bone bat with 13 bones, curved membranes, hinged wings,
jaw and feet. Nine clips include grounded hurt/fall variants. No private human
models, Mixamo content or named companion likenesses are included.

Surface colours and procedural fur/skin/membrane/contact shaders are authored
for this revision. These use per-vertex colours rather than the old cave-grain
texture. No AI-generated raster textures. Rat source rights remain CC0;
project-original additions follow the project's licence.

Reproducible builder: `tools/creature_refinement/build.py`. Exported hashes,
bone/triangle counts and pose envelopes are in `catalog.json` and
`whisker-catalog.json`. Separate editable Blender masters stay local under
`build/local-creatures-refined-v2/masters`; retained earlier masters and live
fallback sprite art are unchanged.
