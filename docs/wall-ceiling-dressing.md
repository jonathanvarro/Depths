# Wall and ceiling dressing: art request

*2026-10-20 · Owner request: walls and ceilings that make the cave feel real, for example a wall torch or a stalagmite. Related: landmarks (#117), the cave descent (#125), the descent wall library (#126), and the art backlog (#96).*

Today, floors draw plain walls, floor and ceiling. The only extras are the stairs and passages, room props, and a few floor props on the fortress floors. This list is **set dressing**: small pieces scattered along walls and ceilings so corridors stop looking alike. It sits **alongside** the descent wall textures (#126), not instead of them.

## First art pack delivered (2026-10-20)

The eleven first-batch categories and all nine floor categories below now have
assets in `art/dressing/cave-v1/catalog.json` (32 registered cutouts/scenes).
The lit torch includes four flame frames and a mood-only local light. Sources,
mounts, previews and rebuilding: [cave-dressing-assets.md](cave-dressing-assets.md).
Claude's sparse seeded placement remains to be wired; the review rooms are
standalone fixtures.

## How the game will place them

These are rules for the code, so the art can be drawn to fit.

- **Four ways to mount a piece:**
  - **Wall:** flat against a wall face, facing into the passage.
  - **Ceiling:** hanging down from the ceiling.
  - **Floor edge:** standing on the floor, pushed against a wall, never in the middle of the walkway.
  - **Corner:** fits where two walls meet.
- **Sparse and stable.** Roughly one piece per five or six wall faces, chosen from the floor's seed, so a floor looks the same each time you see it that day.
- **Never confusable with something you can use.** No dressing goes on cells that hold an event, a fight, stairs or a passage, and nothing should look like a chest, lever or door.
- **Never in the way.** Ceiling pieces stay high enough not to hide an enemy's tag in a fight. Floor-edge pieces never block the view down a corridor.
- **By theme.** Each environment (cave, goblin hold, and later the deeper layers) has its own set, chosen through its environment theme.

## Format (same as the existing props)

- Pixel art in the cave-prop style: a transparent PNG with nearest-neighbour filtering, 64–128 px tall depending on the piece.
- The world scale is a **2.0 m cell** and a **2.4 m wall**. Each piece below gives its rough real size so it reads correctly.
- **Pivot:**
  - wall pieces: the centre of the back edge
  - ceiling pieces: the top centre
  - floor-edge pieces: the bottom centre
- **Variants:** 2–3 per piece where noted, so repeats aren't obvious.
- **Light:** anything that gives off light (lit torches, glowing fungus) needs a lit version and an unlit or burnt-out version. A lit torch can have 2–4 flicker frames.

## First batch (recommended)

| # | Piece | Mount | Size | Floors | Why it helps |
|---|---|---|---|---|---|
| 1 | **Stalactites**: single, pair, cluster | Ceiling | 0.3–0.9 m long | 1–3 | The single biggest "this is a cave" signal. |
| 2 | **Stalagmites**: stub, tall, broken | Floor edge | 0.3–1.1 m tall | 1–3 | Breaks up straight corridors. |
| 3 | **Flowstone and mineral streaks**, plus damp drip stains | Wall | half a wall | 1–2 | Wet, old stone without new geometry. |
| 4 | **Cracks with fallen rubble** at the wall's foot | Wall plus floor edge | 1 m | 1–4 | Danger and age, and it hints at cave-ins (Three Knocks). |
| 5 | **Cobwebs**: a corner web and a sagging strand | Corner, ceiling | 0.6–1 m | 1–2 (heavy on 2) | Sets up the spiders before you meet them. |
| 6 | **Timber pit props**: two posts and a cross beam framing the passage | Wall (pair) plus ceiling | full height | 1 | Floor 1 is "The Old Workings": human mining. |
| 7 | **A burnt-out wall sconce**: an iron bracket with a dead torch stub | Wall | 0.5 m | 1–2 | The "wall torch" asked for, unlit, so it doesn't fight the darkness rules (below). |
| 8 | **Chalk survey marks**: arrows, numbers, a surveyor's cross | Wall | 0.4 m | 1–2 | The survey party's trail; story clue for the ambush. |
| 9 | **A lit goblin wall torch**: a crude bracket, rag-wrapped torch, 2–4 flicker frames | Wall | 0.6 m | 3–4 | A clear sign of goblin ground, and real warm light in their halls. |
| 10 | **Goblin daubs**: painted marks and hand prints in red and ochre | Wall | 0.5–1 m | 3–4 | The wall version of the existing `goblin-mark` floor prop. |
| 11 | **Hanging trophies**: bones and skulls on cords | Ceiling | 0.5–0.8 m | 3–4 | Menace overhead, matching `trophies`. |

## Second batch (when the first lands)

- **Hanging roots and moss curtains** (ceiling; floors 2–3 and the fungal layer). This reuses the look of `hanging-roots`.
- **Faintly glowing fungus patches** (wall, floor edge; floors 2–3 and later the fungal layer). These are emissive, but they don't count as a light source.
- **Bones and old remains** slumped against a wall (floor edge; 1–4).
- **Rusted mine fittings**: a wall ring with a chain, a broken rail end, a lantern hook (wall; floor 1).
- **Goblin hides and crude banners** (wall; 3–4), **wall spikes and chained cages** (wall, ceiling; 4), and **plank walkways overhead** (ceiling; 4).
- **A stranger's mark**: the same hand that marked the survey map, scratched once or twice along floor 1. It's a quiet story clue for the ambush (#107).

## Floor elements (added 2026-10-20)

These are flat **floor decals**: they lie on the floor and you walk over them, so they never block a step or the view. Other pieces stand at a **floor edge**. They follow the same rules as the rest: sparse, stable per floor, and never on cells with events, fights, stairs or passages.

| # | Piece | Mount | Size | Floors | Why it helps |
|---|---|---|---|---|---|
| F1 | **Puddles** with a dull sheen, in 2–3 shapes | Floor decal | 0.5–1.2 m | 1–2 (and the drowned layer) | Damp, living cave. Pairs with the drip stains. |
| F2 | **Gravel, loose stones and grit** | Floor decal | 1 m | 1–4 | Breaks up the repeating floor tile. |
| F3 | **Mine rails**: short broken lengths and a rail end | Floor decal | 1–2 m | 1 | The Old Workings, alongside the pit props. |
| F4 | **Footprints and drag marks** | Floor decal | 1 m | 1–3 | Something walks here. Pure atmosphere, not a hint for any particular fight. |
| F5 | **Pale cave mushrooms**, in clusters | Floor edge | 0.2–0.4 m | 2–3 (and the fungal layer) | Life in the dark; sets up the fungal layer. |
| F6 | **A rat nest**: shredded cloth, twigs, a bone | Floor edge | 0.5 m | 1–2 | The rats' home ground. |
| F7 | **A thin floor crack**, too narrow to fall into | Floor decal | 1–1.5 m | 1–4 | Unease without being mistaken for the pit trap. |
| F8 | **Goblin litter**: gnawed bones, a broken pot, scraps | Floor decal / floor edge | 0.5–1 m | 3–4 | Goblin ground before you see a goblin. |
| F9 | **Old scorch marks** from a long-dead campfire | Floor decal | 0.8 m | 1–3 | Others were here once. Different from the rest spot's cold camp, which has its own prop. |

Nothing on the floor may look like a trap, a pit or a chest. The hollow-floor trap and the pit have their own art, and the dressing must stay clearly different from them.

## Later layers (direction only, matching #126's wall families)

- **Drowned galleries:** drip curtains, waterline stains, mineral crusts.
- **Fungal hollows:** luminous ceiling moss, root curtains.
- **Buried city:** carved reliefs, empty lamp niches, inscriptions.
- **Sealed temple:** seal glyphs, ward niches.

## Decided: torch light (owner, 2026-10-20)

**Lit wall torches are mood only.** They glow and light the walls, but they don't count as light for the party's nerves: the party's light still comes from what it carries.

### The question as it was asked

Should **lit** wall torches (item 9) count as light for the party's nerves, the way a held torch does? I suggest **no for now**. They glow and light the walls, but the party's light still comes from what they carry, so the darkness rules stay simple and predictable. Lit sconces can then be a mood signal for goblin ground. The burnt-out sconce (item 7) avoids the question on the early floors.
