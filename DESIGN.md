# Depths — Design Direction

Last updated: 2026-10-17. This is a living design document for the owner, Claude Code, and Codex. It records the discussion so far; it is not a complete implementation specification. Depths is the working project name, not a confirmed release title.

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

**Map appearance (2026-10-17, #34):** the owner wants rougher paper and a map that feels drawn by the heroes, with no perfect visible grid. See [the parchment-map design and visual study](docs/hand-drawn-map-design.md): worn edges, charcoal room/corridor contours, sparse annotations and clear symbols. Keep actual connections, scale, discovery and facing reliable. Full map can carry more drawing detail; the corner map stays sparse. This is recorded design direction, not a live renderer change.

Within each dungeon site, the objective is to reach its bottom floor or deepest objective and complete that site's challenge. Completion opens the way to another site; the campaign is no longer envisioned as only one increasingly deep dungeon. Exact objectives, completion conditions, and final encounters remain undecided.

*Implemented (#17):* every expedition ends one of three ways, followed by a results screen of what was **gained** (time, deepest floor, enemies overcome, encounters resolved, supplies found, strain eased) and **lost** (lamp oil burned, supplies used, retreats, health and strain changes, new injuries, heroes who didn't come back). **Returned:** taking the way up on floor 1 asks to leave the cave. **Wiped out:** the last hero falling, in or out of combat. **Reached the bottom:** on later expeditions, reaching the deepest point (where the others fell) asks whether to end there — a stand-in until the site's real objective is decided. After returning or reaching the bottom, **New expedition** goes back in from floor 1; the cave remembers its state, and a placeholder camp stop restores health, eases strain (−40) and resets hunger while injuries wait for the nurse. After a wipe, **Begin again** restarts the story until recruitment and the stash exist (#26, campsite).

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

**Recurring merchant (2026-10-16):** the owner requires a greedy merchant who follows the party from rest location to rest location, with a distinctive, memorable appearance that becomes increasingly obese and gross as the campaign progresses. The character design is approved; the original concept's middle figure is his starting build, initially with less gold/jewellery and increasing wealth location by location. He occupies the campsite's supply awning. See [the merchant design and revised progression concept](docs/merchant-design.md). Name, exact stage mapping, trading rules and any supernatural explanation remain proposals or open decisions.

**Decided 2026-10-17 (#40): the first campsite.**
- **Days:** the camp keeps a day counter. **Resting moves it forward one day.**
  - A **new day re-randomizes the cave** (new layouts, fresh enemies), and the merchant restocks.
  - Going back in without resting keeps the same cave.
- **Tent:**
  - **Rest** is safe and fully restores health and strain, at no supply cost.
  - The **stash** survives a party wipe.
- **Nurse:**
  - Treats lasting injuries, free until gold exists.
  - A treated hero is **out of play for a few days** by injury (e.g. limp 1, deep wound 2).
  - Treatment is optional; an injured hero may go back in untreated.
- **Merchant:** tops the pack up to the starting supplies once a day, free until gold exists (#42).
- **Smith:** shows his stock as coming soon.
- **Campfire:** waits for recruitment (#41).
- **Cave path:** leads to preparation.
- **No travel costs** between cave and camp.
- **Art:** the clearing starts as a placeholder; ChatGPT paints it later to fit the same six spots.
- **Ideas for later:** the king's forces arriving as the days pass (#80); paid scouts who map floor 1 (#81).
- *Implemented (first pass):*
  - After the results screen comes the **relief camp**: ChatGPT's clearing (#78) with the six places as large labelled targets that work with mouse, touch and keyboard (Escape goes back).
  - **Arriving heals nothing by itself.** The old automatic camp heal is gone; rest in your tent.
  - The tent's stash moves supplies and gear in and out. It is kept in memory only: party wipes still restart the game until recruits (#41) and saving (#45) exist.
  - The cave path summarizes the party and blocks the way down while no one is fit.
  - A new day re-seeds the cave, so floors are regenerated; going back without resting keeps the explored cave.

**Royal relief camp and art (owner, 2026-10-17, #78/#79):** the king is sending forces against the monsters and goblins, but something disrupted their arrival; they are reaching the area scattered and disorganized. The shortages and apprentice's makeshift tools follow from this. The cause remains open. [Campsite artwork](docs/campsite-art.md) supplies an empty clearing, six independent destination layers and separate merchant/apprentice/nurse portraits, ready to map to #40's six spots. Patched canvas and faded blue/ochre royal cloth are visual proposals; names and final heraldry remain open. The all-sites art review does not decide opening days or stock progression (#79/#80).

**Decided 2026-10-17 (#41): recruitment at the fire.**
- **Roles:**
  - **Warden:** protector; tough, good at Defend, draws attacks.
  - **Scout:** quick; acts early, hits more often, less health.
  - **Brawler:** damage; hits hard, less accurate, gets hurt more.
- **Each recruit** has a role, one **strength** and one **weakness**, shown before hiring. A personal fear comes later, with a fear system.
- **At the fire:** 2–3 candidates. Each new day one leaves and someone new arrives.
- **Cost:** free into empty slots until gold exists (#42).
- **Dismissing:** recruits can be dismissed at camp; Mara can't.
- **Full wipe:** the heroes and everything they carried are lost. The stash and the camp day remain, and play continues from the fire. Whether Mara can die in a wipe is decided later; for now she's treated like anyone else.
- **Portraits:** requested from ChatGPT (#82); role silhouettes until then.
- *Implemented:*
  - Recruit stats: Warden 24 health, defending takes a quarter of a blow; Scout 16 health, 85% to hit, acts early; Brawler 22 health, 3–5 damage, 65% to hit, takes +1 from every blow.
  - Traits: Sharp-eyed, Sturdy, Quick and Strong arm, against Clumsy, Frail, Slow and Weak grip (never on the same stat).
  - Heroes recovering with the nurse stay at camp while the others go down, and they survive a wipe.
  - After a wipe, the fallen and everything carried are gone; the camp, stash, day and anyone at camp remain.

**Decided 2026-10-17 (owner): torches first; the lantern is an upgrade.**
- The camp no longer hands out a lantern. Parties light the way with **torches**: the merchant's daily top-up gives 4, and one is lit automatically at the cave mouth if none is burning.
- When a torch burns out, the message says to light another from the pack.
- The **lantern** (brighter, so better accuracy and less strain, refilled with oil) becomes something to **buy once there's gold** (#42).
- The no-opening debug start still begins with a lantern.


**Decided 2026-10-18 (#42): gold.**
- **Earned from:**
  - coins in chests, packs and goblin stashes;
  - goblin purses (rats and spiders drop nothing);
  - treasure sold to the merchant;
  - posted contracts from the king's camp.
- **Spent on:**
  - merchant supplies (replacing the free daily top-up): torch 3g, ration 4g, dressing 4g, oil flask 6g, draught 12g, **lantern 40g**;
  - smith gear: knife 8g, club 10g, shield 16g, spear 18g, axe 24g, padded coat 28g, iron sword 40g.
  - Recruits and the nurse stay free for now.
- **Starting out:** the first camp visit after the opening gives the basic kit free, with **no starting gold**.
- **Selling:** gear sells back at 30%; treasure sells at its listed value.
- **Wipe:** carried gold is lost; gold in the tent stash is kept.
- **Contracts, treasure values and armour rules** are proposals on #42, to settle while building.

The suggested retreat flow is to return through the dungeon to its entrance before reaching camp, with discovered shortcuts potentially easing later returns. Travel costs, escape exceptions, refuge services, recovery timing, and prices still need design decisions. Rest spots inside the dungeon remain distinct from the outside refuge.

**Cave-camp staff and equipment (2026-10-16):** the owner wants a blacksmith sent from a nearby village and a nurse for the cave area. The smith is an apprentice, explaining the limited selection of quality items; the starting location should offer very basic equipment. The [updated campsite design](docs/campsite-design.md) proposes a sixth clickable smith area and places the nurse in the treatment tent. Exact stock, repair/crafting mechanics, NPC identities and later-site availability remain open. The original five-area interaction study predates this addition.

### Continuity and escalation proposals

**Decided 2026-10-17 (#26):** items stored at camp survive a full party wipe. The current expedition ends, and the player continues the same campaign with new recruits, recruited at the campfire. The tent provides the stash and party preparation. What happens to carried/equipped items, recruitment costs/availability, cross-site stash access and other campaign/dungeon state remains open; this decision does not reset the campaign or imply automatic resurrection. See [the campsite flow](docs/campsite-design.md).

Keeping companions, scars, equipment, relationships, and important discoveries across sites would give the campaign emotional continuity: the people approaching the castle are the ones who began at the cave campfire. This is a preferred design proposal, not a finalized save/persistence or permanent-death rule.

Escalation should introduce new hazards, tactics, and preparation needs as well as stronger enemies. An initially local problem could reveal evidence of a larger threat, providing a reason to travel onward; the specific story is open.

Open campaign questions: what counts as completing a site, whether old sites remain accessible, whether moving on is reversible, how revisits affect procedural layouts and cleared encounters, and what carries forward between sites and expeditions.

## Companions and strain

**Decided 2026-10-17 (#8):** the game starts with **one hero**. Their companions were killed in the dungeon and they need to make it out. The party has **three hero slots**; the others fill later (e.g. campfire recruitment, #26). Party state carries between floors, and any effect with a duration (such as healing over time) is completed in full when the party changes floor.

Each companion has a distinct role, personality, vulnerability, and reason to enter the dungeon. Portrait cards communicate physical and emotional condition.

**Personality/fear ideas recorded 2026-10-17 (#27):** explore lawful, neutral and lawless outlooks alongside individual values/boundaries; useful mixed-party synergies with disagreements and pair trust; fear as readable temporary strain; and modest class-bounded recruit variation (initially one strength, weakness and particular fear). See [the discussion notes](docs/hero-personality-and-fear.md) for examples, neutral-party trade-offs and open rules. These are proposals to develop, not implemented mechanics or finalized numerical balance. Courage can use the proposed Resolve attribute rather than a duplicate stat; the lone-survivor opening remains unchanged.

*Implementation:* heroes are `Companion` resources in `data/companions/` (name, role, motive, personality, vulnerability, portrait, health, effects over time). The placeholder starting survivor is **Mara**, the guide from the portrait concepts, starting wounded (14/20). One step = one unit of time.

**Decided 2026-10-17 (#8): the survivor starts on the deepest floor, where the companions died, and must climb out to the campsite.** On the deepest floor the generator puts the survivor's start in the room farthest from the way up (where the way down would be on other floors); the game opens there with "Your companions lie still. Find the way out." Reaching the way up on the first floor leads out toward camp (the campsite itself is #17/#18). **Decided 2026-10-17 (#30):** the companions' **bodies are in the starting room**; Mara is **hurt, confused and panicking** to leave. The escape is **brief — shorter than three full floors** — and doubles as a **tutorial** introducing the controls, setting and character.

**Refined 2026-10-17 (#30):** the escape is **one hand-built stretch of winding hallways**, separate from the main cave. There is **no map** during it, so the hallways need not fit together geometrically — a turn may lead somewhere that would overlap on a real map, but it plays as one continuous run. **Mara starts bleeding**: she loses health periodically as she walks (untreatable in the opening) and in **2–3 brief fights**, a rat first to teach combat. **When her health is low enough, the daylight exit appears**; she **cannot die** in the opening. About **3–5 minutes**. She is **Panicking without random bolting**, and **short just-in-time hints** teach the controls. Later expeditions explore the generated cave from the top.

*Implemented (#30), tuned by simulation:* `scripts/opening_generator.gd` builds the bodies room and a single long winding one-tile hallway (about 180–225 tiles, far more than needed) with two webs and three fights. Mara starts Panicking (80 strain) at 14/20 and faces down the room toward the way out, ChatGPT's two fallen companions in view. She bleeds 1 health every 12 time and fights a **starved rat, another starved rat and a small spider** (gentler tutorial versions). Daylight appears 4 tiles ahead once she is at **3 health or less and has fought at least twice**; her health can't drop below 2. Simulated: about 33–42 steps and 2–3 fights. No minimap or map; hints show for moving, turning, the web, the first fight and the Pack, worded for keyboard or touch. Leaving shows the results ("You stagger out into the daylight, alone."); the next expedition enters the generated cave at floor 1.

**Revised after the first playtest (#56, owner 2026-10-17):** about **5 minutes**, always **3 fights**. Mara wakes looking at the floor; the view lifts as her eyes open and close a few times, revealing the bodies before the line about them. She starts **bloodied and dirty but not panicking** — **panic sets in after fight 2**, with a hint explaining it (she hits less often and less hard; light, food and rest calm her). Movement is slower in the opening, and tearing through a web is a slower push. The hallway became a **maze full of left / straight / right choices, dead ends and loops** (lost, against the clock), with a web across the bodies room's doorway. **Fights come after distance walked** (steps 20, 44 and 68), so no branch avoids them; daylight opens a few steps ahead once all three are won and she's at 3 health or less (or after 130 steps regardless). Leaving shows **"Barely survived"** and leads to camp; later this screen will show gold retrieved and enemies slain. Simulated: about 75 steps; fights 1–2 about 2–3 rounds, fight 3 (now panicking) about 7 — fight length overall is for the combat discussion (#60).

**Hero dialogue (#57):** heroes speak in a small box above the portrait cards while their portrait talks. Lines come from a per-hero library (`data/dialogue/*.tres`) by situation — waking, the bodies, bleeding, finding the exit, being lost, webs, fights, being hurt, panic, darkness, daylight — picked at random without repeating the last line, with a short cooldown. In the opening Mara remarks that she's bleeding early on and later that she needs to find the exit.

**Torch tutorial (#58, #59, owner 2026-10-17):** the opening has **no lantern** - a dying **fire** lights the bodies room, and torches are Mara's only light until camp. She starts holding a **broken knife**. **Searching the bodies** (walk onto each) gives **two torches** and her companion's **iron sword**. Hints then walk her through the Pack: **equip the sword**, **drop the broken knife** (dropping destroys an item), and **light a torch**. Until a torch is lit she **won't leave the room** ("It's too dark..."). A torch burns about 50 time, so the first one **burns out between fights 2 and 3** and she lights the spare. In **fight 3 the spider strikes first** (and may poison her) and a hint offers **Item > Throw torch**: the spider flees the flames, but it was her last torch - **darkness brings panic**, explained by a hint. Daylight opens soon after (10 steps after the last fight, or once she's weak). At camp she gets a **lantern**; the torch is put out.

*Systems added:* weapons as `Equipment` resources (`data/gear/`; a hero's attack comes from their weapon), carried gear with Equip/Drop in the Pack; the party's light can be the lantern, a held torch (burns down, `Supplies.Source`) or nothing; torches are a supply (`data/items/torch.tres`) lit from the Pack; **Throw torch** in combat makes the target flee and uses up the held torch.

**Revised after the second playtest (#69, owner 2026-10-17):**
- **Waking:** a slightly slower wake-up, and she keeps blinking for a few seconds after she's up.
- **Start:** Mara is at **10/20**, **bleeding** (a red-drop icon on her card) with blood and dirt on her portrait, and carries **nothing**. She's restocked at camp. Only her card shows: no empty slots during the escape.
- **Solid props:** the bodies, the fire and chests are **solid**. Face one and walk into it to search or open it.
- **Tutorial cards:** hints are **centred cards**:
  - movement cards wait for the move;
  - Pack steps hold her still until the Pack is open ("Press I...") and then say what to do there;
  - explanations (bleeding, the first fight, panic, the forced throw) **pause** until "Got it" (or Enter).
  - While the Pack, a chest or a fight is open, the card moves aside.
- **Pacing:** a first stretch of maze is free to explore, closed off by a **second web**. The fights start 6 steps past it.
- **Chest:** after fight 1 a **chest** appears: in a niche cut beside her if the wall allows, otherwise in the nearest dead end ahead. A card explains it when she sees it. Its window sits next to the Pack:
  - **drag** an item across, **tap** it, or use the **take-all icon**;
  - it holds a **restorative draught** (her first healing) and a dressing;
  - a card then has her drink the draught.
- **Torch:** it no longer burns down in the opening. Instead, a few steps after fight 2 she **trips** (the view lurches down), the torch dies, and she must light the spare before she'll move.
- **Spider:** fight 3's spider **can't be beaten by attacking**. Blows glance off (0–1 damage), it never falls and shows no health, and it bites her repeatedly.
  - After her first swing a card teaches **Item > Throw torch**.
  - If she's at **4 health or less** without throwing, the game pauses and **only the throw is allowed**.
  - That was her last torch, so panic follows.
- **Daylight:** when it opens, every side passage off the path to it is **walled up**, so it can't be avoided.
- **Mara:** new lines for exploring, the second web, the chest, tripping, glancing blows, the forced throw and the fire, plus more for the existing moments.
- **Bleeding feedback (#71):** every point lost to bleeding flashes **red at the screen edges** and plays a **heartbeat**.
  - The weaker she is, the stronger the flash and the faster the heartbeat (not louder).
  - Below half health the edges stay **darker** between ticks, closing in.
  - Both stop when bleeding stops. `Main.screen_flashes` turns the flash off, for Settings (#52).
- **Art requests for ChatGPT:** a broken knife icon, broken armour (an armour slot is for later), and a chest; the chest is a plain box for now.

**Decided 2026-10-17 (#11): injuries.** Two to start, both liked by the owner: a **deep wound** (lowers maximum health) and a **limp** (each step costs extra time). An injury can only be **temporarily** eased in the field (e.g. a dressing) and is **properly treated at camp**.

*Implemented (#11):* `Injury` resources in `data/injuries/` — deep wound (max health −5) and limp (+1 time per step; the party moves at the slowest hero's pace). A clean dressing (3 time, survivor starts with 2) binds one injury so it stops hindering until camp; `Companion.treat_injuries()` is the camp treatment for the nurse to call later. Traps currently hurt (3) and have a 50% chance of a random injury, as a placeholder until #16. Injuries show as icons on the card (white band when dressed), in the Pack screen, and can drive portrait overlays (`blood`, `bandage`) once that art exists.

**Decided 2026-10-17 (#12): strain** rises from **time, darkness, lost health, injury and hunger**, and high strain causes **panicking and lost effectiveness**.

*Implemented (#12), numbers to tune in `scripts/strain.gd`:* strain 0–100 per hero, in four states — Steady (<25), Uneasy, Shaken (50+), Panicking (75+) — with effectiveness 100/90/75/60% for combat to use (#14). Per time unit it rises a little from time, more in a dim or dark lantern, with missing health, with each hindering injury, and when hungry (80+ time since eating) or starving (160+); a bright lantern eases it. Damage (+1.5 per health lost) and new injuries (+10) spike it; eating (−5) and resting (−20) relieve it. Panicking heroes sometimes bolt in a random direction instead of the step asked for (15% per step). The card shows a strain bar, a border that warms from neutral to red, a darker portrait, the `pallor` overlay from Shaken, and a tremor when Panicking; messages announce state changes. Mara starts Shaken (55) and not yet fed (hunger 60). Fear/Resolve (docs/hero-personality-and-fear.md) can plug into these rules later.

Strain should affect decisions and behaviour, rather than exist only as a number. Possible reactions include hesitation, requests to retreat, recklessness, and disagreement. Personal motives can make a particular discovery especially tempting to one person.

Trust, promises, and unequal sacrifices are possible ways to deepen this system, not yet mandatory features. Serious refusals or loss of control should have readable warning signs and opportunities for the player to respond.

Health and injuries carry beyond a battle. Stress, disease, and enduring quirks are candidate systems; avoid implementing all of them before the basic loop is proven. Close calls and lasting consequences should create attachment through play.

## Combat

Combat is turn-based. The room view becomes the battlefield while heroes remain represented by their portrait cards. Positioning, protection, and cooperation matter, and injuries or strain affect available tactics.

**Presentation study (#13, #31):** [desktop](art/expedition-v1/combat-desktop.png) and [landscape phone](art/expedition-v1/combat-phone.png) show enemies in the first-person cave with three portrait slots along the bottom and Attack / Defend / Item actions. These are static layout studies, not implemented combat or approved encounter balance; see [the art handoff](art/expedition-v1/README.md).

Exploration knowledge can provide an advantage or help avoid an unnecessary fight. Fighting should offer worthwhile gains while carrying lasting costs.

Possible objectives include defeating an enemy, protecting a companion, recovering an object, or holding a threat back while clearing an exit. Retreat should involve a meaningful decision; its exact mechanics remain open.

**Decided 2026-10-17 (#14, #15):** a hero's turn offers **attack, defend, or use an item**; a **magic system comes later**. Retreat is not decided — the owner's idea is that retreating moves the party to a random nearby spot at a cost of time and light. The cave's first enemies are **rats, spiders and goblins**, with room for more ideas.

*Implemented (#14), numbers to tune:* stepping onto an encounter starts a fight with the enemies standing ahead in the first-person view (ChatGPT's cave-v1 sprites), laid out as in the #13 study. Everyone acts in initiative order (ties go to the party); each round costs 1 time, so the lantern burns and strain builds. **Attack** hits on the hero's accuracy × strain effectiveness, plus a light bonus (bright +10%, dim −10%, out −25%; enemies see in the dark) — the lantern is a real advantage. **Defend** halves damage until the hero's next turn and draws enemy attacks, so a defender protects the others. **Item** offers only items marked usable in combat (the oil flask; food and healing stay outside combat). **Retreat** trials the owner's idea: the party flees 3–6 steps to a random spot, losing 6 time; the enemies stay, at full strength. Damage, strain and injuries (5% per hit from rats/spiders, 12% from goblins) carry back into exploration. Encounters never field more enemies than the party has heroes. **A fight fills its room** (owner, after playtesting the first build): entering any part of that room starts it, so fights can't be stepped around by accident; the survivor's opening room is kept empty, and retreat always lands outside the fight's room. Doorway warnings and visible enemies were considered and set aside for now. Falling offers a restart until #17's endings.

*Enemy tactics (#15):* each enemy introduces itself with a hint when a fight starts.
- **Rat — darting:** goes for the weakest hero (a defender still covers them); when below half health it may flee (40%), and a fight where every enemy fled is won.
- **Spider — webs and venom:** opens by webbing someone (their next action −25% to hit); its bite poisons for 1 damage at the start of the victim's next two turns (a new bite refreshes, never stacks); it drops from above, so defending doesn't draw it.
- **Goblin — cunning:** flanks whoever isn't defending; when at half health or less it may raise a shield (40%), halving damage until its next turn.

Deeper floors mix them (depth 1 mostly single rats; depth 3 pairs and trios like goblin + spider + rat), never more enemies than heroes. Simulated lone Mara at her start: rat 98% win, spider 74%, goblin 79%. A healthy party of three wins everything for now, losing ~2 / 3 / 5 health per fight on depths 1 / 2 / 3 — tune once recruits and equipment exist. More enemy ideas welcome (owner); candidates: a bat swarm that buffets the lantern (burns oil), a blind cave crawler that hunts by sound, spore-releasing mould that raises strain.

**Decided 2026-10-17 (#60): making fights strategic.**
- **Enemy intentions:** each enemy shows its **next action, but not its target**. For example, *winding up a heavy blow*, *spinning a web*, *raising a shield*.
- **Shorter fights, with length by enemy:** quick skirmishes for small creatures, longer fights for tougher ones. Damage rises on both sides, so each fight costs something.
  - Proposed: rat 1–2 rounds, spider 2–3, goblin 3–5.
  - Every enemy has at least one intention worth reacting to; for example, Defend halves a goblin's heavy blow.
- *Implemented (first pass):*
  - Every enemy plans its next move and shows it under its name, as an action without a target: rat *lunging* / *darting back*, spider *spinning a web* / *poised to bite*, goblin *swinging* / *winding up a heavy blow* / *raising a shield*.
  - A heavy blow hits double, but **Defend turns it aside completely**; a goblin never winds up twice in a row.
  - Retuned: rat 4 health (1–3 damage), spider 6 (0.75 accuracy), goblin 10 (2–4).
  - Simulated lone Mara with the iron sword: rat about 2 rounds / 2.6 health lost; spider about 3 / 2.4; goblin about 4 / 7.7 when only attacking, about 5 / 6.1 when defending against heavy blows.
  - The first-fight card explains intentions.
- **Positioning:** heroes and enemies get **front and back rows** once recruits exist (#72). Front takes most melee and blocks melee reach to the back; some attackers reach past. Moving costs a turn.
- **Later:**
  - deciding before a fight, such as sneaking past or striking first (#73);
  - **light as a weapon** stays an idea (#74);
  - the opening's torch throw is unchanged.

**Decided 2026-10-16 (#13): enemies appear in the first-person view.** A dedicated formation layout may be explored later. Do not assume the movement or combat of Greed & Darkness is the target. The owner likes its art styling but envisions these systems differently. Three party positions and a compact action set are starting proposals, not settled rules.

## Resources, rewards, and uncertainty

**Decided 2026-10-16 (#10):**

- **Time is the primary resource.** Every step costs time.
- **Lantern oil burns over time, and its level matters.** A high oil level gives more light and a greater advantage but burns proportionately faster; a low level burns slower but gives less light and less advantage. Managing the flame is a trade-off, not just a meter running down.
- **Food and healing are used outside combat.** Their effects generally take time to fully apply, or apply after a camp/rest event, rather than instantly.
- **Supplies live in a backpack/inventory screen**, not on the main HUD. Keep the HUD visually quiet.

*Implemented (#10), starting values from the economy research, all tunable:* 1 time per step (turns, bumps and menus are free). Lantern holds 100 oil; burn scales from 0.5/step nearly empty to 1.5/step full (a full tank lasts ~110 steps); light brightness and reach scale with oil, and an empty lantern leaves a faint glow so the exit is never locked. Oil flasks refill without waste (a part-used flask is kept). Rations heal every hero 4 over 20 time; a restorative draught heals the most hurt hero 10 over 20 time. A rest at a rest spot (once per spot, asks first) takes 20 time and completes all pending effects. The survivor starts with 3 flasks, 2 rations, 1 draught. Supplies are shown in a Pack screen (Pack button / I), not on the HUD. Dressings wait for the injury mechanic (#11); pack capacity is not limited yet.

**Decided 2026-10-17 (#65): changing floors spends the remaining healing time.**
- Effects still finish between floors (the #8 rule), but the time they still needed passes first: oil burns, hunger and strain tick. The arrival message says how long the party waited.
- Before: a draught plus a quick trip down and back up gave 10 health in 3 time and 4.5 oil, against 21 time and 28.5 oil for resting. Now it's 22 time and 29.8 oil.
- Healing costs the same anywhere, and a rest spot stays better because it also eases strain.

Other candidate resources: health and carrying capacity. Treasure can compete with provisions for space. Recovery consumes resources or requires safety.

Rewards include treasure, equipment, knowledge, shortcuts, and safe resting places. Discoveries should change future options, not simply add score.

Unknown encounters should offer suggestive evidence while retaining uncertainty. Players should often understand the type of risk they are accepting without knowing the precise outcome. Avoid making repeated arbitrary punishment the main source of difficulty.

*Implemented (#16):* chests, traps, strange objects and rest spots are **room events**, data files in `data/events/` (RoomEvent → EventChoice → EventOutcome). Arriving shows a **clue** that hints at the risk; choices such as search, step carefully, touch or rest spend time, and an always-present **Leave it** keeps the event for later. Investigations ("prod it first", "study it") cost time, add to the clue and keep the event open. Outcomes are picked by weight and can hurt, heal over time, change strain, injure, spill or add lamp oil, give supplies, rest, or spring an **ambush** fight. Each event has a depth range (goblin stash, hollow floor and old campsite only from depth 2). The generator's content mix shifts with depth: deeper floors have more fights and traps and fewer rest spots. First set: abandoned pack, goblin stash, tripwire, hollow floor, pale idol, still pool, dry alcove, old campsite. No gold yet, so rewards are supplies.

**Starter-cave economy research (2026-10-17, #25):** see [the sourced research and connected paper prototype](docs/starter-cave-economy-research.md) for proposed attributes, XP, rats/spiders/goblins, basic equipment, treasure budgets, delayed healing, camp services, recruitment and worked expedition costs. It separates the wounded survivor's opening escape from the later recruited-party budget, identifies missing reward/rest guarantees in the current generator and explains the connection between finite encounters and recovery safeguards. These are recommendations for owner review, not approved mechanics or playtested balance; individual death/loss rules, cave persistence, combat rules and exact values remain open. The confirmed #8 lone-survivor/timed-effect and #26 stash/recruitment decisions are preserved. No gameplay implementation is included.

## Visual and audio direction

Dark, gritty, grounded medieval fantasy. Stained stone, corroded metal, worn supplies, oppressive spaces, and scarce lantern light. Charcoal, dirty parchment, muted teal, rusty brown, and warm amber form the initial palette. Keep essential threats and interface elements readable.

The current visual baseline is **simple, shadow-heavy pixel environments with detailed, expressive character portraits and limited, deliberate animation**. Use bold room shapes, sparse textures, a restrained palette, and one clear encounter focal point. The owner preferred this reduced-detail direction over the intricate painted and densely textured pixel mockups. Exact environment resolution and production workflow remain open.

**Enemy detail direction (2026-10-17, #32):** the owner likes the creature designs but wants simpler enemies for consistency and lower requirements. Follow [the enemy art guide](docs/enemy-art-direction.md): silhouette-led shapes, sparse texture, shared lighting/palettes and registered poses. Its proposed 128px canvas and colour limits have a simpler goblin study for review; the detailed nine-pose set remains preserved as reference, not the final production style.

Suggested economical approach:

- Reusable walls, doors, floors, and props assembled into fixed first-person room views.
- Brief transitions between grid steps rather than fully animated travel.
- Enemy sprites with a few purposeful frames and clear silhouettes.
- Portrait variants that communicate condition and emotion.
- Sound, light flicker, restrained particles, and impact effects to support limited animation.
- Placeholder sound (#7) is generated, project-owned audio wired through each environment theme: looping ambience, varied footsteps, a bump, and a passage-opening sound (web tear in the cave, door creak in stone). Real recordings replace them by swapping files in the theme.

Pixel art is not automatically cheap: consistency, readable expressions, viewpoints, and animation frame counts determine workload. Choose a coherent pixel scale before producing final assets. Use Greed & Darkness as a visual reference, not a source of copied assets or a requirement to reproduce its animation technique.

The interface should preserve the two elements the owner particularly liked: expressive companion portraits and the exploration map. Sound, writing, and reactions should make losses and moments of relief feel personal. Content boundaries and the degree of graphic horror remain undecided.

**Navigation/menu study (2026-10-17, #37):** [shared interface proposals](docs/navigation-interface-design.md) compare Field kit (quiet exploration controls, dark worn panels, parchment documents) with Field journal (persistent book tabs and paper-led windows). The owner selected Field kit. **Updated direction (#61):** [Pack slots and the hero window](docs/pack-and-hero-window-design.md) records image-only inventory slots with hover/touch details; Equipment opens by default, Status is a tab in the same window, and portrait selection changes the inspected hero while retaining the active tab. A browser study demonstrates all three screens, explicit actions and navigation. Slot counts/categories remain visual proposals. The previous [labelled-row Godot study](docs/pack-screen-design.md) (#39) is preserved; the live Pack and global theme have not yet adopted the revision.

**Exploration HUD refinement (#62):** After liking the Pack/hero study, the owner requested a backpack icon immediately to the right of the portraits, a gear icon for Settings and a visible dwindling light source. The [HUD guide](docs/exploration-hud-design.md) and interactive study demonstrate one compact source-aware indicator: lantern reservoir/oil or torch life, with clear band/percentage readouts and controls that remain readable in darkness. This updates the earlier no-fuel-HUD suggestion. Item stocks remain in Pack; icon navigation retains accessible names, hover/focus labels and touch access. The live HUD is unchanged by this design task.

**Title/typography study (2026-10-17, #38):** The owner accepted the [title-screen concept and type roles](docs/title-screen-and-typography.md): Cinzel SemiBold for the title/major headings and Source Sans 3 for actions/body text. The cave background is generated separately; title/menu use actual bundled fonts with licences and reusable Godot resources. Desktop/phone captures and a specimen are provided; Depths remains a working release name. *Implemented (#18):* the title is now the game's first screen; Begin expedition starts the lone-survivor opening, Settings is shown disabled until settings exist, and Quit appears on desktop only. Before every later expedition a preparation screen shows the party's cards and condition, the lantern and the pack, then Enter the cave. These live screens and the isolated #39 Pack preview use the fonts; adoption across other screens remains separate work.

## Reusable environment materials

Use a library of coordinated wall, floor, and ceiling textures applied to reusable geometry. Keep surfaces low-resolution, sparsely detailed, and consistent in colour and intended pixel scale. Combine material families with room shapes, props, and lighting for identity. Stains, cracks, moss, and symbols can later be separate variations or overlays.

**Campfire visual (#63):** [campfire-v1](art/features/campfire-v1/README.md) supplies a fixed stone/log base and six-frame flame loop on 128px canvases, with separate solid/flame lighting and a warm local light. Claude's #59 opening hook loads it automatically; more maze placements remain with visible room contents (#46). The graphic does not add rest, healing, fuel, checkpoint or recruitment rules.

**Torch art (#68):** [torch-v1](art/props/torch-v1/README.md) adds a rough wooden torch with soot-darkened cloth, a live 64px Pack icon and reusable steady/dim/unlit presentation sharing the campfire flame library. The neutral solid body remains fixed as the flame shrinks. Held-art positioning stays with the shared interface work; this adds no torch mechanics or tuning changes.

**Opening equipment/chests (#70):** [tutorial art handoff](docs/opening-tutorial-art.md) supplies a broken-knife icon, damaged padded-armour icon and coordinated closed/open/empty wooden chest states. Chest drawings share a 128px canvas, floor pivot and palette; the knife's existing resource uses its damaged image. The other assets are ready for their implementation hooks, without new armour, loot or lighting rules.

**Cave event props (#75):** [room-prop art handoff](docs/cave-room-prop-art.md) supplies a torn pack with closed/searched states, a small worn pale idol, still black water on a horizontal floor card and a cold hearth with torn bedroll/tin cup. Reusable 128px scenes match the existing event clues. Select by event identity during visible-contents work (#46); the art adds no rewards, safety, light, collisions or event rules.

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
- Keep each character's pose, framing and facial registration fixed across outfits, expressions, and animation frames. Author neutral character colours/form separately from directional illumination; lighting passes must stay registered across variants. The current Mara sample looks slightly toward image right rather than directly at the player; use this as the initial pose reference, not a requirement that every character have an identical face angle.
- Prepare bases without a hood or outer equipment and with minimal plain clothing, leaving shoulders and neckline accessible for outfit layers.

### Layer structure and clothing

Build editable layered masters and export aligned full-canvas transparent layers. Do not trim or independently resize components. Share layer names, pixel scale, lighting-pass conventions and attachment conventions across characters.

**Separate illumination (owner direction, 2026-10-17, #35):** keep neutral character/outfit/expression art separate from incident highlights and directional/cast shadows. A character should support warm, dim and neutral lighting without a permanent lantern glow. See [the portrait lighting contract and migration audit](docs/portrait-lighting.md). Current Mara and merchant art has baked lighting and needs a source-art pass; the existing renderer does not yet implement independent lighting. Keep conditions and essential UI readability independent of scene illumination.

The intended structure includes background, back hair, body/neck, character head/face, eyes/brows, mouth, clothing, front hair, accessories, and condition layers. Exact ordering depends on the garment: a hood or cloak may need back and front pieces, and hair may need to overlap a collar. Reconstruct hidden pixels rather than relying on visible fragments from a flattened image.

Outfits should fit a known body template and neck/shoulder attachment points. Start with deliberate complete outfit sets rather than unrestricted combinations of every hairstyle, hood, collar, and armour piece. Validate overlap and clipping before adding variants.

### Reusable body templates

Adopt reusable upper-body templates to reduce later clothing work while retaining character-specific heads. The owner's planning target is **three body types for female characters and three for male characters**. Lean, average, and broad are proposed build labels; exact proportions and attachment geometry are not yet defined.

These are head-and-shoulders portrait templates, not a commitment to six full-body animation rigs. An outfit fitted to a template can be reused by characters using that template, with checks for head, neck, hair, and pose compatibility. Each additional template still requires an outfit fitting and validation pass.

The proposed validation step is one body template, two distinct character heads, and a shared outfit before producing the full six-template library. The template count is a planning target, not a requirement to create all six for the first playable.

**First reuse proof (#84, 2026-10-17):** [recruit portrait kit](docs/recruit-portrait-kit.md) supplies an older Warden and younger Scout with distinct neutral heads sharing the exact same covered-body/linen and padded-jerkin textures. Six PortraitSets cover neutral animated and static worried/exhausted expressions; both have four condition layers and separate authored upper-left light masks. This validates one clothed bust/socket at 192px and 96px, not all six body families.

**Recruit roster (#82, 2026-10-17):** [nine recruit faces](docs/recruit-roster.md) expands that same body/outfit to three each for Warden, Scout and Brawler, with different ages, genders and appearances. Seven new heads join the original two; all provide neutral blink/talk, static worried/exhausted expressions, four condition layers and separate upper-left lighting coverage. The combined catalog maps stable visual IDs to animated resources and flat fallbacks for Claude's recruit assignment. Brawlers have rough faces/old scars and the same basic garment; appearance grants no equipment or traits. This art task does not wire the live candidates or migrate Mara (#36).

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

**In game (#9):** a `PortraitSet` resource (`scripts/portrait_set.gd`, e.g. `data/portraits/mara.tres`) lists a character's aligned 192 × 192 layers in the order above — background, back pieces, body template, head, eyes, mouth, clothing, front pieces — plus named condition overlays (e.g. "blood", "bandage") and optional `blink_frames` / `talk_frames`. `scripts/portrait_view.gd` stacks the layers and animates by swapping drawings: automatic blinks every few seconds, `talk(seconds)`, and `hurt()` (red flash and small shake, no art needed). Reusing a body or outfit means pointing several sets at the same image. Blinking and talking stay inactive until frames are drawn. Portrait cards (name, health bar, condition icons) sit bottom-left, one per party slot, with empty slots faint.

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

1. ~~Target platform and engine~~ — decided: Godot 4, Windows and iPhone, **landscape only** on phone (#6). Still open: minimum supported devices.

   **Phone layout check (#6, 2026-10-16):** the UI is laid out at 648px tall and stretched to the screen, widening on longer phones. Measured at iPhone SE (16:9), iPhone 15/16 and Pro Max (~2.17:1) shapes in the editor: touch-pad buttons come out at 51–58pt (Apple's minimum is 44pt); default text is 20px (≈12pt on SE) so legends stay legible; the HUD sits inside iOS's safe area so the camera cutout, rounded corners and home bar don't cover the map or controls. Not yet tried on a real iPhone (#20).
2. ~~Movement scheme~~ — decided: forward/back/turn. Each step costs time (#10). Still open: strafing and room-transition presentation.
3. Combat: enemies in first-person view (#13). Still open: targeting, positions, action economy, and retreat rules.
4. Opening: decided (#30) — bodies in the room, brief tutorial escape. Still open: trust and relationships. Strain states, player agency, and the role of trust or relationships.
5. Partly decided (#26): stored items survive a party wipe and the campaign continues with new recruits from the campfire. Still open: carried/equipped item losses or recovery, currency, recruitment costs/availability, cross-site stash access, and persistence of injuries, knowledge, relationships, shortcuts and dungeon state. Carrying surviving companions' history between sites remains a proposal.
6. Per-site floor count, expedition duration, difficulty curve, completion objectives, refuge recovery/services, and transitions/revisits between sites. First site: cave + campsite; later castle/portal escalation is campaign direction rather than a finalized destination list.
7. Coherent clue placement in procedural floors. (Navigability is guaranteed by the generator: rooms are joined incrementally, so every floor cell is reachable — #1.)
8. Environment resolution, final portrait cleanup/export workflow, animation budget, body-template proportions, and horror boundaries. Portrait working canvas is 192 × 192; see the portrait-system section for agreed direction and remaining proposals.

## References and concept history

- **Darkest Dungeon:** party strain, preparation, attachment, lasting costs, tactical cooperation. Inspiration rather than a recreation target.
- **Fear & Hunger:** vulnerability, consequential encounters, dangerous curiosity, and knowledge as progression.
- **Greed & Darkness:** dark pixel-art atmosphere and first-person presentation; movement and combat are not the intended template.
- Prior conversation mockups explored a flooded chapel, strained party portraits, and a map, then a grittier exploration/combat interface. They are mood and layout studies, not final assets or binding specifications; image files have not yet been added to this repository.
- Earlier title candidates included What Knowledge Costs and Below the Last Light. No release title has been chosen.
