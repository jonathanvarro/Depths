# Damp Caves: layout reference sections (#302)

Design candidate for owner/Claude review, 2026-11-26. These four sections answer brief G; they are not new playable layouts, approved water mechanics or balanced encounters. The latest owner network is **Abandoned Mines → Damp Caves → Cavern or Fungal Hollows**. Cavern leads to the Rest Area; the player/quartermaster surface route targets that Rest Area. Only the `junction` section's two destination-tagged exits express that world junction. Other `>` marks are section continuations, not additional destinations.

## Shape rules

Keep the 35×35 generator envelope and existing room footprints of at most 5×5. Use offset, dogleg corridors, small linked chambers and cut-off corners to suggest erosion. Larger-looking caverns can be composed from adjacent supported room modules; enlarging a single room past the generator cap is a separate change. Do not fill every corridor with a floor prop.

Keep a dry, connected route from the mine entrance to **both** outward exits. Put water below or beside that route: central basins with dry rims, shallow side channels, short flooded dead ends. Reach the two exits through different recognizable approaches; goblin occupation hints lead toward Cavern, while fungal traces only grow dense near the Hollows boundary. The Damp Caves themselves emphasize wet rock, silt and calcite rather than the fungal side region's mushrooms.

Propose exit placement by walking distance rather than opposite map corners: do not show an onward exit immediately from arrival, and aim for both exits beyond the first two or three encounter-sized chambers. Exact distance targets and seeded frequency need full-floor generation/playtests. Keep a return route readable, with a familiar landmark at important junctions. No fixed full-floor counts are established by these small sections.

## Legend and data contract

Use existing `#` rock, `,` room, `.` corridor, `E` encounter, `C` chest, `T` trap, `O` object, `R` rest, `<` way in/up, `>` onward, `D` closed passage and `B` blocked passage.

- `~` means proposed **shallow visual wetness**, no gameplay cost.
- `w` means a proposed deep basin; it is **not** silently added to `map.water`.
- Coordinates below are zero-based `(x,y)`. Ordinary letters do not prescribe event odds or enemy types; the point tables carry design intent.
- These are planning sections with metadata in `damp-caves-layout-sections.json`. Do not paste `~`/`w` into the live parser and assume room/water/encounter classification works. Claude should preserve the underlying room/corridor mask and apply separate water/art overlays after approved placement.
- Current runtime has one numeric up/down destination; supporting the first section's paired destination exits requires #300's area IDs/arrival anchors before hookup.

## Proposed water rules

Start with shallow damp patches/puddles as **looks only**: no extra time, strain, noise, fuel loss or torch extinguishing. This introduces wet terrain without changing the player's movement rules. Every required exit and the bitter-moss site has a route that avoids deep water.

Existing `Galleries` deep-water travel already costs time/strain and soaks torches, while a lantern stays above water. If the owner chooses a small early demonstration of that rule, reuse that authority on explicitly approved optional `w` cells, with a dry ledge around them, an understandable depth warning and a way back. Do not copy the Galleries' floor-wide flood generation, sluice flags or quest progression into floor 2. Do not add a new swimming, oxygen or drowning subsystem. No proposed water behavior is implemented in this delivery.

Sump black water may remain inaccessible scenery, or become optional existing-style wading after review. That choice must be explicit; a shallow-looking puddle must not secretly extinguish the player's torch.

## Reference sections

### Two exits beyond the drowned drift

```text
#########################
#########################
##,,,,,###########,,,,,##
##,,<,,..###......,,>,,##
##,,,,,#.###.#####,,,,,##
##,,,,,#.#,,,,,###,,,,,##
########.#~~~~~##########
########..,,,~,##########
########..,,E,,..########
########.#,,,,,#.########
########.#######.########
########.#######.########
##,,,,,#.#######.#,,,,,##
##,,C,,..#######.#,,,,,##
##,,,,,#########..,,>,,##
##################,,,,,##
#########################
#########################
#########################
```

| Feature | Cell | Placement intent |
| --- | --- | --- |
| Drowned drift | (8, 3) | Rails/debris at the transition from mining to wet natural rock; no flood rule implied |
| Two destination clues | (12, 7) | Worked goblin marks toward Cavern; dense fungal traces only near the Hollows exit |
| Shallow newt encounter | (12, 8) | Newt pair can emerge before combat begins; no hidden guaranteed first strike |
| Ambient newt | (13, 6) | Small noncombat crossing between puddles, off the exit cells |
| Optional cache | (4, 13) | A dead end with a reward rather than a required key |

Connectors: (20, 3) → Cavern; (20, 14) → Fungal Hollows.

### Dry ledge around the sump

