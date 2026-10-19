# Depths roadmap

*Written 2026-10-18 from the open and closed issues, DESIGN.md and the commit history. Update it when a phase moves.*

## Where the project stands

The **first playable is very close to whole**: DESIGN.md defines it as the cave and the campsite as one complete loop. 101 issues are closed and 20 remain open. Most of the open ones are ideas waiting for a decision rather than unfinished work.

### Built and working

| Area | What's in |
|---|---|
| **Opening** | The escape tutorial (#30, #55–#59, #69): Mara (or Corin or Alwen, #95) wakes among the bodies, takes a weapon, learns torches, fights, and climbs out. |
| **Exploration** | Procedural floors, doors, stairs, a full-screen map, a hand-drawn parchment map (#50), visible room props with used states (#46), and room events with the coin flip (#16, #77). |
| **Party** | Three main heroes plus recruits (#41, #83, #95). Covers health, injuries, strain, hunger, bleeding, stats, levels and XP (#47), armour (#93), and rows (#72). |
| **Combat** | Turn-based, with intentions shown as icons (#60). Enemy tactics, coin-flip killing blows, nine monster types, and the goblin fortress and queen (#44). Hits show as slashes, numbers and icons with no text log (#105). |
| **Camp** | Rest and days, nurse recovery, stash, merchant, smith, contracts, recruits, the secured route and training (#40–#43, #79, #85–#88). |
| **Economy** | Gold, treasure, prices, and a free kit that's limited (#42, #86, #90–#92). |
| **Platform** | Saving and loading (#45), settings (#52) and a Windows build (#19). Placeholder sound (#7). |
| **Art** | ChatGPT's portraits, enemies, cave and fortress textures, props, treasure, UI glyphs, and campaign illustrations. |

### Still open, grouped

- **Finishing the first playable:** #108 camp layout, #64 condition readability (first pass built), #51 shared UI style, #54 music and sound, #99 fortress art (checklist done, issue still open), #48 equipment (only the shield is left), #105 art (replacing the placeholder icons).
- **Ideas needing a decision:** #73 sneak past or strike first, #94 traps, #107 the story of recovering the bodies, #104 leg injuries and carrying, #76 weapon traits or body-part targeting, #74 light as a weapon, #80 the king's forces, #101 exploration classes, #53 magic, #106 trust.
- **Phone:** #20 iPhone export, and #66 checking the screens on a real device.

---

## Phase 1: Finish and prove the first playable *(now)*

**Goal:** someone can play from the title screen to the queen's defeat and back to camp. The run should hit the DESIGN.md success criteria: the party is tempted to push on, the reasons to leave are clear, and the condition of the party can be read at a glance.

1. **A full campaign playtest.** Play through the opening, several expeditions, floors 1–4, the gate and the queen. Note pacing, difficulty and confusing moments.
2. **A balance pass** with the new monsters, levels and armour. Rerun `tools/balance_sim.gd` and tune the XP limits and the queen fight against the playtest.
3. **#108: recompose the camp** as a connected place (ChatGPT's art, then the hookup).
4. **#51: shared interface style.** You choose the typography and the direction; then one Godot theme goes across every screen.
5. **#54: sound and music.** Pick from the auditions, then add music for the title, the cave, combat and the camp.
6. **Close-outs:**
   - #99 (fortress art) and #48 (add the shield, or move it to a new issue)
   - swap in ChatGPT's #105 icons
   - #64 player check

**Done when:** a new player finishes the cave without explanations from us, and the playtest notes show no blocking confusion.

## Phase 2: Decisions in the dark *(next)*

**Goal:** exploration choices matter as much as fights. These ideas extend what's already built rather than adding new systems.

- **#73 Sneak past or strike first:** a choice before a fight, using light, noise and scouting. Probably the biggest gain for strategy.
- **#94 Traps and tripwires:** built on the tripping animation and the new sprung-trap props.
- **#107 Story:** go back down for the bodies, and learn it was an ambush. This gives the first expedition a purpose and camp its first story beat.
- **#104 Leg injuries lower carrying capacity,** tying injuries to the economy.
- **#74 Light as a weapon** in fights (the torch throw exists already).

## Phase 3: A deeper party *(later)*

**Goal:** more variety between heroes and runs. Each item needs a design discussion first.

- **#53 Magic system**, starting from Sister Alwen the healer.
- **#101 Classes that change exploration**, including the Fixer.
- **#76 Weapon traits or body-part targeting.**
- **#80 The king's forces arrive over the days** (builds on the secured route, #79).
- **#106 Trust between party members** (low priority).

## Phase 4: Phone release readiness *(in parallel when a device is free)*

- **#20 iPhone export setup:** signing and a TestFlight build.
- **#66 Check on a real landscape iPhone:** the Pack, hero windows, touch sizes and the safe area.
- A performance check on older devices, and settings for text size and flashes.

## Beyond the first site

DESIGN.md's campaign direction, not yet broken into issues:
- more sites after the cave (a castle, then a portal), each with its own refuge
- carrying heroes and their history between sites
- shortcuts and revisits

Start this only once Phase 1 proves the cave loop.

---

## How the work is shared

- **You:** design decisions (recorded on issues and in DESIGN.md) and playtests.
- **Claude:** game code, tests (`tools/*_check.gd`) and builds.
- **ChatGPT:** art, research and audio. Each piece arrives with its own check tools.
- Placeholders let the code go ahead before the art is ready.
