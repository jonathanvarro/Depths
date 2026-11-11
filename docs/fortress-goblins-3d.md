# Fortress goblins and Goblin King in 3D (#257)

[Open the review gallery](E:/GitHub/Depths/build/local-fortress-goblins-3d-v1/inspector.html). The native inspector and four editable Blender masters are beside it. This is the first model pass following the [selected fortress concept](https://github.com/jonathanvarro/Depths/blob/9dcb47b56f6fc17bf5eabbfc688269c4004e630a/art/concepts/fortress-goblins-v1/README.md).

| Model | First pass | Triangles |
|---|---|---:|
| Common goblin | Bare head, rough wraps, small buckler and knife | 2,491 |
| Shield guard | Narrow crested helm, broad round shield and iron cudgel | 2,999 |
| Archer | Low moss hood, prominent quiver and a wide draw with a string that follows the draw hand | 2,977 |
| King | Low hunch, oversized right forearm, broken iron circlet and horned-skull staff | 3,712 |

The three goblins retain the 57-bone [CC0 goblin rig](https://opengameart.org/content/goblin-1) by CDmir and TinyWorlds via the #255 adaptation. The guard has brace. The archer has one additional control for the centre of the string, with both tips bound to the bow hand. Both `draw` and `attack` reach full tension and release at frame 8 (0.333 s), inside the current 0.4 s combat gesture. With motion reduced, the archer holds a drawn pose. The original source and declaration are in art/third-party/oga-creatures-v1.

The 64 × 64 [Goblin King silhouette](../art/ui/expedition-v1/thumbnails/goblin_king.png) is a profile of the live model. The camera gives the broken circlet and horned-skull staff room against the King's hunch. The existing bestiary lookup uses the `goblin_king` resource ID.

The King's original 15-bone rig has idle, plant, attack, hurt and fall at 24 fps. The free arm swings while the staff supports him. He releases the staff during his fall. The still frames are plant 15, attack 18, hurt 4 and fall 32. The staff and gripping hand keep their anchors during the planted weight shift. The attack clip is 34 frames, so the live cue should allow the visible windup before frame 18. Combat effects and timing are caller-owned.

All four reuse the earlier cave palette and world grain and have fixed metric floor origins and +Z fronts. The King and his staff reach 1.97 m at rest. Godot 4.7.2 Mobile passed 691 checks and saved 108 captures, including first-person review views and a phone-size simulation of the tactical camera. The fixture checks the imported skin against Blender, clip motion, clearance, the 2 m tile, exact still sampling and the King's grip and staff anchors. It ran off the active desktop. First-person and board shots come from the isolated review. Live encounter and physical iPhone checks remain pending.

The [King's victory illustration](../art/illustrations/fortress-king-v1/victory.png) uses the existing 640 × 360 story card canvas. The fallen staff and broken circlet identify the encounter. Its master and exact built-in ImageGen prompt are in the [generation record](../art/source/fortress-king-v1/generation.json). Run tools/fortress_goblins/build_victory.py to regenerate the 640 × 360 export.

## Rebuild

Run tools/fortress_goblins/build.py in Blender 5.2 background mode with --factory-startup --disable-autoexec --python-exit-code 1, then -- --workspace E:/GitHub/Depths. It uses the existing #255 goblin.blend master under build/local-spiders-goblin-v1/masters. The output is art/enemies/fortress-goblins-3d-v1. Run prepare_review.py with the same workspace, import the review folder headlessly, and use the private-desktop Godot launcher with --script res://check.gd. Use native-check as its report folder. Run package_review.py to verify the captures and build the gallery.

The original branch is codex/fortress-goblins-3d, stacked on codex/combat-roster-3d for the shared palette and motion contract. The string and silhouette are on codex/fortress-treatment-art. See [the follow-up review and rebuild](treatment-supply-art.md).
