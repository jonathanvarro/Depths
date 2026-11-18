# Remaining early creature models and Bitter Moss

These six low-poly creatures use original meshes and rigs, the existing
cave-grain palette, local +Z fronts and fixed tile origins. No third-party
character mesh or clip is used. They replace the painted enemies on the board
when 3D enemies are enabled. The existing painted scenes remain available.
These are presentation changes. Hit rules, equipment, light, and enemy stats
stay with the current combat and quest systems.

| Creature | First floor | Visible cue |
|---|---:|---|
| Cave bat | 1 | Wings spread at flight height, body drops for the swoop, wings fold on landing. |
| Rock beetle | 2 | Brown stone-like plates cover the tucked head and legs. |
| Hollow miner | 3 | A battered work cap and two arms extended across the tile during a grab. |
| Gas-bloat | 3 | Pale green gas sac swells before bursting. The familiar gas cloud accompanies its collapse. |
| Lamp-eater | 3 | Hooked arms frame an open jaw during the drain. |
| Breach hound | 3 | Front paws and head reach forward during its pack lunge. |

The Bitter Moss quest uses a low wet slab with a pale moss carpet. Gathering
leaves a scraped face and ragged fringe through the existing used-prop state.
The quest builder uses the same scene as the checked-in resource.

Godot 4.7.2 Mobile passed 1,105 rig and motion checks and captured 179 views.
The largest sampled Blender-to-Godot bounds discrepancy was 1.5 cm. The
live-resource fixture also passed pose dispatch, the reduced-motion states,
and the fresh and scraped Moss scene at 1278 × 590.

[Compare the six models](E:/GitHub/Depths/build/local-early-creatures-v1/captures/lineup.png)
· [Bitter Moss, fresh and gathered](E:/GitHub/Depths/build/local-early-creatures-v1/bitter-moss.png)
· [Native pose inspector](E:/GitHub/Depths/build/local-early-creatures-v1/START_REVIEW.cmd)

## Rebuild

Run `tools/creatures_3d/build_early_creatures.py` in Blender 5.2 background
mode with `-- --workspace E:/GitHub/Depths`. The local editable masters are
in the review folder. Use `tools/fortress_goblins/prepare_review.py --workspace E:/GitHub/Depths --creatures`,
import the review and run its `check.gd` via the private-desktop launcher.
The `tools/creatures_3d/check_early_creatures.gd` fixture checks the live
resource bindings, pose dispatch, still mode and both Bitter Moss states.
