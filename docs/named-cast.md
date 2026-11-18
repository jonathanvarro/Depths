# Named companion portrait review

[Review the likenesses at 192 and 96 pixels](../art/concepts/named-cast-v1/inspector.html). The owner approved Branna, Nessa and dirty-blonde Maelin on 2026-11-12. The introduction ideas below informed the named arrivals at the fire.

| Companion | Visual cues | Proposed introduction |
|---|---|---|
| Branna | Broad face, short grey hair, soot-marked reinforced work coat | Helps account for recovered miners’ belongings |
| Nessa | Angular face, uneven fringe, waxed cape and survey fold | Notices a discrepancy in an old survey |
| Maelin | Swept dirty-blonde hair and tucked braid, raised brow, asymmetric plum-black collar and a battered notebook | Examines a recovered sample and questions the party's explanation |
| Rook | Silver-streaked hair, moustache and goatee, burgundy brocade and neckcloth | Makes a small deal that shows his competence and appetite for profit |

Branna, Nessa and [dirty-blonde Maelin](../art/source/floor-four-finish-v1/maelin-v3.png) have unique animated PortraitSets under `data/portraits/named-cast-v1`. Each uses a clean character plate, complete replacement eyes and mouth, two blink and two talk frames, four condition overlays, and separate light masks. The exporter checks that the neutral layers reconstruct the approved 192 px image byte for byte. The gallery has paused 192 and 96 px frames, including closed eyes and speech together. The existing named recruits use the rigs. Saves with their earlier flat portraits acquire the matching rig when loaded.

Regenerate with `tools/art/build_named_portraits.py` and run `tools/art/check_named_portraits.gd` in Godot. Original source hashes and prompts are in [generation.json](../art/source/floor-four-finish-v1/generation.json).

Rook already uses the [Fixer-a PortraitSet](../data/portraits/fixer-v1/fixer-a.tres). It has its own clean plate, animation, conditions and lighting. Reserving this face from random recruits remains part of the Rook issue.
