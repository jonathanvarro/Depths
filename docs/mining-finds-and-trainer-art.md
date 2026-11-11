# Floor 1 mining finds and camp skills trainer

## Mining finds (#256)

[Review the fresh and searched states](E:/GitHub/Depths/build/local-mining-finds-v1/inspector.html).
The timber rack keeps its frame and pegs after searching. The sound tools and shelf coal disappear, leaving a damaged haft. The seam is a continuous stratum with loose pieces below it. After working it, recessed dark rock, pale pick marks and coal dust remain.

The two event resources and their story builder use the dedicated scenes under art/props/mining-finds-3d-v1. They use the existing wall-placement and closed/empty visual contracts. The models use metres, +Z into the room, and one shared mine palette. The rack stands on its own feet and the stone face has a shallow return when an event has no adjacent wall. Loot, weights, requirements, time, prices and save fields are preserved.

The mattock icon shows a pointed pick and a broad adze on the same head. Coal is low and layered, alongside the more upright metallic Black ore. Native128 and direct-source64 exports are under art/items/mining-finds-v1. The earlier Miner’s sledge icon is inherited from the parent regional equipment branch. The [mining generation record](../art/source/mining-finds-v1/generation.json) has the built-in ImageGen prompts and source hashes.

## Camp skills trainer (#240)

[Portrait and shelter review](../art/concepts/mining-trainer-v1/inspector.html).
The proposed trainer is a veteran with cropped grey hair, a split eyebrow and a faded ochre scarf. The shelter has a rope-and-straw training post and practice staves. The neutral 192 × 192 portrait, transparent 512 × 256 shelter and separate Godot Node2D scene live under art/camp/skills-trainer-v1. Place shelter.tscn by its base-centre origin. At its baked scale it uses approximately 184 × 90 camp-canvas pixels. Placement, arrival, dialogue and lesson catalogue remain game work. The [trainer generation record](../art/source/skills-trainer-v1/generation.json) identifies both built-in ImageGen inputs and exact prompts.

## Checks and rebuild

The Godot review passed 16 headless and 24 Mobile checks with eight mounted prop captures at 1278 × 590 and 852 × 393. The 30-floor event regression reported zero failed assertions. Its headless run could not write the test save or log under user:// and reported existing scene teardown warnings. The isolated Mobile renderer passed and preserved foreground focus. Trainer artwork was checked as a transparent cutout and loadable scene. Physical iPhone and live trainer review remain pending.

Run tools/mining_finds/build.py through Blender 5.2 in background mode with --factory-startup --disable-autoexec --python-exit-code 1, then -- --workspace E:/GitHub/Depths. The editable prop masters are in the local review folder. Run tools/art/build_mining_trainer_art.py, import the branch, and run tools/mining_finds/check.gd with the local review folder after --. Use the #253 private desktop with native-check as the launcher output folder, then run tools/mining_finds/package_review.py with the same workspace. Both props use original geometry and existing mine materials.

The delivery branch is codex/mining-finds-trainer-art, stacked on codex/regional-equipment-icons.
