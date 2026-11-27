# Area production briefs: the whole cave network

Owner direction (2026-11-26): a production list for every area, matching the
Damp Caves brief (`docs/damp-caves-production-brief.md`). It follows the new
area network the owner set out on 2026-11-25 (#300, ChatGPT's documentation
PR #301):

```text
Abandoned Mines (today's floor 1)
  `-- Damp Caves (today's floor 2)            <- the first junction
        |-- Cavern (today's floor 3, "Goblin Outskirts")
        |     `-- Rest Area (today's scouts' refuge / Overlook)
        |           `-- Goblin Fortress (today's floor 4)
        |                 |-- Throne Room [quest boss lair: the Goblin King]
        |                 |-- Jail [side route]
        |                 |     `-- Execution Halls [small, exceptionally hard boss lair]
        |                 `-- Drowned Galleries (today's floor 5)
        |                       `-- Black Reservoir (today's floor 6)
        `-- Fungal Hollows [side route; today's "Fungal Caverns" look]
              `-- Grove [small, exceptionally hard boss lair]
```

**The travel network itself is not built yet.** The game still goes down one
floor at a time. Branch lengths, exits, numbering and rest-route rules are
open under #300. This brief covers the **art and design** each area needs.
Claude builds the network (area IDs, paired exits and arrivals, saving,
seeds, the map) and hooks the art up.

Priorities: **P1** is needed for the area to look like itself and nothing
2D; **P2** makes it feel new; **P3** is later, or needs the owner's call.

## Conventions for every area

The Damp Caves brief's **Style** and **Conventions** sections apply to every
area here (Godot 4.7.2 Mobile renderer; CC0 or original; metric floor origin
and +Z out of the wall; flush wall pieces; full-face wall UVs; `set_motion`
still mode and the "flashes" preference; mood-only glow; budgets in
`catalog.json`; a `codex/` branch with an inspector, native phone captures
and a handoff doc; no gameplay authority in the art). Creatures use the 3D
contract in that brief's section I: concept sheet first, then the model with
`play`/`sample`/`set_motion`/`set_opacity`/`framing_bounds`, clips, and
roughly 1,200–3,000 triangles.

Each area's design deliverables follow the same shape as the Damp Caves
section G: shape rules in words, three to five ASCII reference sections in
the layout legend, where the landmarks, quest sites, lairs, named packs and
creatures sit, and a proposed encounter mix.

## Shared, network-wide pieces (P1, needed by every junction)

| # | Asset or design | Notes |
|---|---|---|
| N1 | **Exit art per destination** | Today every floor has one way down and one way up. Junction areas need several exits that look different and are recognisable from a distance: e.g. a wet water-cut shaft toward the Cavern, a spore-choked crawl toward the Fungal Hollows. Each needs a "way on" and a "way back" piece in its area's style. |
| N2 | **Exit signs** | A small readable marker per exit (miners' chalk, a scout's flag, a goblin totem), so the player knows where each one leads before committing. |
| N3 | **Map glyphs per exit and per area** | Small symbols for the full map and the corner map, plus an area name style for map titles and arrival messages. |
| N4 | **Arrival cards** | One painting per area for the first arrival (like the results and arrival art in `docs/results-and-rivals-art.md`). |
| N5 | **Boss-lair threshold kit** | For the Throne Room, Execution Halls and Grove: a clear, readable warning at the entrance (bones, banners, marks of the boss), so the player can still turn back before committing (owner direction, #300). |
| N6 | **Music and ambience per area** | One ambience bed per area (most areas have none of their own yet), and a short tense cue for boss-lair thresholds. |
| N7 | **Network design** | For #300: how long each branch is (in floors), whether branches rejoin, where exits sit relative to each other, and which areas are optional. |

## 1. Abandoned Mines (today's floor 1) — polish

Has one exit only, down to the Damp Caves. It's mostly 3D already.

- **P1, 2D leftovers to replace in the mine's style:**
  - Base dressing: `chalk-arrow`, `chalk-cross`, `chalk-tally`, `web-strand`, `rat-nest`, `puddle-small`, `puddle-wide`, `floor-gravel`, `tracks-drag`, `floor-crack`, `old-scorch`, `cracks-rubble`.
  - Landmarks: `root-curtain-a/b`, `root-foot-tangle`, `floor-crossing-root`, `collapsed-crates`, `split-barrel`, `fallen-banner`, `cache-rubble-planks`, `cache-spilled-grain`.
  - These also appear on later floors, so mine-style 3D versions serve everywhere until an area has its own.
- **P3:** the tutorial's starved rat and small spider are still 2D sprites (`starved_rat`, `small_spider`). Low priority: they only appear in the opening.

## 2. Damp Caves (today's floor 2) — the first junction

Everything in `docs/damp-caves-production-brief.md`, **plus:**
- **P1:** two different ways on (N1/N2): one toward the **Cavern**, one toward the **Fungal Hollows**, both readable as different from the start.
- **P1:** the "three knocks" story prop is a 2D sprite (`art/props/story-slice-v1/three-knocks`); make a 3D version in the Damp Caves style.

## 3. Cavern (today's floor 3, "Goblin Outskirts")

A large natural cavern on the goblins' doorstep: wide open spaces, high
shadowed roofs, goblin marks, watch posts and trophies spreading out from
the fortress. It leads to the Rest Area. Today it uses the mine's look plus
an "outskirts" dressing of 2D goblin props.

- **P1, theme surfaces:**
  - Natural cave wall and variant, floor and ceiling, distinct from both the mine and the Damp Caves: drier, darker, broader.
  - Unused families in `art/textures/descent-walls-v1` may help (`worked-cave`, `goblin-hold`).
- **P1, passages and exits:** a closed passage (goblin hide curtain or wicker screen), a blocked passage (goblin barricade), and ways on and back.
- **P1, 2D leftovers to replace:**
  - Outskirts props in `art/props/fortress-v1`: `goblin-mark`, `palisade`, `trophies`, `watch-post`.
  - Base dressing pieces `goblin-daubs`, `goblin-litter`, `hanging-trophies`.
  - The iron seam quest prop (`story-slice-v1/iron-seam`).
  - The goblin stash event prop (`cave-events-v1/goblin-stash`).
  - #246's 3D palisade, watch post and bracket already exist, so hook those up (Claude) and fill the gaps.
- **P2, dressing kit:**
  - Goblin camp debris: cook fires (cold and lit), bone piles, drying racks, crude totems, spike lines.
  - Cavern formations: tall columns, boulder fields.
- **P2, landmarks:** e.g. *the totem field*, *the goblin lookout*, *the collapsed bridge*, *the bone midden*.
- **P2, events:** goblin camp finds (a cooking pot, a trophy pole to loot, a sleeping-goblin ambush site).
- **Creatures:** today's floor-3 roster is all 3D: goblins, archers, drummers, guards, webspinners, venom spiders and rats. P3: goblin scouts with wolves or hounds, if the owner wants more.

## 4. Rest Area (today's scouts' refuge and the Overlook)

The underground camp the player and the quartermaster establish as a route
from the surface. Reaching it first is an earned milestone (#300). The
Overlook composition (`art/camp/overlook-v1`, owner-approved) is its "camp
screen".

- **P1:**
  - The approach area in first person: the room where the refuge sits, with a 3D scouts' campfire (today's `campfire-v1` refuge prop is 2D sprites; `campfire-3d-v1` exists to build from), tents and bedrolls, and a lookout over the drop.
  - It must read as safe at a glance.
- **P1, design:** how arriving by the surface route looks and feels, what the quartermaster's route costs or needs (with #296 / #299), and what services the Rest Area offers versus the surface camp.
- **P2:** a stash and quartermaster corner, a scouts' map table, and signs of earlier scouts who didn't make it.

## 5. Goblin Fortress (today's floor 4) — the second junction

A goblin-held stronghold built into the rock. It has **three exits**: the
Throne Room (quest boss), the Jail (side route) and the Drowned Galleries.
The Galleries must not need the Throne Room victory (#300).

- **P1, 2D leftovers:**
  - Fortress props in `art/props/fortress-v1` (`throne`, `palisade`, `watch-post`, `trophies`, `goblin-mark`).
  - The hall and gate features in `art/features/fortress-v1` (`hall-closed`, `hall-open`, `gate-barred`, `gate-broken`).
  - #246's 3D throne, palisade, watch post, walkway, cage and bracket exist (Claude to hook up); the gates and hall doors still need 3D with their closed/open/broken states.
- **P1, exits:** three distinct ways on (N1/N2): a grand barred way to the Throne Room, a low iron grate down to the Jail, a flooded culvert to the Galleries.
- **P2, dressing:** banners, braziers (lit and cold), weapon racks, goblin bunks, latrines, a drum stand. Make it dirtier and more lived-in than the Cavern.
- **P2, landmarks:** *the drum hall*, *the mess*, *the armoury*, *the gate yard*.
- **Creatures:** all 3D (goblins, archers, guards, brutes, drummers, the gate captain).

## 6. Throne Room — quest boss lair (the Goblin King)

- **P1:**
  - The arena set piece, using #246's 3D throne and platform, with braziers, bone heaps, trophy walls and the King's hoard chest.
  - The threshold warning (N5).
  - A layout in which the King starts before his throne with his guards in front (the current rules: `FortressDressing.king_cell`).
- **P2:** a victory state, with the throne toppled or the banners burning.
- The Goblin King is already 3D.

## 7. Jail — side route from the fortress

Cramped stone cells, iron and despair. A side route that leads on to the
Execution Halls. Its rewards should be worth the detour but not essential
(#300).

- **P1, theme:** dressed-stone cell walls, wet straw floor, low ceilings.
- **P1, props with states:**
  - Cell doors and bars (shut, open, broken).
  - Shackles and chains on walls.
  - The jailer's desk with a key ring (its key could open cells: a puzzle hook for Claude).
  - Cells containing prisoners' remains or belongings.
- **P2, events:** a living prisoner to free (a recruit or a story beat), a confiscated-gear store, a torture rack (keep it implied, not graphic), a ledger of who was taken.
- **P2, creatures:** goblin jailers (a whip and keys variant of the goblin base) and kennel hounds (the existing breach hound may serve).
- **P2, landmarks:** *the oubliette*, *the kennels*, *the warden's room*.

## 8. Execution Halls — small, exceptionally hard boss lair (off the Jail)

- **P1:**
  - A boss concept (owner approval first), for example **the Headsman**: a huge goblin executioner with a cleaver-axe and a hooded mask, who drags victims to the block.
  - A 3D model in the creature contract, with extra clips (`drag`, `execute`, `taunt`).
- **P1:** the arena set piece: the block, a gallows frame, pikes, blood gutters (dark and implied), a viewing balcony. Plus the threshold warning (N5).
- **P2:** a hoard and trophy that make the detour memorable.

## 9. Drowned Galleries (today's floor 5)

Flooded worked tunnels and waterworks. The theme surfaces and the
sluice/flow-gate machinery are already 3D. It leads to the Black Reservoir.

- **P1, 2D leftovers:**
  - Waterworks dressing (`waterworks-v1/dripping-channel`, `silted-lamp`).
  - The lower water gate quest prop (`story-slice-v1/lower-water-gate`).
  - The wounded keeper's body prop (it uses the opening's `fallen-a` sprite).
  - The lamp-eaters' lamp (`traps-lamps-v1/lamp`).
- **P1, passages and exits:** today the Galleries borrow the mine's webs, roots and pit. They need their own closed passage (a rusted sluice door), blocked passage (a silt choke or collapsed culvert), and ways on and back (flooded stairs).
- **P2, dressing:** pipes, valves, rusted rails under water, sunken carts, drowned miners' gear.
- **Creatures:** hollow miners, breach hounds, lamp-eaters and gas bloats are all 3D already.

## 10. Black Reservoir (today's floor 6)

The great dark water and the ancient stonework below the Galleries.

- **P1, 2D leftovers:**
  - The reservoir's water edge and wet stairs (`reservoir-finish-v1/water-edge`, `stairs`).
  - The ancient stonework vision prop (`ancient-stonework-v1`).
- **P1, creatures (2D sprites today, need 3D):** the underhound, the borrowed pack, the unfinished hound and the Marrow Shepherd (the lair boss). Use the existing approved designs in `docs/underhound-production.md`, `docs/shepherd-and-flow-gate.md` and `docs/descent-production-art.md`.
- **P2:** landmarks around the far shore, and the ending's descent (looks only today).

## 11. Fungal Hollows — side route from the Damp Caves

**Selected concept direction (2026-11-26, #306):** floating fairy light (not
necessarily hostile), two ordinary infested explorers, an aggressive root brute,
an armoured fungal elite and rooted-remains floor dressing. Regional green/branch
armour is a reward idea only. Seven selected plates, owner approval and the
numbered reference mapping: `docs/fungal-hollows-grove-concepts.md`. The generic
creature suggestions below are earlier proposals, not extra approved production.

The working rename of the Fungal Caverns. **Dense fungal growth**,
distinct from the wet bare rock of the Damp Caves (#300). The existing
fungal theme (`themes/fungal-caverns.tres`, `scripts/fungal_dressing.gd`,
the `cave-growth-3d-v1` fungi) is the starting point. It leads to the Grove.

- **P1:**
  - Push the look much further than today's floor 2: walls furred with mycelium, giant shelf fungi, stalks taller than the party, spore haze, soft glows.
  - Replace the 2D `moss-curtain` and the 2D fungus-pulse effect.
- **P1, passages and exits:** a closed passage (a membrane of fungal growth to tear or burn), a blocked passage (a fallen giant cap), and ways on and back.
- **P2, events:** spore puffballs (a burst with a boon or bane), edible and poisonous caps (food with a risk), a bioluminescent pool, a mycelium-wrapped corpse to search.
- **P2, creatures:**
  - Two or three fungal creatures, concept first: e.g. a spore-bloated rat, a sporeling (small, walking cap) and a rot crawler.
  - A named pack: e.g. *the Mycelium Mother's brood*.
- **P2, landmarks:** *the cap forest*, *the glowing pool*, *the rot pit*.

## 12. Grove — small, exceptionally hard boss lair (off the Fungal Hollows)

**Selected visual direction (2026-11-26, #306):** the **masculine Flower Knight**,
an elegant spear-and-leaf-shield secret boss with an intact purple bloom. Owner
explicitly accepted corrected v2. See `docs/fungal-hollows-grove-concepts.md`.
Heartrot below is the earlier placeholder proposal; existing resources remain
untouched. Its moves/clip suggestions are not automatically assigned to the
Flower Knight. No model or gameplay replacement is delivered in this concept task.

- **P1:**
  - A boss concept (owner approval first), for example **the Heartrot**: a vast fungal growth knotted around a long-dead tree, with grasping roots, spore bursts and captured bodies in its mass.
  - A 3D model, with extra clips (`spore_burst`, `grasp`, `regrow`).
- **P1:** the arena: a ring of giant fungi around the Heartrot, a shaft of pale light from far above, roots across the floor. Plus the threshold warning (N5).
- **P2:** a hoard and a unique reward for the side route.

## Suggested production order

1. Damp Caves (in progress) and the network pieces N1–N3, because every
   junction needs them.
2. The 2D leftovers on the main path (Abandoned Mines, Cavern, Fortress,
   Galleries, Reservoir), so nothing flat remains in normal play.
3. The Cavern's new look and the Rest Area, the next stretch of the main path.
4. Fortress exits, Throne Room, then Jail and Execution Halls.
5. Fungal Hollows and the Grove.
6. Black Reservoir creatures in 3D.
