# Floor 4 art finish and backlog review

## Live presentation

- **Discern.** The charcoal-blue tome has a split ochre seal, 128 and 64 px exports, and an item binding. The existing Holy Light, Bind and Watchful Eye tomes and votive candle use their delivered icons from #216. Item rules, effects and save IDs are preserved. [Discern source and exact built-in ImageGen prompt](../art/source/floor-four-finish-v1/generation.json).
- **Overhead party.** The climb's hanging roots could cover the player marker and look like extra limbs. They now hide with the overhead geometry, then return when the camera goes back to first person. The four lead models have fuller shoulders and sleeves and a shared muted fill in their palette. Their joints, clips, and floor registration are preserved.
- **The King on the dark stage.** A warm key and cool fill pick out his face, circlet and skull staff. His painted guards flank him. The camera excludes cave geometry behind the raised curtain so walls cannot cut through the model. It restores the cave before the exit fade. The tactical throne encounter stays on the board. See the [phone-size combat captures](E:/GitHub/Depths/build/local-party-board-v2/native-final).

## Related art requests

| Issues | Verified state | Remaining |
|---|---|---|
| #197–#200 | [Named-cast review](named-cast.md) with three new neutral studies and a review of the existing Fixer-a rig for Rook | Likeness and Rook identity review before creating the animated portraits or assigning named recruit IDs |
| #194–#196 | [22 regional shape candidates](../art/concepts/regional-equipment-v1/inspector.html). All seven replacement base icons, five salvage icons, the Light mace and Miner's sledge are live | Regional alternatives such as the sleeved quilted coat and tall guard shield need a shape or item decision |
| #218 / #220 | [Private chair contact captures](E:/GitHub/Depths/build/local-party-board-v2/chair-review), [padded-jacket swap review](E:/GitHub/Depths/build/local-padded-jacket-v2/review/inspector.html), and a [public 43 cm stool scene](../art/dressing/camp-stool-v1/stool.tscn) with its CC0 provenance | Both jacket fits and fixed seat placement passed the checks. The jacket hem still crosses the seat edge during the chair sequence, so contact polish remains open |
| #217 | Field cues are wired and the live sound fixture passed. [Listening gallery](../art/concepts/field-audio-v1/inspector.html) | Owner listening and mix review |
| #150–#152 | [Ten deeper-horror concept sheets](../art/concepts/descent-horror-v1/inspector.html), including the revised Bell and Sleeper. Underhound, Borrowed Pack and Marrow Shepherd have game sprite families | Review the remaining concept choices before producing further encounters |

The jacket and animation checks ran from a private copy. Its models, clips and captures remain in ignored local storage. Godot reported resource cleanup diagnostics at shutdown in some gameplay fixtures after their assertions passed.

To rebuild the figures, run `tools/combat_roster/build_roster.py` with Blender in background mode and pass `-- --workspace E:/GitHub/Depths --party-only`. The editable figure masters are in the local review's `masters` folder. Use `tools/art/export_floor_four_finish.py` to regenerate the Discern and named-cast review images.
