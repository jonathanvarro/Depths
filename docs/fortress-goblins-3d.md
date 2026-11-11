# Fortress goblins and Goblin King in 3D (#257)

[Open the review gallery](E:/GitHub/Depths/build/local-fortress-goblins-3d-v1/inspector.html). The native inspector and four editable Blender masters are beside it. This is the first model pass following the [selected fortress concept](https://github.com/jonathanvarro/Depths/blob/9dcb47b56f6fc17bf5eabbfc688269c4004e630a/art/concepts/fortress-goblins-v1/README.md).

| Model | First pass | Triangles |
|---|---|---:|
| Common goblin | Bare head, rough wraps, small buckler and knife | 2,491 |
| Shield guard | Narrow crested helm, broad round shield and iron cudgel | 2,999 |
| Archer | Low moss hood, prominent quiver and a wide, hand-posed draw with the bow clear of the torso | 2,967 |
| King | Low hunch, oversized right forearm, broken iron circlet and horned-skull staff | 3,712 |

The three goblins retain the 57-bone [CC0 goblin rig](https://opengameart.org/content/goblin-1) by CDmir and TinyWorlds via the #255 adaptation. Their four common motions stay available. The guard has brace and the archer has draw. The archer's current bowstring holds its resting shape during draw. The original source and declaration are in art/third-party/oga-creatures-v1. The King's 15-bone rig and geometry are original. His two clips are idle and plant, at 24 fps. The staff and gripping hand keep their anchors during the weight shift. The King still needs the full combat pose set and live integration.

All four reuse the earlier cave palette and world grain and have fixed metric floor origins and +Z fronts. The King's tallest point is the staff at 1.97 m. Godot 4.7.2 Mobile passed 603 checks and saved 93 captures, including first-person review views and a phone-size simulation of the tactical camera. The fixture checks the imported skin against Blender, clip motion, clearance, the 2 m tile, exact still sampling and the King's grip and staff anchors. It ran off the active desktop. First-person and board shots come from the isolated review. Live encounter and physical iPhone checks remain pending.

## Rebuild

Run tools/fortress_goblins/build.py in Blender 5.2 background mode with --factory-startup --disable-autoexec --python-exit-code 1, then -- --workspace E:/GitHub/Depths. It uses the existing #255 goblin.blend master under build/local-spiders-goblin-v1/masters. The output is art/enemies/fortress-goblins-3d-v1. Run prepare_review.py with the same workspace, import the review folder headlessly, and use the private-desktop Godot launcher with --script res://check.gd. Use native-check as its report folder. Run package_review.py to verify the captures and build the gallery.

The branch is codex/fortress-goblins-3d, stacked on codex/combat-roster-3d for the shared palette and motion contract. The Queen remains the live boss.
