# Depths — Design Direction

Last updated: 2026-10-16. This is a living design document for the owner, Claude Code, and Codex. It records the discussion so far; it is not a complete implementation specification. Depths is the working project name, not a confirmed release title.

## Premise

A dark, first-person dungeon crawler about party strain, dangerous discoveries, and the temptation to keep going. Lead a small party through a procedurally generated dungeon to reach its bottom floor.

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
- Controls should be simple directional inputs. Whether these mean absolute map directions or forward/back/turn/strafe remains open.
- Entering a room commits the party to encountering its contents. It does not require opening every chest or touching every object.
- Rooms can contain creatures, traps, chests, strange objects, events, or places of relief.
- Some threats require an immediate response; others allow investigation or withdrawal.
- Investigation provides clues but consumes resources. Exact costs and whether each action advances time remain open.
- Procedural layouts should use consistent rules and reusable authored encounters so discoveries remain understandable.

## Map and dungeon progression

Preserve the readable map from the visual concepts, adapted to the grid. Show explored rooms and routes, the current location, blocked doors, uncertain passages, stairs, and known routes toward safety. Notes and unresolved discoveries provide reasons to revisit rooms.

The main objective is to reach the bottom floor. Its story purpose and final encounter are undecided.

Successive floors should become harder through stronger enemies, new behaviours, more demanding combinations, traps, and environmental hazards. Avoid relying solely on larger enemy health and damage values. Increased danger should be accompanied by rewards worth considering: equipment, treasure, knowledge, shortcuts, and access to deeper areas.

Allow moments of recovery within the overall decline. A defensible room or useful cache can make another floor seem possible. Descent should be a deliberate choice made with the party's condition and return route in mind.

Returning safely with useful gains should matter even when the bottom is not reached. Exact return-travel hazards, stair rules, and expedition persistence are unresolved.

## Companions and strain

Start by exploring a three-person party. Each companion has a distinct role, personality, vulnerability, and reason to enter the dungeon. Portrait cards communicate physical and emotional condition.

Strain should affect decisions and behaviour, rather than exist only as a number. Possible reactions include hesitation, requests to retreat, recklessness, and disagreement. Personal motives can make a particular discovery especially tempting to one person.

Trust, promises, and unequal sacrifices are possible ways to deepen this system, not yet mandatory features. Serious refusals or loss of control should have readable warning signs and opportunities for the player to respond.

Health and injuries carry beyond a battle. Stress, disease, and enduring quirks are candidate systems; avoid implementing all of them before the basic loop is proven. Close calls and lasting consequences should create attachment through play.

## Combat

Combat is turn-based. The room view becomes the battlefield while heroes remain represented by their portrait cards. Positioning, protection, and cooperation matter, and injuries or strain affect available tactics.

Exploration knowledge can provide an advantage or help avoid an unnecessary fight. Fighting should offer worthwhile gains while carrying lasting costs.

Possible objectives include defeating an enemy, protecting a companion, recovering an object, or holding a threat back while clearing an exit. Retreat should involve a meaningful decision; its exact mechanics remain open.

The precise presentation is unresolved: enemies might remain in first-person view or use a dedicated formation layout. Do not assume the movement or combat of Greed & Darkness is the target. The owner likes its art styling but envisions these systems differently. Three party positions and a compact action set are starting proposals, not settled rules.

## Resources, rewards, and uncertainty

Candidate resources include health, light, food, healing supplies, and carrying capacity. Treasure can compete with provisions for space. Recovery consumes resources or requires safety.

Rewards include treasure, equipment, knowledge, shortcuts, and safe resting places. Discoveries should change future options, not simply add score.

Unknown encounters should offer suggestive evidence while retaining uncertainty. Players should often understand the type of risk they are accepting without knowing the precise outcome. Avoid making repeated arbitrary punishment the main source of difficulty.

## Visual and audio direction

Dark, gritty, grounded medieval fantasy. Stained stone, corroded metal, worn supplies, oppressive spaces, and scarce lantern light. Charcoal, dirty parchment, muted teal, rusty brown, and warm amber form the initial palette. Keep essential threats and interface elements readable.

The latest proposed production direction is **dark pixel art with detailed character portraits, modular first-person environments, and limited, deliberate animation**. This replaces the expensive painted mockups as a potential initial asset target, while preserving their mood. The owner has asked about feasibility; final adoption and asset resolution remain open.

Suggested economical approach:

- Reusable walls, doors, floors, and props assembled into fixed first-person room views.
- Brief transitions between grid steps rather than fully animated travel.
- Enemy sprites with a few purposeful frames and clear silhouettes.
- Portrait variants that communicate condition and emotion.
- Sound, light flicker, restrained particles, and impact effects to support limited animation.

Pixel art is not automatically cheap: consistency, readable expressions, viewpoints, and animation frame counts determine workload. Choose a coherent pixel scale before producing final assets. Use Greed & Darkness as a visual reference, not a source of copied assets or a requirement to reproduce its animation technique.

The interface should preserve the two elements the owner particularly liked: expressive companion portraits and the exploration map. Sound, writing, and reactions should make losses and moments of relief feel personal. Content boundaries and the degree of graphic horror remain undecided.

## Proposed first playable

Build one short, complete expedition before expanding the dungeon:

- Three compact floors with a temporary bottom-floor objective and a way to return.
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

1. ~~Target platform and engine~~ — decided: Godot 4, Windows and iPhone. Still open: touch control scheme, phone orientation (portrait or landscape), and minimum supported devices.
2. Exact movement, facing, turn, and room-transition rules.
3. Combat layout, targeting, positions, action economy, and retreat rules.
4. Strain states, player agency, and the role of trust or relationships.
5. What persists between expeditions: companions, death, injuries, equipment, knowledge, and shortcuts.
6. Floor count, expedition duration, difficulty curve, and bottom-floor purpose.
7. How procedural generation guarantees navigable layouts and coherent clues.
8. Art resolution, asset workflow, animation budget, and horror boundaries.

## References and concept history

- **Darkest Dungeon:** party strain, preparation, attachment, lasting costs, tactical cooperation. Inspiration rather than a recreation target.
- **Fear & Hunger:** vulnerability, consequential encounters, dangerous curiosity, and knowledge as progression.
- **Greed & Darkness:** dark pixel-art atmosphere and first-person presentation; movement and combat are not the intended template.
- Prior conversation mockups explored a flooded chapel, strained party portraits, and a map, then a grittier exploration/combat interface. They are mood and layout studies, not final assets or binding specifications; image files have not yet been added to this repository.
- Earlier title candidates included What Knowledge Costs and Below the Last Light. No release title has been chosen.
