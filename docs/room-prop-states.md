# Resolved room props · #46

The current room events already had initial prop art. This pass adds the requested resolved appearances while preserving their placements, interactions and rewards.

| Event | Resolved appearance |
| --- | --- |
| Old workings | Exhausted rock seam, empty basket and a dropped pick |
| Pale idol | Empty niche with a pale dusty impression and small chips |
| Still pool | Murky water with broad ripples and stirred sediment |
| Dry alcove | Flattened bedding and cold ashes |
| Old campsite | Spread pale ashes, spent char and flattened bedroll |
| Tripwire | Cut, slack wire ends and shifted trigger |
| Hollow floor | Open dark pit inside the broken stone rim |
| Rigged strongbox | Its own small rusty iron box, opened and empty with a released spring |

## Asset locations

`art/props/room-states-v1/` contains the seven used textures and matching scenes plus the strongbox's own closed/used textures and scene. All eight event resources point to these stateful scenes. Other original props and their textures remain unchanged. Existing abandoned-pack and goblin-stash state changes remain in place.

The existing `container.gd` contract drives `state = "closed" / "empty"`. Each used scene retains its original Sprite3D transform, pixel size, filtering and orientation; pool and hollow floor remain horizontal floor props. Exports use full 128×128 transparent canvases and at most 32 colours. Upright used variants receive only a vertical registration adjustment to match their original ground contact; they are not individually fitted to new silhouettes. Flat variants retain the canvas centre.

`art/features/stone-stairs-v1/` supplies up/down artwork and stone/fortress scene variants. Both themes use these dedicated stair props. Down scenes include a floor mesh in the theme's floor material because LevelBuilder omits the ordinary floor tile at a descent. Cave roots/pit and the opening's daylight exit remain unchanged.

## State and visibility

Main changes a prop only when the event resolves. “Leave it” preserves the initial appearance. Existing `DungeonMap.triggered` state restores resolved art after rebuilding a floor or loading a save; no save fields were added.

Unresolved traps remain hidden unless the party has Keen eyes. On resolution, a previously hidden trap gains its spent prop immediately, and every hero can see those remains on a later visit. Enemies continue to ambush. The collapsed pit and the spent spring are visual evidence of the existing resolved event, not new collision, repeated trap damage or extra rewards. Stair traversal still uses the existing repeatable grid interaction.

## Sources and rebuilding

Built-in **ImageGen** authored the used variants, iron strongbox states and stair artwork. Original masters and the exact prompt/reference set are preserved in [`art/source/room-states-v1/`](../art/source/room-states-v1/) and its `generation-manifest.json`, excluded from Godot import. No paid API fallback was used.

`tools/art/build_room_states.py` exports registered runtime textures, scenes, catalog, before/after review sheets and a source/output hash report. `--wire` updates only the eight event art references and the stone/fortress stair scene references. `tools/art/validate_room_state_exports.py` verifies all ten source masters/prompts, eleven exported textures, opaque water/pit interiors, preserved original textures, local documentation links and unchanged choices/outcomes in all eight event resources. Original material textures and event choices/outcomes are unchanged.

## Review and checks

[`art/concepts/room-states-v1/`](../art/concepts/room-states-v1/) contains dark/light before-and-after sheets, actual Main desktop/phone captures, export registration/hash validation and runtime results. `tools/art/check_room_states.gd` exercises actual event completion and leaving, resolved/unresolved trap visibility, floor rebuilding, existing save serialization and repeatable stairs. It compares every inherited prop transform with the original. The isolated review room deliberately places one prop ahead of the real party camera; it is a presentation fixture, not a new shipped room layout.

Godot 4.7.2 Mobile renderer: **250 checks pass with 44 desktop/landscape-phone captures**, including the final stair placement. Existing fortress and full opening playthrough checks also pass, with clean engine error logs. Native/48px dark/light sheets supplement those actual views. The floor-mounted pool and collapsed pit are captured from two cells back so their complete silhouettes fit the forward camera. Stairs use front-facing perspective art like other world props; descending stairs are lower than the ascending flight. [Before/after overview](../art/concepts/room-states-v1/overview-dark.png). Physical iPhone testing remains separate.
