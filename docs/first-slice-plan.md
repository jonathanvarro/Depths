# First story slice: build plan

*2026-10-20 · For owner review before building. It turns the "practical first slice" of [the cave descent proposal](cave-descent-and-quests.md) (#125) into concrete work. Story: #122. Quests: #123. The fallen companions: #107. Nothing here is built yet.*

## What the player experiences

1. **The commander scene.** The hero escapes the cave (the existing opening). Outside, the king's forces are waiting, and the **knight commander** questions them: did they find it? The player answers with one of a few short choices, such as "We were ambushed" or "Not yet". He sends them to camp with a first order.
2. **Those Left Behind** (visible quest, from the commander). Somewhere on floor 1 is the place where the hero's party fell. The player fights through to it, searches it, and chooses what to bring back as evidence. Reporting to the commander at camp closes the quest and opens the first questions about the ambush.
3. **Three Knocks** (hidden quest, no prompt). On floor 1 or 2, a side passage has fresh dust, an abandoned cup and a faint tapping. Behind the rubble, a trapped miner waits. The party can:
   - spend time and light bracing the passage and lead the miner out, or
   - mark the spot for a camp crew, who bring the miner back after the next return.

   Either way the miner turns up at camp, grateful, and tells them where there's an iron seam.
4. **Iron for the Apprentice** (visible quest, from the smith once he's arrived). Bring back a sample of iron ore from a marked seam. In return the smith can forge one new weapon, which you then buy with gold as usual.
5. **The fortress service route.** On floor 4, a goblin service passage leads to a **lower water gate**, with no need to fight the queen. Reaching it shows the first view of the flooded galleries below. That's where the slice ends: "the way down continues". The queen becomes a side quest with her bounty, no longer the campaign's ending.

## Systems to build

| # | System | What it does | Main files |
|---|---|---|---|
| A | **Quest state** | Each quest has an ID, a stage (unknown → offered → active → resolved) and flags (e.g. "miner rescued", "crew sent"). It's saved with the campaign, and kept separate from the floor seed, so daily cave changes don't forget it (proposal §"Daily regeneration"). | new `scripts/quest_state.gd`, `camp_state.gd`, `main.gd` save/restore |
| B | **Conversations** | A portrait and a speaker name, short lines, and 2–3 reply buttons. Replies can set quest flags. Conversations are data files, so story text can change without code. It reuses the event screen's look, with the speaker's portrait added. | new `scripts/conversation.gd` (resource), new `scripts/conversation_screen.gd`, `data/conversations/*.tres` |
| C | **Camp talk** | People at camp offer conversations when they have something to say: the commander at the camp's command post (or the fire), and the smith and nurse in their own activity views. A small marker on a site shows there's news. | `camp_screen.gd` (coordinate with ChatGPT, who is working on the camp) |
| D | **Quest log** | A short list in the Pack: active quests with the next step and whom to report to. Hidden quests appear only once found. | `pack_screen.gd` (a new tab or section) |
| E | **Quest packages on floors** | A package is a small hand-made piece of maze: one or two rooms, its own events and props. While it's active, the floor generator places it into a generated floor. It goes into a dead-end branch off an existing room, never on the only way to the stairs. If it can't fit, the generator tries another seed offset, and always places a required package (never silently drops it). | `floor_generator.gd`, new `scripts/quest_package.gd` (resource), `data/packages/*.tres`, `dungeon_map.gd` |
| F | **Quest events** | Room events that belong to a package: fixed, not picked at random. They can check and set quest flags (building on the #114 room flags), and can hand over quest items such as evidence or iron ore. | `room_events.gd`, `event_outcome.gd`, `event_choice.gd` |
| G | **Smith project** | Delivering the ore unlocks one forged weapon in the smith's stock, which is then bought with gold. | `camp_state.gd` stock, `camp_screen.gd` smith view |
| H | **Fortress lower gate** | The fortress also marks a lower water gate reachable without the queen's hall. Reaching it plays the slice's ending beat. The queen's death pays the bounty but no longer ends the cave. | `fortress.gd`, `main.gd` (`_queen_defeated` wording, the victory illustration) |

## Build order

Each step ends playable and tested, and is committed separately.

1. **Quest state, conversations and the commander scene** (A, B). The opening's results card is followed by the commander conversation, and its reply sets the first flag. Test: the scene works for Mara, Corin and Alwen, and it survives saving.
2. **The quest log and camp talk** (D, C). The commander's first order appears in the log; at camp he has a line for each stage.
3. **Packages in the generator** (E), proven first with an empty test package, then **Those Left Behind** (F): the ambush site on floor 1, the fight, the evidence choice, and reporting back. Test: over 400 seeds, a required package always fits, the stairs stay reachable, and the quest's state survives a day passing and a reload.
4. **Three Knocks**: the hidden package, its two ways to solve it, and the miner arriving at camp.
5. **The iron project** (G): the seam, the ore, and the smith's forged weapon.
6. **The fortress lower gate** (H), plus the new wording for the queen and the slice's ending.
7. **Playtest**: teach the campaign bot about the quests, rerun the balance report, and do a full manual pass with screenshots.

Rough size: steps 1–3 are the largest (new systems); steps 4–6 mostly add content on top of them.

## Art and writing needed (for ChatGPT)

- **Knight commander:** a portrait in the hero portrait style (the main-heroes rig), plus a version for the commander scene. The scene needs a backdrop of the cave mouth with soldiers waiting; the title-screen style can carry it at first.
- **Miner:** a recruit-style portrait.
- **Ambush site props:** the fallen party's camp, scattered gear, and a few distinct evidence pieces (their reuse of the opening's body art is fine).
- **Three Knocks props:** a rubble pile with a gap, a cracked support beam, and the abandoned cup.
- **Iron seam prop** (with a used state), and an **iron ore** item icon.
- **Lower water gate:** a feature with a view of dark water below.
- **Icons:** a quest-log icon and a camp "news" marker.

Placeholders let the code go ahead first, as before.

## Decisions I need from you

1. **The commander, for this first scene:** a name, and a first impression. My suggestion: **stern but fair on the surface**, so his later turn (if any) has room to grow.
2. **The ambush evidence.** It should raise questions without answering them. My suggestion: the party's own route map, marked in a hand none of them used, plus a goblin arrow fletched with something goblins don't use. Or is there something you'd prefer?
3. **Three Knocks: rescue now or send a crew?** I suggest both work. Rescuing costs time and light, and may draw a fight. Sending a crew is safe, but the miner only arrives after the next return.
4. **The iron project's reward:** one forged weapon. My suggestion is a **"camp-forged blade"**: 4–6 damage, light enough for any hero, sold at 45 gold. Or should it be armour?
5. **Can quests be missed?** I suggest no, not in this slice: everything waits for the player.
6. **The slice's ending:** at the lower water gate, show a short scene ("the way down continues"), then carry on playing in the cave as now. Alternatively, an end card for the demo?
7. **The opening's bodies:** the ambush site on floor 1 is a new place built from the same bodies and art, so the opening itself doesn't change. Is that right, or should the opening room itself become the quest site?

## Not in this slice

- New floors (5+).
- Other gathering materials.
- Later commander and rival story beats.
- More levels.

These all wait until this slice has been played and reviewed (#119).

## Decided (owner, 2026-10-20)

The owner accepted every suggestion above:

1. **The commander:** stern but fair on the surface. Working name **Commander Edric Vael** (placeholder; rename freely).
2. **The ambush evidence:** the party's own route map, marked in a hand none of them used, and a goblin arrow fletched with something goblins don't use. It raises questions; it doesn't answer them.
3. **Three Knocks:** both ways work. Rescuing now costs time and light and may draw a fight. Sending a crew is safe, but the miner arrives only after the next return.
4. **The iron project's reward:** a **camp-forged blade** (4–6, light, 45 gold) in the smith's stock.
5. **Quests can't be missed** in this slice; everything waits.
6. **The slice's ending:** a short scene at the lower water gate ("the way down continues"), then play carries on.
7. **The ambush site** is a new place on floor 1, built from the opening's bodies and art. The opening itself is unchanged.

## Built (2026-10-20)

All six build steps are in: f8168bb and the commits before it.

**The campaign playtest bot now follows the story.** Over 90 campaigns (30 per hero, 45 days max):

| | Mara | Corin | Alwen |
|---|---|---|---|
| Those Left Behind done (median day) | 3 | 2 | 2 |
| Three Knocks done | day 3 (30/30) | day 2 (30/30) | day 2 (29/30) |
| Iron for the Apprentice done | day 3 | day 3 | day 3 |
| Lower water gate reached | day 6 (30/30) | day 6.5 (30/30) | day 6 (30/30) |
| Queen dead (side quest) | 24/30 | 27/30 | 18/30 |
| Stuck runs | 0 | 0 | 0 |

- The slice's story content takes about a week of in-game days.
- The queen remains the hardest fight and is now optional.
- Alwen's queen result (18) is lower than the last balance run (23). The extra quest fights change every campaign's course, so treat it as noise until it's seen twice.

**Not done:**
- Real art (see the art list above).
- A hand-played pass through the slice.
- Rebuilding the exe.
