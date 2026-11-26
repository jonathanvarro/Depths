# Floor 2: Damp Caves — production brief

Owner direction (2026-11-25): floor 2 stops being the **Fungal caverns** and
becomes the **Damp Caves**, with a clearly different look from the warm,
timbered mine of floor 1. This brief lists every asset and design piece to
produce, what it replaces, and the conventions the game needs. ChatGPT
produces the art and the layout designs; Claude does the live hookup (theme,
dressing script, landmark builders, rules) afterwards.

Priorities: **P1** is needed to swap the theme without anything looking out
of place. **P2** makes the floor feel new. **P3** is optional, and needs the
owner's go-ahead.

## Style

- Cold, wet, water-carved limestone: slick sheen, mineral streaks, seeping
  cracks, standing water, silt and mud. Fewer timbers; this is natural cave
  that the miners only broke into.
- The palette moves from floor 1's warm browns to cold grey, blue-green and
  bone. Light reflects off wet surfaces, and the party's torch stays the only
  warm colour.
- Still dark and gritty (`docs/enemy-art-direction.md`): drips, rot and
  drowned debris, nothing pretty.
- It must still read on a phone at 1278×590 and 844×390.

## Conventions (unchanged from the current 3D libraries)

- Godot 4.7.2, Mobile renderer, CC0 or original sources only. Record each
  source and licence. Nothing private or Quaternius.
- Metric floor origin. **+Z points out of the wall**, with wall pieces flush
  against it and their back unmodelled (the game only places them against
  real rock). Ceiling pieces hang from the ceiling (wall height 2.2 m on a
  2 m cell).
- Wall surfaces use full-face UVs (`wall_face_uv`, as in the fungal theme).
- Anything that moves (drips, ripples, flicker) needs `set_motion(enabled)`
  with an exact still pose, and respects the Settings "flashes" preference.
- Glow is mood only: no gameplay light, and no more than one small light per
  piece.
- Budgets in the same range as `cave-growth-3d-v1` and `mine-refined-v2`.
  Give triangles, materials and draws per piece in `catalog.json`.
- Deliver on a `codex/` branch with `catalog.json` (id, mount, envelope,
  states), editable masters kept local, an `inspector.html` with native Mobile
  captures at desktop and phone sizes, and a `docs/damp-caves.md` handoff.
- Gameplay stays with the game: art gets no rules, collision or RNG.

## A. Theme surfaces (P1)

Today: `themes/fungal-caverns.tres` uses `descent-walls-v1/fungal-stone` (wall
and variant) and the `descent-surfaces-v1` fungal floor and ceiling.

| # | Asset | Notes |
|---|---|---|
| A1 | Damp limestone wall + a variant | Tileable per 2 m face, full-face UV, wet streaks and seeps; the variant breaks up repetition |
| A2 | Wet floor | Silt, water-worn stone, shallow puddle staining; must sit under puddle decals |
| A3 | Ceiling | Dripping, with soda-straw texture and darker wet patches |
| A4 | Wet-sheen material settings | Roughness and specular that read as wet under the torch, without mirror flicker on mobile |

## B. Passages and ways up and down (P1)

These replace the fungal theme's scenes. They follow the LevelBuilder
floor-centre / −Z convention used in `transitions-3d-v1`.

| # | Replaces | New asset | States |
|---|---|---|---|
| B1 | Spider web (closed passage) | A curtain of hanging wet roots and slime, or a calcite drapery to break through | intact / opened; a torch still burns a web-like curtain, so say which it is |
| B2 | Tangled roots (blocked passage) | A mud and silt slide, or a fallen slab, choking the passage | blocked / cleared |
| B3 | Pit (way down) | A flooded sinkhole or water-cut shaft with a ledge to climb down | one state; the game adds its warm way-down glow |
| B4 | Hanging roots (way up) | A wet rope ladder or a calcite ramp back up | one state; the game adds its pale way-up glow |

## C. Dressing kit (P1)

Today `scripts/fungal_dressing.gd` uses wall fungus, wall roots, flowstone,
rubble cracks, moss curtains, root curtains, stalactites, floor fungus,
stalagmites, puddles and gravel, plus 2D fungus-pulse and drip sprite
effects. Replace these with a damp set of 3–6 pieces per mount:

- **Wall:** wet flowstone sheet; mineral seep stain; dripping crack;
  dark damp moss patch; a niche of cave pearls.
- **Ceiling:** soda-straw cluster; dripping stalactite (with a drip hook);
  hanging wet roots.
- **Edge** (against the wall, on the floor): rimstone dam (small terraced pool
  edge); slick boulder; stalagmite stub; drowned debris (a plank, a bucket, a
  rusted lamp).
- **Floor decal:** small and wide shallow puddles (3D surface, replacing the
  2D puddles); silt ripples; mud with old boot prints; wet gravel.
- **Effects:** a 3D or particle drip (falling drop plus a small ripple) to
  replace the 2D drip sprite; optional low mist tinted cold, reusing
  `exploration-mist-v1`'s rules.

