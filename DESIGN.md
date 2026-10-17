# Depths — Design Direction

Last updated: 2026-10-16. This is a living design document for the owner, Claude Code, and Codex. It records the discussion so far; it is not a complete implementation specification. Depths is the working project name, not a confirmed release title.

## Premise

A dark, first-person dungeon crawler about party strain, dangerous discoveries, and the temptation to keep going. Lead a small party through procedurally generated dungeon sites, each paired with a nearby refuge. Begin with a cave and campsite; later sites grow in danger and importance. Within a site, descend toward its deepest objective.

**The goal gets closer as the party becomes less able to reach it.** Lost hit points, persistent injuries, dwindling supplies, emotional strain, and increasingly difficult floors make each decision to continue more consequential. Discoveries offer opportunities to recover, gain an advantage, or take another tempting risk.

## Design pillars

- **Consequences connect encounters.** Winning a fight can leave the party less able to survive the next room.
- **Curiosity competes with survival.** Clues suggest possibilities without explaining every consequence.
- **Companions are people under pressure.** Distinct motives and vulnerabilities make risks matter to particular characters.
- **Retreat is meaningful.** Leaving preserves survivors and gains, but abandons opportunities and delays the objective.
- **Relief is a reward.** Food, shelter, treatment, and a safe route should feel valuable.
- **Knowledge matters.** Consistent dungeon rules let players apply what they learn, even when layouts change.

## Current direction and certainty

Established direction: dark and gritty atmosphere; first-person grid exploration; procedural dungeon layouts; room encounters; an increasingly difficult descent toward the bottom floor; a small party represented by expressive portraits; turn-based combat involving positioning, protection, and cooperation; a readable exploration map.

Proposals still to validate: exactly three companions; the detailed strain and relationship mechanics; resource quantities and time costs; combat positions and action lists; the pixel-art production approach; and the initial prototype scope below. Engine: Godot 4; target platforms: Windows and iPhone (decided 2026-10-16).

## Core loop

1. Prepare companions, equipment, skills, and provisions.
2. Choose an adjacent room and move into it.
3. Read the situation and any companion reactions.
4. Investigate, interact, fight, withdraw, or leave something untouched where possible.
5. Carry the resulting rewards, injuries, resource losses, and strain forward.
6. Decide whether to explore further, descend, rest where permitted, or return toward safety.

Preparation should create responsibility: the player can connect outcomes to choices about supplies, party composition, and acceptable risks.

## Exploration and movement

- The party moves together through a procedurally generated grid, one room at a time, viewed through the party's eyes.
- Controls: classic forward / back / turn left / turn right (decided 2026-10-16). Strafing is not included for now.
- Entering a room commits the party to encountering its contents. It does not require opening every chest or touching every object.
- Rooms can contain creatures, traps, chests, strange objects, events, or places of relief.
- Some threats require an immediate response; others allow investigation or withdrawal.
- Investigation provides clues but consumes resources, including time.
- Procedural layouts should use consistent rules and reusable authored encounters so discoveries remain understandable.

## Map and dungeon progression

Preserve the readable map from the visual concepts, adapted to the grid. Show explored rooms and routes, the current location, blocked doors, uncertain passages, stairs, and known routes toward safety. Notes and unresolved discoveries provide reasons to revisit rooms.

Within each dungeon site, the objective is to reach its bottom floor or deepest objective and complete that site's challenge. Completion opens the way to another site; the campaign is no longer envisioned as only one increasingly deep dungeon. Exact objectives, completion conditions, and final encounters remain undecided.

Successive floors should become harder through stronger enemies, new behaviours, more demanding combinations, traps, and environmental hazards. Avoid relying solely on larger enemy health and damage values. Increased danger should be accompanied by rewards worth considering: equipment, treasure, knowledge, shortcuts, and access to deeper areas.

Allow moments of recovery within the overall decline. A defensible room or useful cache can make another floor seem possible. Descent should be a deliberate choice made with the party's condition and return route in mind.

Returning safely with useful gains should matter even when the bottom is not reached. Exact return-travel hazards, stair rules, and expedition persistence are unresolved.

## Campaign progression and refuges — recorded 2026-10-16

### Agreed direction

