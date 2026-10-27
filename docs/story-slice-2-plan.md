# Story, slice 2: the Drowned Galleries (plan for review)

Drafted 2026-10-26 by Claude from the owner's answers to
[the slice-2 options](story-slice-2-options.md). Nothing here is built
yet: the owner reviews this plan first. Decisions go to #122 and
DESIGN.md.

## The owner's answers

| Question | Answer |
|---|---|
| What is the relic? | **Something alive.** A heart or an egg in the deep that's waking. |
| Who really wants it? | **Commander Vael, for himself,** using the king's name. |
| Who caused the ambush? | **The dark elves.** |
| What do the elves want? | **They're its old keepers.** They kept it asleep, and want it back. |
| Below the fortress | **The Drowned Galleries** (floors 5–6). |
| Campaign length | **12 floors,** six layers ending at a temple (#125). |
| First vision | **The living thing,** felt when a hero touches the old stonework. |

## How it fits together

- **What sleeps below** is alive and waking. The gas and the monsters are its breath and its dreams leaking up through the breach the miners made. The deeper the party goes, the stranger the creatures, as the art direction already describes.
- **The elves are its keepers.** For generations they kept it asleep. When the king's vanguard came down looking for "the relic", the elves ambushed them to keep anyone from reaching it. So the elves really did kill your companions. They're guilty, and they believed they had no choice.
- **Vael** wants the living thing for himself. The king wants the breach closed; Vael tells him it can't be done without the relic. He's patient and reasonable, and quietly ruthless.
- **The player's question across the campaign:** the elves murdered your friends, but they may be right. Do you help them, or Vael, or neither?

### Continuity with slice 1

*Those Left Behind* already found **a route map in a stranger's hand** and **an odd goblin arrow**. Slice 2 pays them off:
- The arrow is **elf-made, dressed as goblin work.** The apprentice smith finds a black feather from it in your pack (a new talk line).
- The map's hand is **elf script.** It can't be read yet; a wounded elf on floor 5 can read it.

The truth comes out in steps, never from a single note.

## Floors 5–6

### Floor 5: The Drowned Galleries
- **Feel:** ankle-deep passages, black pools and dry ledges. It's the fortress's old water system, which the goblins inherited and half understood.
- **New floor rule: water.** Some passages are flooded (deep water cells). Wading through costs extra time and nerves and soaks a torch (its burn time halves while wading). A lantern is fine. This makes the lantern matter more.
- **The route problem:** the stairs down sit behind the main sluice. Find the sluice wheel and open it to drain one wing.

### Floor 6: The Black Reservoir
- A great cistern, with walkways and sluices, and something moving below.
- **The route problem:** divert the flow to expose the descent. The floor changes for the rest of the day.
- **A mini-boss here:** the Marrow Shepherd (see Monsters).

## Quests and conversations

| Quest | Given by | Floor | What happens |
|---|---|---|---|
| **The Black Fletching** | the smith (visible) | camp | The apprentice finds a black feather in your pack: "That's not goblin work. Someone wanted you to think it was." |
| **The Wounded Keeper** | hidden package | 5 | A wounded dark elf, cut off from her people, in a dry room among the pools. Help her (a draught or a dressing) or leave her. Helped, she reads the map: it's the vanguard's route, marked by her own people. She admits the ambush, and why. |
| **The Dry Passage** | Vael (visible) | 5 | Open the main sluice. Vael's reason is the descent; his questions afterwards are about "what's down there". |
| **The Stonework** | hidden package | 6 | Old carved stone at the reservoir's edge. Touching it plays **the first vision** (blue tint): a slow heartbeat through rock, something vast turning in its sleep. No words, just the sense of it. Afterwards each hero says one line. |
| **The Reservoir** | story | 6 | Divert the flow and expose the way to floor 7. It ends the slice with a camp scene: Vael hears about the elf and the heartbeat and becomes very interested. |

**At the campfire afterwards:** a short talk where the party argues over the elf. She killed your companions, but she says the thing below must stay asleep. No choice is forced yet; slice 3 picks it up.

**What carries over:** whether you helped the keeper is saved, and later slices react to it.

## Monsters for floors 5–6

The new monsters come from ChatGPT's approved concepts (#150, "wrong animals"). They're the first creatures from the living thing's dreams, and they're stranger than the breach family:

| Monster | Floors | How it fights |
|---|---|---|
| **Underhound** | 5–6 | Like a breach hound, but its jaw extends: it winds up a long lunge that reaches the back row. Defending blunts it. |
| **Borrowed Pack** | 5–6 | Three heads, one hide. Hitting one hurts the shared body; killing a head pulls the others off balance (they lose their next action). |
| **Marrow Shepherd** | 6 (mini-boss) | Carries sleeping hounds in a bone cage. Every few rounds it births an unfinished hound. Kill it before the cage empties. |

**Joining them:**
- **Hollow miners** (drowned, in the Galleries).
- **Breach hounds and lamp-eaters.**
- **Elves:** not as foes yet; only the keeper appears.

**Art needed from ChatGPT:**
- Production sprites for the three monsters, with poses and states like #141.
- Water-floor surfaces: pools and wet walls.
- The sluice wheel prop.
- The wounded keeper's portrait (elves concept: `docs/elves-concept.md`).
- The stonework prop.

## Recruit memories (#118)

Built alongside, because it makes losing people in the deeper floors hurt more.

- **What a memory is:** each hero keeps up to three short facts the game can prove, such as:
  - "Pulled Corin from a hollow miner's grip (day 6)";
  - "Survived at 1 health on floor 3";
  - "Was there when Bren fell";
  - "Killed the Broodmother".
- **Where they show:**
  - on the hero's card, as a "Remembers" line;
  - in homecoming quotes ("Since the Broodmother, I check every web twice.");
  - in a grief line naming the hero when they die.
- **New moments with a line from the hero involved:**
  - levelling up;
  - first daylight after a hard trip;
  - a friend falling mid-fight.
- **Saving:** memories are saved and checked across a save and load.

## Build order

1. **Recruit memories.** These need no art, so they can start now.
2. **Floor 5:** the water rule, the sluice, *The Arrow*, *The Wounded Keeper* and *The Dry Passage*. Placeholder art until ChatGPT's arrives.
3. **New monsters,** once their art lands. Then the bot is extended to floors 5–6, with difficulty tuned to roughly 24 of 30.
4. **Floor 6:** the reservoir, the vision and the slice's ending.

The second-site plan stays in reserve. The twelve-floor descent (#125) is now the campaign's shape: floors 7–12 are later slices.
