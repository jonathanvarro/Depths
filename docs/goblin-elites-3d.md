# Gate Captain and Goblin Brute in 3D (#251)

[Compare the two models](E:/GitHub/Depths/build/local-goblin-elites-v1/captures/lineup.png).
The [native pose inspector](E:/GitHub/Depths/build/local-goblin-elites-v1/START_REVIEW.cmd) lets you
pause, step at 24 fps, switch lighting, and check first-person and overhead framing.
Editable Blender masters are in the local review's masters folder.

| Enemy | Silhouette | Combat poses |
|---|---|---|
| Gate Captain | Forked iron crest, stacked pauldron, worn red cloth, cleaver and open brass horn | Ready to rally, horn blast, raised cleaver, regular slash and heavy cleave |
| Goblin Brute | Broader hunched shoulders, rough hide wraps, chipped two-handed maul | Regular swing, raised maul, heavy swing and lowered-maul recovery |

Both models have idle, hurt and grounded fall. The warning and recovery
poses loop while the intent is held. Reduced motion holds those silhouettes
and shows a fixed action frame. Both heavy strikes cue at frame 7.
The models face local +Z and stay within the existing 2 m cell
during the authored poses.

The Brute's natural encounter uses the model on the combat board. The
Captain's optional lair keeps its first-person battle stage and shows the
model there with the 3D-enemy setting on. Local stage lighting and the
stage layer keep the Captain clear of the cave walls. The Brute's intent tag
sits beside the model to give the maul room in the steep overhead view.
Turning the 3D-enemy setting off restores the painted sprites. Both use the
existing encounter rules.

The two rigs derive from the existing 57-bone [CC0 goblin](https://opengameart.org/content/goblin-1)
by CDmir and TinyWorlds. The original download and licence are kept in
`art/third-party/oga-creatures-v1`. The models add original kit, use the
shared cave-grain palette and ship with three skinned surfaces each.
Exact sizes, triangle counts, animation samples and hashes are in the
[model catalog](../art/enemies/goblin-elites-3d-v1/catalog.json).

Godot 4.7.2 Mobile passed 501 model checks and saved 82 review captures.
The largest sampled Blender-to-Godot bounds difference was 7.1 mm.
The 1278 × 590 live encounter fixture and the headless fortress regression
also passed. The live fixture ran on a separate desktop and verified the
Brute's wind-up and recovery, the Captain's rally and model-off sprite,
and restoration of the cave camera. Physical iPhone review is pending.

## Rebuild and review

Run `tools/fortress_goblins/build_elites.py` with Blender 5.2 in background
mode, passing `-- --workspace E:/GitHub/Depths`. It uses the existing
`build/local-spiders-goblin-v1/masters/goblin.blend` and exports only this
pair. Run `tools/fortress_goblins/prepare_review.py --workspace E:/GitHub/Depths --elites`
and import the local review and checkout headlessly. Use the [private desktop launcher](background-asset-checks.md)
for `res://check.gd` in the review and `res://tools/enemy_models_check.gd` in
the checkout. The body rig, palette and published master it derives from are
shared with the fortress set.