The campaign progresses through **dungeon + refuge combinations**, starting small and of low importance, then building toward a castle, a demon portal, or a similarly significant threat. The first site is **a cave paired with a campsite**. Completing a site allows the party to move to another location with its own dungeon and refuge.

Preserve two scales of progression:

- **Within a site:** prepare at its refuge, explore increasingly difficult depths, retreat to recover when necessary, and return to attempt its objective.
- **Between sites:** complete the current challenge and move onward to a more consequential destination, introducing different environments and threats.

This direction replaces the assumption that the whole campaign must take place in one dungeon. The initial cave-and-campsite loop should stand on its own before building later sites. Recording the wider campaign does not authorize implementing every destination now.

### Possible route, not a fixed content list

| Stage | Refuge | Dungeon | Possible emphasis |
| --- | --- | --- | --- |
| First site | Small campsite | Cave and abandoned workings | Learn exploration, resources, retreat, and recovery |
| Later site | Occupied chapel | Old crypt | Introduce unnatural threats and sealed passages |
| Later site | Expedition outpost | Ruined fortress | Longer expeditions and more demanding objectives |
| Late campaign | Encampment | Castle and its depths | Bring together the party's accumulated experience |
| Possible finale | Makeshift sanctuary | Demon portal or breach | A high-stakes final expedition |

Only cave + campsite is the initial site choice. The intermediate destinations, their order, and whether the castle/portal are one site or separate sites remain illustrative. Avoid committing to a full campaign asset list before testing the first site.

### Refuge purpose

Retreat has a destination: the current site's nearby refuge. It provides the setting for recovery, provisioning, party preparation, and reflection before another attempt. A campsite with other explorers is a useful initial concept; a town or more elaborate settlement is not required.

Suggested initial presentation: one campsite screen with a few selectable activities rather than a large walkable town or settlement-building system. Food and treatment should respect the established delayed recovery/rest rules; returning should not implicitly erase every injury or strain state.

**Campsite interaction direction (2026-10-16):** the owner wants little tents/activity areas that highlight and can be clicked or tapped to enter. See [the campsite design](docs/campsite-design.md) for the proposed clearing, five destinations (your tent, supplies, treatment, campfire, cave path), mouse/touch behaviour, and activity-view flow. The spatial interaction is the owner's direction; the service selection and detailed layout are proposals for review. This is a design study, not an implemented refuge or finalized recovery/economy rules.

The suggested retreat flow is to return through the dungeon to its entrance before reaching camp, with discovered shortcuts potentially easing later returns. Travel costs, escape exceptions, refuge services, recovery timing, and prices still need design decisions. Rest spots inside the dungeon remain distinct from the outside refuge.

### Continuity and escalation proposals

Keeping companions, scars, equipment, relationships, and important discoveries across sites would give the campaign emotional continuity: the people approaching the castle are the ones who began at the cave campfire. This is a preferred design proposal, not a finalized save/persistence or permanent-death rule.

Escalation should introduce new hazards, tactics, and preparation needs as well as stronger enemies. An initially local problem could reveal evidence of a larger threat, providing a reason to travel onward; the specific story is open.

Open campaign questions: what counts as completing a site, whether old sites remain accessible, whether moving on is reversible, how revisits affect procedural layouts and cleared encounters, and what carries forward between sites and expeditions.

## Companions and strain

Start by exploring a three-person party. Each companion has a distinct role, personality, vulnerability, and reason to enter the dungeon. Portrait cards communicate physical and emotional condition.

Strain should affect decisions and behaviour, rather than exist only as a number. Possible reactions include hesitation, requests to retreat, recklessness, and disagreement. Personal motives can make a particular discovery especially tempting to one person.

Trust, promises, and unequal sacrifices are possible ways to deepen this system, not yet mandatory features. Serious refusals or loss of control should have readable warning signs and opportunities for the player to respond.

Health and injuries carry beyond a battle. Stress, disease, and enduring quirks are candidate systems; avoid implementing all of them before the basic loop is proven. Close calls and lasting consequences should create attachment through play.

## Combat

Combat is turn-based. The room view becomes the battlefield while heroes remain represented by their portrait cards. Positioning, protection, and cooperation matter, and injuries or strain affect available tactics.

Exploration knowledge can provide an advantage or help avoid an unnecessary fight. Fighting should offer worthwhile gains while carrying lasting costs.