```text
#########################
#########################
##,,,,,##################
##,,<,,...,,,,,##########
##,,,,,###,www,##########
##,,,,,###,wwwE##########
##########,www,##########
########..,,,,,..########
########.#######.########
########.#######.########
########.#######.########
########.#######.########
##,,,,,#.#######.#,,,,,##
##,,,,,#.#######.#,,,,,##
##,,E,,..#######..,,>,,##
##,,,,,###########,,,,,##
#########################
#########################
#########################
```

| Feature | Cell | Placement intent |
| --- | --- | --- |
| The sump | (12, 5) | 3x3 deep visual basin, surrounded by a dry walkable rim |
| Newts surface | (14, 5) | Fight trigger on the dry rim, visible gills and wake before engagement |
| Blind crawler nook | (4, 14) | One crawler with a rat in a narrow optional dead end; retain retreat access |
| Wall leeches | (10, 5) | Clinging at a wet boundary, with a dry route around the pool; no collision |

Connectors: (20, 14) → Section continuation (not an extra world exit).

### A water-linked patrol loop beside the dry route

```text
###################################
#,,,,,#############################
#,,<,,#############################
#,,,,,#############################
#,,,,,#############################
###.#######,,,,,###########,,,,,###
###.#######,,,,,###########,,,,,###
###.#######,,~~~~~~~~~~~~~~~~~,,###
###.#######,,~,,###########,,~,,###
###.#######,,~,,###########,,~,,###
###.#########~###############~#####
###.#########~###############~#####
###.#########~###############~#####
###..........~###############~#####
###.#########~###############~#####
###.#########~###############~#####
###.#########~###############~#####
###.#########~###############~#####
###.#########~###############~#####
###.#######,,~,,###########,,~,,###
###.#######,,~,,###########,,~,,###
###.#######,,~~~~~~~~~~~~~~~~E,,###
#,,,,,#####,,,,,###########,,,,,###
#,,,,,#####,,,,,###########,,,,,###
#,,>,,#############################
#,,,,,#############################
###################################
```

| Feature | Cell | Placement intent |
| --- | --- | --- |
| Drowned Mother resting room | (29, 21) | Leader start; at least 12 walking steps from both stair anchors |
| First possible cold glow | (11, 13) | At the side-loop threshold; actual visibility remains caller-owned |
| Dry main bypass | (3, 13) | The leader does not patrol the only route between stairs |
| Leech shallows | (28, 7) | Shallow approach suitable for a leech/newt fight; no guaranteed swarm gate |

Connectors: (3, 24) → Section continuation (not an extra world exit).

Patrol room sequence: (13, 7) → (29, 7) → (29, 21) → (13, 21) → (13, 7). Shallows connect the rooms; a separate dry spine bypasses the patrol. The rest cell is 45/45 walking steps from the section anchors in this reference. First glow is an occlusion-dependent view from the side entrance, not a new visibility rule.

### Weeping wall, protected moss site and optional brood

```text
###############################
###############################
##,,,,,#####,,,,,#######,,,,,##
##,,,,,#####,,O,,#######,,,,,##
##,,<,,.....,,,,,...D...,,O,,##
##,,,,,#.###,,,,,#######,,,,,##
##,,,,,#.###,,,,,#######,,,,,##
########.######################
########.######################
########.###,,,,,##############
########.###,,,,,##############
########....,,O,,##############
########.###~~~~~##############
########.###,,,,,##############
########.######################
########.######################
##,,,,,#.###,,,,,#######,,,,,##
##,,,,,#.###,,,,,#######,,,,,##
##,,C,,.....,,R,,.......,,E,,##
##,,,,,#####,,,>,#######,,,,,##
##,,,,,#####,,,,,#######,,,,,##
###############################
###############################
###############################
###############################
```

| Feature | Cell | Placement intent |
| --- | --- | --- |
| The weeping wall | (14, 3) | Flowstone landmark; drip anchors belong against the wall |
| Bitter-moss package reserve | (26, 4) | Reserve actual 5x4 healing_moss package footprint plus connection margin; O denotes its intended event, not a package implementation |
| Wet lost cache | (4, 18) | Rotted crates; persistent buried-cache state remains with the existing event |
| Bone silt | (4, 16) | Loose bones collected in a dark silt bank at an optional end |
| Rimstone stair | (14, 11) | Small terraced pools, with a dry edge to the optional object |
| Brood warning threshold | (22, 18) | Existing Go in/Back away before committing; no required exit or quest target behind it |
| Brood fight | (26, 18) | Retain the existing lair contract; no new monster or boss rules assigned |

Connectors: (15, 19) → Section continuation (not an extra world exit).

## Landmarks, quest and lair placement

