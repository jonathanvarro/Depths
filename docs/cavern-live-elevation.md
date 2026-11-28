# Live Cavern elevation and Rest Area (#313)

The owner-approved walking study (#311 / PR #312) is now integrated into the
real Main expedition flow. The Cavern uses sloping ledges, level rooms and
quest sites, a timber span where its topology allows, tall rock faces and
floor-registered actors/props. A newly generated Rest Area reserves the full
delivered shelter/tent/planning/supplies/hearth/lookout composition.

## Terrain and movement

`DungeonMap` now has optional `elevations`, `flat_landings`, `terrain_version`,
and shared `floor_y`, `world_at`, `surface_y`, `linked`, `can_step` and
`step_position` methods. Empty terrain retains flat-floor behavior.
`CavernTerrain.ensure` assigns heights only for the Cavern area, after all
quest packages, puzzles and content have been placed. It preserves the seeded
layout, content and RNG. Rooms, whole protected sites, doors and stair aprons
remain level. Connected groups descend in 0.2m increments, capped at 2.4m.
Even the shortest room/corridor ramp is at most about 26.6 degrees. Loops can
ascend again toward a nearer group; heights are not a one-way descent rule.

The real Party follows continuous support between flat landing edges, using
the accepted study's 0.42s move time in the Cavern. Other floors retain their
existing speed. Turns, touch repeat, keyboard input, passage opening, fuel,
strain, class effects and encounter timing remain controlled by their existing
systems. Legal terrain edges also govern walking paths, pack approach/sight,
field combat movement, melee/reach and tactical markers. There is one height
per X/Z cell; stacked walkways remain a separate map-layer decision.

`ElevatedGeometry` builds stone/timber support and connecting ramps instead
of the old y=0 tiles/2.4m ceilings. Rooms have tall, opaque rock faces visible
from both sides; corridors overlook the rift. The deep floor and tall columns
are scenery, never walkable cells. Shared physical UVs, opaque materials and
the existing Cavern kit are reused; no new downloaded asset, character clip,
raster generation or source-art alteration. Low atmospheric fill/thinner fog
make height readable while lit; darkness and gameplay visibility still use
the existing light rules. Existing audio assignments/gains are preserved.

## Actors and props

Main's groups, field enemies, danger marks, bodies, loot/chests, event props
and wall lights use the map's metric floor origin. Moving packs and enemies
follow the same ramp profile as the party. Sprite setback/lift remains relative
to its local floor; models remain on the ground and keep their existing pose
and framing APIs. Puzzle fittings and water planes also respect local height.
Existing dresser/landmark anchors are shifted once; child-local model mounts
are retained. Cavern dressing uses sparse delivered geology and goblin marks,
avoiding quest/fight rooms and moving paths.

## Full Rest Area

`RestApproach` supplies a small authored safe layout with a reserved 5x5-cell
site, sufficient roof clearance, one continuous caller floor, clear navigable
camp space and blocked furniture cells. Existing lookout slabs supply their
own floor. The full scene is bound to the existing `Refuge.EVENT` interaction,
with its origin at the reserved site's anchor rather than its trigger cell.
Approaching the refuge or its furniture opens the existing Overlook controls;
rest, stash and companion activities retain their original authorities.
The interaction uses the canonical refuge cell even when approached beside
the furniture, so spent-state and stash return remain correct.

Fresh/used aliases bank and stop the fire on restore. Actual party members
continue to determine Overlook occupants. Planning/quartermaster markers do
not invent an NPC or service. Reaching the area still secures the quartermaster's
route through the existing `rest_secured`/route logic. Fortress and Cavern
return travel use the actual paired exits; nearby descent art is labelled by
destination. Random dressing/landmarks/lights do not intrude into this site.

## Saves and compatibility

The existing SaveGame object serializer stores the new plain map fields.
No save version bump or destructive conversion is needed. Legacy Cavern maps
derive height from their saved topology and protected-site records on build;
layouts, used events, explored cells, loot and quest progress are retained.
New terrain persists exactly, including encounter checkpoints and return trips.
The controller is restored from its saved cell at that cell's floor height.

**Previously cached Rest Area layouts remain intact**, using their compact
refuge marker; a new expedition/newly generated Rest Area gets the full reserved
approach. This avoids relocating the player, used refuge, bodies or events in
an existing safe-area save. The companion/stash/secured-route state is shared
through the same CampState throughout.

## Verification and review

`tools/cavern_terrain_check.gd`: 29,778 checks across 30 generated maps, including
unchanged topology/reachability, physical grades, serialization and idempotence.
`tools/cavern_live_check.gd`: native Main traversal and every rendered landing/
connector support, pack movement, real mixed-model field combat and checkpoint
resume, actual legacy/new file loads, grounded event props, full refuge entrance,
furniture/stash/used-fire restore, paired returns and three landscape phone shapes.
Final counts/captures are in its validation JSON because per-frame counts vary.
Existing area-network and Damp/rest checks pass; the quest-site suite passes
all 220 generated floors, including missing-site repair. The original walking
study's headless regression also passes.

The Windows release is exported with the existing preset and Godot 4.7.2
templates, then continued from separate private Cavern and spent-refuge saves.
`--verify-cavern` emits read-only `AREA_CHECK` metadata for those export checks;
it does not alter gameplay. The private desktop launcher now supports
`--exported` to omit the editor-only `--path` argument. Runtime binding/height
and used-state assertions check the actual executable, not just its exit code.

Local gallery, reports, private launchers and exported build:
`E:/GitHub/Depths/build/local-cavern-live-v1/inspector.html` and
`E:/GitHub/Depths/build/cavern-live-checkout/build/windows/Depths.exe`.
Use the gallery's launchers to play copies of review saves without touching
the owner's normal save. Tests never use the active screen or owner profile.
Physical iPhone performance and owner review of the integrated floor remain.
