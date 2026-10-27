# Depths roadmap

*Rewritten 2026-10-27 from the open and closed issues (26 open, 141 closed), DESIGN.md and the commit history. Update it when a phase moves. The October 18 version is in the git history.*

## Where the project stands

**The first slice is complete and played:** the opening escape, camp, floors 1–4, the goblin fortress, an optional queen and the lower water gate. It has been played on the owner's iPad.

**The second slice has started:**
- The story is decided ([plan](story-slice-2-plan.md)).
- Floor 5, the Drowned Galleries, is built with placeholder art.
- Floor 6 and the new monsters are next.

The campaign is now planned as **12 floors** in six layers, ending at a temple (#125).

### Built and working

| Area | What's in |
|---|---|
| **Story** | Commander Vael. *Those Left Behind*, *Three Knocks*, the iron sample, the lower gate. Slice 2 so far: *The Dry Passage*, *The Black Fletching* and *The Wounded Keeper*. |
| **Exploration** | Procedural floors with quest packages, lairs and territories. Traps, landmarks and room events with the coin flip. Wandering monsters. Deep water on floor 5. A hand-drawn map. |
| **Party** | Three main heroes plus recruits in four roles (Warden, Scout, Brawler, Fixer) with exploring perks. Levels, talents, injuries, strain and hunger. Banter and memories. |
| **Combat** | Intent icons and 20 monster types, with elites and depth scaling. Mini-boss lairs. Strike first and slip past (Scout talents). Flare. The queen. |
| **Camp** | Tent and stash, merchant, smith, nurse, recruits at the fire, contracts, routes and quests, all fitting on screen without scrolling. |
| **Platform** | Saving, settings, phone layouts, and Windows and web builds. The iPad is reached over home Wi-Fi. |
| **Testing** | 45+ automated checks, three opening play-throughs, and a campaign bot (target: queen dead in about 24 of 30 campaigns per hero). |

## Phase A: Finish slice 2, the Drowned Galleries *(now)*

1. **Floor 6, the Black Reservoir:**
   - divert the flow to expose the descent;
   - the old stonework and the first vision (the living thing, in the blue tint);
   - the slice's ending scene with Vael.
2. **The new monsters,** from ChatGPT's #150 concepts:
   - Underhound (a long lunge at the back row);
   - Borrowed Pack (three heads, one hide);
   - the Marrow Shepherd, a floor-6 mini-boss that births hounds.

   Behaviour and numbers can start with placeholders. Art: #166.
3. **The playtest bot goes down to floors 5–6.** Then retune so slice 2 is as hard as intended.
4. **Polish what floor 5 left:**
   - deep water on the map;
   - the wanderer clock saved with the game;
   - a properly wet look for the walls (#166);
   - ChatGPT's sounds and ending cards (#167).

**Done when:** a player goes from the lower gate through floors 5–6 to the reservoir's ending, the bot's results are on target, and the placeholder art is replaced.

## Phase B: Play it whole *(alongside)*

- **#119:** an owner playtest of the whole campaign so far, on the iPad. Note pacing, difficulty and anything confusing.
- **#118:** the playtest question: whom would you hate to lose, and why?
- **Hero balance:** Alwen wins least often in the bot (21 of 30, against Corin's 25).

## Phase C: Look and sound *(when ChatGPT's art and audio land)*

- **#54:** music and recorded sound, replacing placeholders (#167 starts it).
- **#51:** one shared interface style across every screen. The owner chooses the direction.
- **#128:** wall and ceiling dressing. **#89:** camp warmth.

## Phase D: Deeper systems *(each needs a decision first)*

- **#53:** magic, starting from Alwen.
- **#76:** weapon traits or body-part targeting.
- **#123:** quest rules: the log, missable quests, rewards.
- **#133 and #135:** the remaining shrine, boon and trinket ideas.
- **#106:** trust between party members (low priority). **#110:** paper-doll equipment (later).

## Phase E: iPhone *(when a device is free)*

- **#20:** the iPhone export: signing and TestFlight.
- **#66:** check the Pack and hero windows on a real landscape iPhone.

## Beyond slice 2

- **Slice 3** picks up the keeper's choice: the elves murdered your companions, but they may be right. Vael's interest grows.
- **Floors 7–8,** the Mosslit Hollows and the Garden of Echoes, as proposed in #125.
- **The monsters keep getting stranger** with depth (#151, #152): wrong animals, then impossible bodies, then living phenomena.
- **The campaign ends at the temple on floor 12,** where the living thing sleeps.

## Next top tasks

| # | Task | Why now | Size | Waits on | Issue |
|---|---|---|---|---|---|
| 1 | **Floor 6, the Black Reservoir:** diverting the flow, the vision, the slice-2 ending | Finishes the slice the owner approved | Large | Nothing (placeholders) | #122 |
| 2 | **New monsters:** Underhound, Borrowed Pack, Marrow Shepherd | Floors 5–6 reuse floor-3 foes today | Medium | Art from #166 (can start without it) | #150, #166 |
| 3 | **Bot to floors 5–6, then retune** | The new floors' difficulty is untested | Medium | Tasks 1–2 | #119 |
| 4 | **Owner iPad playtest** of wanderers, memories and floor 5 | Real feedback before more is built | Owner | The current iPad build | #119, #118 |
| 5 | **Map and save polish:** water on the map, the wanderer clock saved | Small gaps floor 5 left | Small | The map symbol from #167 (optional) | — |
| 6 | **Hero balance for Alwen** | The weakest start, by the bot | Small | — | — |
| 7 | **Hook up ChatGPT's slice-2 art and sounds** | Replaces the placeholders | Medium | ChatGPT (#166, #167) | #166, #167 |
| 8 | **Shared interface style** | One look across screens | Medium | Owner decision | #51 |
| 9 | **Magic system** | The biggest remaining design gap for a healer | Large | Owner decision | #53 |
| 10 | **iPhone export and device check** | Release readiness | Medium | A device | #20, #66 |