## D. 2D leftovers still in the live game (P1 for floors 1–2)

These are still flat sprites and show on floors 1–2, in the base dressing or
the landmarks. Each needs a 3D replacement in the right style. Floor 1's
should match the mine; floor 2's should match the Damp Caves.

- Base dressing: `cracks-rubble`, `chalk-arrow`, `chalk-cross`,
  `chalk-tally`, `web-strand`, `rat-nest`, `puddle-small`, `puddle-wide`,
  `floor-gravel`, `tracks-drag`, `floor-crack`, `old-scorch`.
- Fungal set: `moss-curtain` (and its lit version); the 2D fungus-pulse and
  drip effects.
- Landmarks (`scripts/landmarks.gd`): `root-curtain-a`, `root-curtain-b`,
  `root-foot-tangle`, `floor-crossing-root`, `collapsed-crates`,
  `split-barrel`, `fallen-banner`, `cache-rubble-planks`,
  `cache-spilled-grain`.
- Event props: the goblin stash (`art/props/cave-events-v1/goblin-stash`,
  floors 2+) and the lamp-eaters' lamp (`art/props/traps-lamps-v1/lamp`,
  floors 2–3), each with fresh and used/empty states.
- Later (floors 3–4): `goblin-daubs`, `goblin-litter`, `hanging-trophies`.

## E. Landmarks for floor 2 (P2)

Each landmark is a set piece the player can recognise in first person and
that gets named on the map. Floor 2 currently draws from the old working face,
old cave-in, pale grotto, root-choked junction, king's lost cache and
dripping hall. Proposed Damp Caves set (art kit plus a short layout note
each):

1. **The sump** — a room mostly under still black water, with a dry ledge
   around it. (The clear-pool event fits here.)
2. **The weeping wall** — a room where one wall is a single great flowstone
   curtain, wet and glistening.
3. **The drowned drift** — a stretch of old mine corridor, half flooded, with
   rails running under the water and a sunken cart.
4. **The rimstone stair** — a room of stepped rimstone pools.
5. **The bone silt** — a dead end where water has washed bones into a bank of
   silt.

Keep the king's lost cache on floor 2 (and its buried cache), restyled with
wet, rotted crates.

## F. Events and their props (P2)

Ideas for new floor-2 room events (each needs a 3D prop with states; the
text, choices and odds are written later with Claude):

- **A sunken satchel** (container): a pack half under a pool. Fresh / emptied.
- **Cave pearls** (object): a nest of pearls in a rimstone pool, to sell.
  Fresh / gathered.
- **A seep** (rest spot): clean water running down the rock. Fresh / used.
- **A slick ledge** (trap): a slope of wet flowstone over a drop. Ready /
  slipped / passed.
- **Blind fish** (object): a pool of pale fish, as food. Fresh / fished.

## G. Floor layout designs (P1, with the owner)

The generator lays out a 35×35 grid with rooms of at most 5×5, corridors and
content letters (see `scripts/floor_generator.gd` and the layout legend in
AGENTS.md). For the Damp Caves, please deliver:

1. **Shape rules in words:** how the floor should differ from floor 1, for
   example more winding passages, rounder rooms, a few larger caverns, dead
   ends that end in water, how often rooms are flooded, and how far apart the
   ways up and down are.
2. **Three to five reference sections as ASCII,** in the existing legend
   (`#` rock, `,` room, `.` corridor, `E C T O R < >`, `D` closed passage,
   `B` blocked passage). Mark water with `~` for shallow and `w` for deep, and
   say what each means for play.
3. **Proposed water rules for Claude to implement,** e.g. shallow water is
   only for looks; deep water must be waded (slower, noisier); torches don't
   work while wading. Floors 5–6 already have deep-water wading
   (`map.water`, `Galleries`), so say whether floor 2 reuses that.
4. **Where the landmarks, the bitter-moss site (floor 2's quest) and the
   brood lair should tend to sit.**

## H. Sound (P2)

- A Damp Caves ambience bed: drips, a distant rush of water, low echo.
- Four wet footsteps, plus a splash step for puddles and shallow water.
- A wet wall bump.
- Sounds for the new closed passage (B1) and blocked passage (B2).
- Two or three drip one-shots for the dressing to play occasionally.

## I. Creatures (P3, owner's call)

Floor 2's roster is already all 3D: rats, great rats, spiders, cave bats,
goblins, rock beetles and goblin trappers. If the owner wants damp-specific
creatures: a pale cave newt or olm, a blind crawler (crayfish-like), or a
leech swarm. Each would be a concept first, following the enemy art
direction.

## Integration notes for Claude (afterwards)

- A new `themes/damp-caves.tres` with its own `dressing_script`.
  `Galleries.theme_from` / `_apply_theme` choose floor 2's theme.
- Landmark builders for section E, and the restyled lost cache.
- Event `.tres` files for section F, plus any water rules agreed in G.
- Keep the fungal theme files: they can come back deeper down.
