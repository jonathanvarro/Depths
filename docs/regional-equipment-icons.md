# Regional equipment icon first pass (#194 / #195)

[Review both updated icons and the decisions on all 22 original candidates](../art/concepts/regional-equipment-v1/inspector.html).

- **Cave & Mine.** The Quarry Hammer master now supplies the actual Miner's sledge picture in the tool-rack loot. The square iron head makes it distinct from the wooden club it previously used.
- **Goblin Territory.** The generated Light mace base now uses a distinct icon with a small chipped iron head, crooked ash haft and worn oxblood binding. The founder's mace retains its existing picture. The heavier Gatebreaker Mace remains a separate concept.

The new mace master was made with built-in ImageGen. Its [exact prompt and source hashes](../art/source/regional-equipment-v1/generation.json) are retained. The Quarry Hammer source and prompt are in the [earlier regional master record](../art/source/early-equipment-v1/generation.json). The builder reduces both masters directly to 128 and 64 px using the established palette and alpha rules. The only game data edits are the two icon references. The original candidates and source files remain in their earlier locations.

The review table identifies which shapes are already represented by live equipment, which differ materially from a live item, and which have no matching base. The sleeved quilted coat, tall goblin shield and other nonmatching variants remain candidates.

Thirty Godot headless checks and 42 Mobile checks passed. The latter include 12 captures of the real Pack, loot and merchant screens at 1278 × 590 and 852 × 393. The tests cover old generated mace restoration, all five mace quality rolls and RNG, founder art and the two item bindings. The Mobile run preserved foreground focus. Captures and logs are in [the local review folder](E:/GitHub/Depths/build/local-regional-equipment-v1). Physical iPhone review remains pending.

Rebuild with tools/art/build_regional_equipment_icons.py and run tools/art/check_regional_equipment_icons.gd with the absolute review folder after --. The feature branch is codex/regional-equipment-icons.
