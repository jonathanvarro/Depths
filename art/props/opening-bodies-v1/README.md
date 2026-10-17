# Fallen companions — opening escape (#55, art for #30)

Two distinct fully clothed adult companions, one supine and one prone. Practical starter clothing, closed/hidden faces and small dried-blood stains establish the loss without graphic wounds. These are anonymous opening companions, not new named recruits or fixed character classes.

[Sprites at 2×](preview.png) · [Cave, player eye height](cave-desktop.png) · [Landscape phone](cave-phone.png) · [Dim lantern](dim-phone.png)

## Ready for Claude

| Variant | Ready Node3D scene | Transparent texture |
| --- | --- | --- |
| Brown leather / supine | `res://art/props/opening-bodies-v1/fallen-a.tscn` | `res://art/props/opening-bodies-v1/fallen-a.png` |
| Slate cloth / prone | `res://art/props/opening-bodies-v1/fallen-b.tscn` | `res://art/props/opening-bodies-v1/fallen-b.png` |

Each scene matches the existing **`main.gd body_scene`** hook: its root is a Node3D with its origin on the floor. Set the root at `(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)`. There is no collision, script, animation, loot, interaction or movement blocking.

Assign `fallen-a.tscn` to the existing export to replace both placeholder instances immediately. To show both distinct companions, choose A/B by placement index in `_add_opening_dressing()` instead of instantiating the same scene twice. Both scenes already contain their sprite configuration. **Do not rotate the sprite onto the floor**: it is an upright fixed-Y billboard with the lying pose already drawn from a low side angle, like the enemies' camera-facing presentation. Parent Y rotation is safe; the card continues to face the camera. It does not provide multiple anatomical viewing angles.

Claude's opening implementation and `scenes/main.tscn` were left untouched because that work is in progress. This art task does not close #30. Connect the scenes there, then check actual spawn/facing, HUD overlap and tutorial flow. Keep at least one companion visible when Mara looks around the waking room; do not put both beneath the portrait/movement controls.

## Canvas, registration and lighting

- Runtime PNGs are **128×128 RGBA**, untrimmed, binary transparency and nearest filtering, with one shared **32-colour palette**. Floor contact is `(64,120)` on both canvases. Transparent padding above is intentional.
- `Sprite3D.pixel_size = 0.015625`; `position.y = 0.875`. Together these put the common contact line exactly at root floor Y=0. A complete canvas is 2m wide; the visible bodies are about 1.8m long. One identical horizontal export scale is used; only vertical translation registers ground contact.
- `billboard = 2` (fixed Y), `shaded = true`, cutout alpha, no cast shadow or emission. The lantern supplies runtime colour/brightness, rather than a permanent orange glow. Drawings retain local form shading; these are not physically extracted albedo passes.
- Each prop is one sprite quad. There is no skeleton, animation or 3D relief mesh. Low side-angle drawings were chosen after floor-plan textures and a relief test proved much less readable at the game's 1.2m eye height. The top-down studies remain only in `art/source`, not in the runtime scenes.

Future bodies should preserve the small canvas, simple silhouettes, practical clothing and restrained surfaces instead of adding portrait-level detail.

## Sources and export

Created with the **built-in image_gen tool**: two top-down character studies, then an oblique rerender of each using its study as the identity/clothing reference. [Complete prompts and paths](../../source/opening-bodies-v1/generation-manifest.json), both `fallen-*-master.png` studies and the final `fallen-*-oblique-master.png` files are preserved in `art/source/opening-bodies-v1`. No external artwork was copied.

`tools/art/build_opening_bodies.py` exports the final oblique masters at a common 128px width with BOX downsampling, registers contact at y=120, and applies alpha threshold 128 and a common median-cut palette without dithering. There is no background removal or manual repainting. [registration.json](registration.json) records source/output hashes, dimensions, bounds, palette and world/pivot settings.

## Checks

`tools/art/check_opening_bodies.gd` uses the existing cave theme/level builder in an isolated room. **Godot 4.7.2 Mobile/D3D12: 52 assertions pass**, covering scenes, registration/world scale, textures, transparency/filtering, lit materials and parent-yaw behaviour. Captures at 1280×720 and 1278×590 show normal/dim lanterns and were visually reviewed. [validation.json](validation.json) records the scope. Source-copy/hash, 128px RGBA, binary alpha, palette and documentation-link checks also pass.

This is simulated landscape-phone rendering. Physical iPhone performance/visibility and the real opening's initial placement/HUD remain integration checks for #30; the captures are art tests, not a completed tutorial playthrough.
