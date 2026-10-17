# Simplified cave enemies — current combat art

Ready for Claude's combat implementation (#33). Rat, spider and goblin each have **idle, attack and hurt** drawings following the simpler goblin direction from #32. The existing `data/enemies/{rat,spider,goblin}.tres` scene references now point here; no combat rules or enemy numbers were changed by this art task.

| Enemy | PackedScene | SpriteFrames |
| --- | --- | --- |
| Rat | `res://art/enemies/cave-simple-v1/rat/scene.tscn` | `res://art/enemies/cave-simple-v1/rat/frames.tres` |
| Spider | `res://art/enemies/cave-simple-v1/spider/scene.tscn` | `res://art/enemies/cave-simple-v1/spider/frames.tres` |
| Goblin | `res://art/enemies/cave-simple-v1/goblin/scene.tscn` | `res://art/enemies/cave-simple-v1/goblin/frames.tres` |

Each scene is a floor-origin Node3D with an **AnimatedSprite3D named `Sprite`**. It uses the existing `idle`, `attack`, `hurt` animation names, one non-looping drawing each, so `combat_screen.gd`'s pose switching/restoration and death fade work directly. Combat controls pose duration. No walk/death cycle is supplied.

## Export contract

- All nine PNGs are exactly **128 × 128 RGBA**, untrimmed, binary alpha (0 or 255), nearest filtering, alpha scissoring, billboarded and lit by the scene.
- Each family shares **one palette of at most 32 visible colours across all three poses**, recorded in its `palette.json`.
- Fixed canvas pivot **(64,120)** and planted ground row **y=120**. Full-canvas normalization uses one common scale per enemy; no per-pose bounding-box fitting. One shared horizontal translation per family; vertical translations register supporting feet. Transform/bounds/hash records are in each `registration.json` and [validation.json](validation.json).
- Nominal idle silhouette heights: rat 0.50m, spider 0.55m, goblin 1.40m. Pixel size is shared across a creature's poses. Scene Y offset places the pivot on the floor; do not copy the old 256px scene's pixel size onto these 128px textures.
- Shape and surface detail were redrawn using the built-in image editor before export; this is more than downsampling the old art. Shared-palette quantization and matte cleanup complete the export. The goblin idle reuses the simpler study, remapped to the family's shared palette.

The former detailed [cave-v1 set](../cave-v1/preview.png), its scenes and original sources are preserved. Prefer the new paths above for combat. Generated raw masters are excluded from Godot import with `.gdignore`.

## Review and validation

[2× pose sheet](preview.png) · [native-size sheet](native-preview.png)

Actual combat captures, using the real main scene, combat UI and connected EnemyType resources:

| Enemy | Desktop 1280 × 720 | Landscape phone 1278 × 590 |
| --- | --- | --- |
| Rat | [Desktop](rat-combat-desktop.png) | [Phone](rat-combat-phone.png) |
| Spider | [Desktop](spider-combat-desktop.png) | [Phone](spider-combat-phone.png) |
| Goblin | [Desktop](goblin-combat-desktop.png) | [Phone](goblin-combat-phone.png) |

Phone captures use the project's simulated safe-area margins, not a physical iPhone. Review sheets show pixel shape more clearly than lantern-lit screenshots. Eight legs were visually checked in each spider pose; supporting limbs and equipment remain distinct. These are discrete pose drawings, not smooth animation; minor anatomy/edge polish remains possible. Real-device readability and performance are still to be checked.

`python tools/art/build_simple_enemies.py` rebuilds from preserved local sources with Pillow and NumPy and asserts dimensions, alpha, palette counts, ground rows and no clipping. [Exact prompts and source map](../../source/enemies-simple-v1/generation-manifest.json) record all eight new generated drawings and the reused goblin idle's provenance.

Godot 4.7.2 import succeeded. `tools/art/check_simple_enemies.gd` passes **63 checks** through EnemyType loading, imported textures, scene pivots, actual combat attack/hurt restoration and death fade. `tools/art/render_simple_enemy_combat.gd` produces the six actual combat captures. Run these with Godot's `--path` pointing at this project and `--script res://tools/art/<script>.gd`; render captures require the normal Mobile renderer.