Use the sump as a dry-ring room, the weeping wall on a broad wall face, and rimstone terraces in a side chamber with an intact dry edge. The drowned drift belongs near the mine-to-natural-cave transition. Bone silt and the wet lost cache belong in rewarding dead ends. Keep cache fresh/resolved state and the buried-cache quest independent of scenery.

Reserve the actual bitter-moss package footprint and its connection margin before decorative placement. Its current resource is 5×4; the `quest-lair` section marks a reserve, not a substitute package. Preserve current near-site discovery and guarantee every active required site. Do not put the only required quest target behind a lair warning or random water crossing.

Place the brood lair off the main route, with the existing Go in / Back away choice before the encounter zone. Rejecting it leaves both world exits reachable. Keep ordinary surface water, optional encounter room bounds and real quest package bounds distinct; decorative puddles cannot define combat triggers.

## Creature and wildlife placement proposal

**Pale newts:** pool edges, wet chambers and the sump. Stage emergence before a fight starts so the face/gills and targeting are readable. Water may conceal an ambient body until nearby, but wake/ripples should warn first; do not introduce an invisible attack, guaranteed surprise or untargetable combatant. Ordinary newt pairs should be weaker than the named pack; Claude sets numbers.

**Blind crawlers:** narrow wet side passages and dead ends, one per encounter, usually with a supporting rat/spider behind. Avoid stacking grabbers or combining a compulsory corridor grab with unavoidable deep wading. Preserve space to withdraw before entering the room's encounter zone.

**Leech swarms:** wet wall bases and still shallows. Use them near some optional bottlenecks and as part of a water-start fight; preserve an alternative route instead of putting a swarm on every required crossing. A wall-clinging ambient version is not a hostile encounter and adds no collision or damage.

**The Drowned Mother:** the reference loop sits beside the main dry route and has four connected room centers. Start her in the far resting room, away from stairs and protected quest footprints. Reuse named-pack patrol/discovery/glow/hoard authority, including the existing once-won hoard. Visibility, eligibility, avoidance and movement remain caller-owned. A section plan is not permission to force this pack to spawn on every floor. Her fitted model and followers wait for approved concepts.

**Ambient spots:** small newts slip between nonessential puddles; a few leeches cling to real wet walls away from interactable targets. Reuse future creature models with their ambient fade API, solid default materials and exact still mode. Do not make an ambient animal look like a compulsory enemy or hide an exit cue behind it.

## Starting encounter mix for playtest, not live balance

Propose a modest **35% new wet-creature groups / 65% retained families** before existing party-size and knowledge gates. These are candidate group-selection weights, not expected encounter counts or a production tuning result. Remove no existing enemy family. Convert today's duplicate entries into explicit weights only if Claude chooses that representation. Do not apply these values by editing `ENCOUNTER_GROUPS[2]` in the art branch.

| Candidate group | Relative weight |
| --- | ---: |
| NEWT, NEWT | 10 |
| NEWT, RAT | 6 |
| CRAWLER, RAT | 8 |
| LEECHES, NEWT | 7 |
| CRAWLER, LEECHES, SPIDER | 4 |
| GOBLIN | 12 |
| GREAT_RAT | 6 |
| GREAT_RAT, SPIDER | 10 |
| SPIDER, SPIDER | 8 |
| BAT, BAT, SPIDER | 6 |
| GOBLIN, RAT | 6 |
| GOBLIN, SPIDER | 5 |
| BEETLE, RAT | 7 |
| TRAPPER, GOBLIN | 5 |

Retain the current party-size rules, low-party relief, learned-enemy restrictions and named-pack eligibility. The triple containing a crawler needs particular solo/phone testing. Keep advanced web/venom-plus-goblin combinations on floor 3 as currently intended; do not accidentally restore the combinations previously moved out for causing early wipes. New tactics, drain duration, fire responses and stat values require Claude's combat work and playtests.

## Validation and remaining decisions

Run `python tools/damp_caves/build_layout_sections.py` to regenerate the JSON and validate these same proposals. **50 checks pass:** bounded 35×35 sections, rectangular rows/legend, ≤5×5 room descriptors, connected walkable cells, reachable features, every connector reachable without deep water, two explicitly named first-junction destinations, closed patrol loop with a start away from anchors, and a main bypass that remains connected when the patrol branch is blocked. These checks do not establish seeded-generator fit, art clearance, package stamping, encounter balance, patrol runtime or playable junction support.

Owner/Claude review remains for water interaction, patrol encounter pressure, group weights, package margins and return/rejoin behavior. A future live integration must validate required quest sites over seeds, both junction arrival/return anchors, old-save migration, refusal/retreat, still mode and exported builds. This delivery changes no game rules.