Possible objectives include defeating an enemy, protecting a companion, recovering an object, or holding a threat back while clearing an exit. Retreat should involve a meaningful decision; its exact mechanics remain open.

**Decided 2026-10-16 (#13): enemies appear in the first-person view.** A dedicated formation layout may be explored later. Do not assume the movement or combat of Greed & Darkness is the target. The owner likes its art styling but envisions these systems differently. Three party positions and a compact action set are starting proposals, not settled rules.

## Resources, rewards, and uncertainty

**Decided 2026-10-16 (#10):**

- **Time is the primary resource.** Every step costs time.
- **Lantern oil burns over time, and its level matters.** A high oil level gives more light and a greater advantage but burns proportionately faster; a low level burns slower but gives less light and less advantage. Managing the flame is a trade-off, not just a meter running down.
- **Food and healing are used outside combat.** Their effects generally take time to fully apply, or apply after a camp/rest event, rather than instantly.
- **Supplies live in a backpack/inventory screen**, not on the main HUD. Keep the HUD visually quiet.

Other candidate resources: health and carrying capacity. Treasure can compete with provisions for space. Recovery consumes resources or requires safety.

Rewards include treasure, equipment, knowledge, shortcuts, and safe resting places. Discoveries should change future options, not simply add score.

Unknown encounters should offer suggestive evidence while retaining uncertainty. Players should often understand the type of risk they are accepting without knowing the precise outcome. Avoid making repeated arbitrary punishment the main source of difficulty.

## Visual and audio direction

Dark, gritty, grounded medieval fantasy. Stained stone, corroded metal, worn supplies, oppressive spaces, and scarce lantern light. Charcoal, dirty parchment, muted teal, rusty brown, and warm amber form the initial palette. Keep essential threats and interface elements readable.

The current visual baseline is **simple, shadow-heavy pixel environments with detailed, expressive character portraits and limited, deliberate animation**. Use bold room shapes, sparse textures, a restrained palette, and one clear encounter focal point. The owner preferred this reduced-detail direction over the intricate painted and densely textured pixel mockups. Exact environment resolution and production workflow remain open.

Suggested economical approach:

- Reusable walls, doors, floors, and props assembled into fixed first-person room views.
- Brief transitions between grid steps rather than fully animated travel.
- Enemy sprites with a few purposeful frames and clear silhouettes.
- Portrait variants that communicate condition and emotion.
- Sound, light flicker, restrained particles, and impact effects to support limited animation.

Pixel art is not automatically cheap: consistency, readable expressions, viewpoints, and animation frame counts determine workload. Choose a coherent pixel scale before producing final assets. Use Greed & Darkness as a visual reference, not a source of copied assets or a requirement to reproduce its animation technique.

The interface should preserve the two elements the owner particularly liked: expressive companion portraits and the exploration map. Sound, writing, and reactions should make losses and moments of relief feel personal. Content boundaries and the degree of graphic horror remain undecided.

## Reusable environment materials

Use a library of coordinated wall, floor, and ceiling textures applied to reusable geometry. Keep surfaces low-resolution, sparsely detailed, and consistent in colour and intended pixel scale. Combine material families with room shapes, props, and lighting for identity. Stains, cracks, moss, and symbols can later be separate variations or overlays.

The first test set lives in `art/textures/stone-v1/`: two 64 × 64 wall variants, one floor, one ceiling, and shared Godot materials. The existing prototype now uses them. This is a production-direction test, not a final resolution commitment. Windows import and a rendered corridor were checked; larger-room tiling, physical texel-scale consistency, seam cleanup, and phone appearance still need review.

### Environment-specific doors and stairs

Doors and stairs are reusable gameplay roles with appearances suited to each site. The owner intends these differences to be primarily visual, rather than requiring a new movement or interaction system for each environment.

| Gameplay role | Cave presentation ideas | Built-environment examples |
| --- | --- | --- |
| Passage barrier / door | Thick spider webs, tangled roots, or a dirt obstruction | Wooden door, iron gate, stone slab |
| Route upward | Dirt mound, rising natural passage, or climbable roots | Staircase or ladder |
| Route downward | Pit, sloping tunnel, or root-lined shaft | Descending stairs or hatch |

The cave examples preserve the owner's direction; exact assets and interactions are not yet specified. Webs can be visually cleared rather than swinging open, while still using the shared passage-barrier state. Natural ascents and descents can use the shared floor-transition behaviour.

Keep gameplay state separate from presentation: blocked/cleared passage, interaction availability, destination, and return linkage should not depend on whether the artwork depicts a door, web, staircase, or pit. A site's presentation can supply appropriate visuals, labels, and simple transition effects without changing the underlying rules.

Maintain clear navigation cues and consistent map meanings. A decorative pit must not be mistaken for a usable descent, and a passage disguised by roots must still be recognisable as interactable. Visual pits do not imply one-way travel or falling damage. Special requirements such as burning webs, cutting roots, tools, or resource costs are future mechanics requiring a separate decision; they are not implied by this visual direction.

This is guidance for the doors/stairs work already underway (#3 and #4), not a request to replace or duplicate it. The first implementation can remain generic and gain environment-specific appearances later.

**Implemented (#3, #4):** gameplay uses four roles — closed passage (cleared by stepping into it), blocked passage (can't pass yet), way down, way up. An `EnvironmentTheme` resource (`themes/cave.tres`, `themes/stone.tres`) supplies each role's name, messages, placeholder colour, and an optional scene for real art, plus the site's wall/floor/ceiling materials. The cave theme currently uses spider webs, tangled roots, a pit, and hanging roots; the stone theme uses doors, a barred door, and stairs. Taking a way down or up asks for confirmation first, and floors remember their state when revisited. Adding environment art means assigning scenes in a theme, not changing game code.

## Portrait system — direction recorded 2026-10-16

### Canvas, identity, and pose

- Use a **192 × 192 pixel canvas** as the current portrait working standard, subject to checking readability on Windows and iPhone.
- Keep detailed, expressive pixel portraits against simpler environments.
- Preserve each character's individual face, hair, and personality; a reusable body does not mean a shared generic face.
- Keep each character's pose, framing, lighting, and facial registration fixed across outfits, expressions, and animation frames. The current Mara sample looks slightly toward image right rather than directly at the player; use this as the initial pose reference, not a requirement that every character have an identical face angle.
- Prepare bases without a hood or outer equipment and with minimal plain clothing, leaving shoulders and neckline accessible for outfit layers.

### Layer structure and clothing

Build editable layered masters and export aligned full-canvas transparent layers. Do not trim or independently resize components. Share layer names, pixel scale, lighting direction, and attachment conventions across characters.

The intended structure includes background, back hair, body/neck, character head/face, eyes/brows, mouth, clothing, front hair, accessories, and condition layers. Exact ordering depends on the garment: a hood or cloak may need back and front pieces, and hair may need to overlap a collar. Reconstruct hidden pixels rather than relying on visible fragments from a flattened image.

Outfits should fit a known body template and neck/shoulder attachment points. Start with deliberate complete outfit sets rather than unrestricted combinations of every hairstyle, hood, collar, and armour piece. Validate overlap and clipping before adding variants.

### Reusable body templates

Adopt reusable upper-body templates to reduce later clothing work while retaining character-specific heads. The owner's planning target is **three body types for female characters and three for male characters**. Lean, average, and broad are proposed build labels; exact proportions and attachment geometry are not yet defined.

These are head-and-shoulders portrait templates, not a commitment to six full-body animation rigs. An outfit fitted to a template can be reused by characters using that template, with checks for head, neck, hair, and pose compatibility. Each additional template still requires an outfit fitting and validation pass.

The proposed validation step is one body template, two distinct character heads, and a shared outfit before producing the full six-template library. The template count is a planning target, not a requirement to create all six for the first playable.

### Condition layers

- Dirt, blood, bruises, and similar temporary marks use independently controlled overlays.
- Scars use persistent appearance overlays; how they are earned and carried between expeditions depends on unresolved gameplay persistence rules.
- Bandages are separate accessories that can cover wounds.
- Sunken cheeks, pallor, and other changes to facial condition use coordinated shading layers or replacement face variants rather than arbitrary dark marks.
- Condition placement must remain compatible with facial expressions and the character's fixed pose. Wounds should transition to healed scars where appropriate; bandages cover injuries. Avoid blindly stacking every effect until the face becomes unreadable.

### Simple animation

Use interchangeable pixel drawings rather than deforming a single face. Initial candidates are three blink states, a small set of speaking mouth frames, and coordinated eye/brow/mouth expression sets such as neutral, worried, angry, and exhausted. Speaking frames must remain compatible with the current expression. Full lip-sync is not required for the initial test.

Frame counts and expression coverage are proposals, not completed assets. Build and check one blink, a short speaking cycle, one outfit swap, and one condition overlay before expanding. Generated concepts require alignment and pixel cleanup; independently generating every frame risks identity and feature drift.

### Existing prototype and limits

`art/concepts/portraits/mara-base-192-v2.png` is the unhooded pose reference. `art/concepts/portraits/mara-layered-v1/` contains a 192 × 192 OpenRaster wardrobe test, separate transparent PNGs, a combined preview, and a README.

The wardrobe test demonstrates a tunic toggle and provides neutral eye/mouth replacement patches. It is **not a finished layered animation master**: hair, body, face, and original underlayer remain combined in its base image; blink, speech, scar, dirt, and fatigue variants are not implemented. The next production step is proper separation and hidden-area reconstruction.

## Proposed first playable

Build the **cave + campsite** as a complete initial loop before expanding into a multi-site campaign:

- A small cave dungeon with a completion objective and a route back to the campsite. Three compact floors remain a scope proposal, not a fixed requirement.
- A minimal campsite where the party can recover, replenish supplies, and prepare another attempt. Include retreat and re-entry; do not require a town or travel system for this first version.
- Three companions with distinct actions and visible conditions.
- A small reusable selection of encounters and enemy types.
- Basic supplies, health, one persistent injury mechanic, and a few strain states.
- Grid navigation, a readable map, turn-based combat, and expedition outcomes.

Prototype art can be placeholders. Validate decisions and readability before commissioning or generating a large asset set. Extensive diseases, quirks, relationship simulation, town management, and large content libraries are outside this initial proposal.

Success criteria:

- Players feel tempted to continue while understanding why someone wants to leave.
- Encounters change later decisions and allow more than one reasonable response.
- Deeper floors require better judgement as well as sufficient resources.
- Combat and exploration affect the same party condition and resource economy.
- Players can understand navigation, threats, and companion condition without fighting the interface.

## Open decisions

1. ~~Target platform and engine~~ — decided: Godot 4, Windows and iPhone, **landscape only** on phone (#6). Still open: final touch layout and minimum supported devices.
2. ~~Movement scheme~~ — decided: forward/back/turn. Each step costs time (#10). Still open: strafing and room-transition presentation.
3. Combat: enemies in first-person view (#13). Still open: targeting, positions, action economy, and retreat rules.
4. Strain states, player agency, and the role of trust or relationships.
5. What persists between expeditions and sites: companions, death, injuries, equipment, knowledge, relationships, and shortcuts. Carrying party history forward is a proposal; exact rules remain open.
6. Per-site floor count, expedition duration, difficulty curve, completion objectives, refuge recovery/services, and transitions/revisits between sites. First site: cave + campsite; later castle/portal escalation is campaign direction rather than a finalized destination list.
7. Coherent clue placement in procedural floors. (Navigability is guaranteed by the generator: rooms are joined incrementally, so every floor cell is reachable — #1.)
8. Environment resolution, final portrait cleanup/export workflow, animation budget, body-template proportions, and horror boundaries. Portrait working canvas is 192 × 192; see the portrait-system section for agreed direction and remaining proposals.

## References and concept history

- **Darkest Dungeon:** party strain, preparation, attachment, lasting costs, tactical cooperation. Inspiration rather than a recreation target.
- **Fear & Hunger:** vulnerability, consequential encounters, dangerous curiosity, and knowledge as progression.
- **Greed & Darkness:** dark pixel-art atmosphere and first-person presentation; movement and combat are not the intended template.
- Prior conversation mockups explored a flooded chapel, strained party portraits, and a map, then a grittier exploration/combat interface. They are mood and layout studies, not final assets or binding specifications; image files have not yet been added to this repository.
- Earlier title candidates included What Knowledge Costs and Below the Last Light. No release title has been chosen.
