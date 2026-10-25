# Optional mini-boss encounters — a concept catalogue

2026-10-25 · [Design brainstorm #156](https://github.com/jonathanvarro/Depths/issues/156).

**Proposal:** twelve encounter ideas across the mine's possible deeper environments. Names, lore, rewards, locations and new mechanics are working concepts. This document adds no encounters, art, numbers or gameplay. The water/fungal/city/temple regions remain the [expanded-descent proposal](cave-descent-and-quests.md), not approved floor assignments.

The useful pattern is a recognizable place, a warning, one distinctive tactical rule and a reward worth considering. Difficulty can come from deciding how to approach the fight, what to protect, when to spend supplies and what to leave behind. Retain opportunities for a wounded party to back away.

## Existing work to build around

**Broodmother nest and gate-captain post belong to [#145](https://github.com/jonathanvarro/Depths/issues/145), not this catalogue.** Their enemy behaviours and art already exist; dedicated optional lair placement was in progress when this was written. The owner chose a threshold warning with Go in/Back away, free refusal, side rooms off the sole stair route, daily lair rerolls with beaten lairs staying beaten, and light scaling that leaves solo adventuring dangerous. The approved reward is a guaranteed magic-or-better item, extra gold and elite XP. Keep the gate and queen encounters unchanged.

The twelve ideas below are additional candidates, not twelve more bosses to insert now. They do not increase #145's agreed frequency. [#149](https://github.com/jonathanvarro/Depths/issues/149) also owns the smaller creature-linked encounter trial; the more elaborate Foreman below is a possible later development, not a duplicate implementation of that trial.

## Catalogue at a glance

| Region | Encounter | Distinctive decision | Starting point |
| --- | --- | --- | --- |
| Old workings | The Rat King | Break up the pack or withstand the leader's rush | Existing great rat/rat tactics and art |
| Old workings | The Last Foreman | Stop the working rhythm or endure it to preserve a discovery | Hollow miner, grabs and authored room events |
| Goblin holdings | The Tollkeeper | Pay for lesser access, fight for the hoard, or leave | Brute wind-up/recovery and a conversation |
| Goblin holdings | The Furnace Keeper | Use a gas burst against the enemy or take the slower safer approach | Brute and gas-bloat interactions |
| Flooded passages | The Sluice Maw | Spend actions on water controls or exploit the natural attack window | New local encounter states |
| Flooded passages | The Drowned Hookman | Rescue a dragged companion or press the attack | Existing grab release, plus proposed row displacement |
| Fungal hollows | The Graft | Destroy its nourishment or preserve valuable medicinal growth | New finite healing source/objective |
| Fungal hollows | The Spore Cantor | Interrupt a song and release irritants, or withstand its strain pulse | New interrupted/continued attack outcomes |
| Buried city | The Procession Warden | Break its restraints to pass or defeat it for the full prize | New alternate victory objective |
| Buried city | The Memory Custodian | Manage a delayed copy of an attack rather than always strike hardest | New delayed-copy tactic |
| Temple approaches | The Votive Knight | Spend healing despite feeding its next heavy strike | New healing-triggered charge and optional bargain |
| Temple approaches | The Kneeling Thing | Deal with an announced echo while its next motion begins | New delayed strike; later presentation prototype |

## Old workings: creatures and people the mine has changed

### 1. The Rat King

- **Warning and place:** stolen grain sacks, picked-clean bones and several dragging tails disappear into a royal supply store. A swollen great rat wears a tangle of stolen cord and metal scraps; the name is a miners' nickname, not a new ruler.
- **Fight:** the leader rushes and recovers while ordinary rats threaten exposed heroes. The immediate problem is whether to clear the small rats or defend against the larger charge. Start with the existing tactics; any later move behind bodyguards needs its own rule and pose.
- **Preparation:** use a ration to lure one scavenger away before entering, or save food and face the whole group. Keep the change visible and deterministic.
- **Reward/tradeoff:** recover a stolen royal cache. Its valuable is recognizable human property, not a magic sword inexplicably grown inside a rat. Food salvage can be a separate, clearly warned decision rather than an automatic sickness roll.
- **Why use it:** an early, understandable introduction to an optional lair, adds and supply preparation. Reuse a great rat for a prototype; no new species or art is required to test the choice.

### 2. The Last Foreman

- **Warning and place:** three blows on a shift bell answer a dragging pick. A dead foreman still oversees a collapsed working face, with two recognizable work stations and a worn tally board.
- **Fight:** a visible work rhythm alternates a grab, an assistant's blow and a heavy pick strike. The party can defend the dangerous beat and strike between it, or disrupt an assistant first. Make the cycle finite and readable rather than add endless miners.
- **Preparation:** find the shift record and silence or wedge the bell before commitment, removing one coordinated threat. A pick helps, but a slower manual solution remains possible. There is no real-time reaction test.
- **Reward/tradeoff:** secure the workers' keepsakes, useful equipment and a small clue about the mine's last shift. Preserve personal traces instead of treating every body as a container. This does not establish the culprit behind the hero's separate ambush.
- **Implementation:** familiar miner/grab/art ingredients; the coordinated rhythm and bell condition are extensions. First prove #149's smaller hollow-miner encounter.

## Goblin holdings: people who can bargain as well as fight

### 3. The Tollkeeper

- **Warning and place:** a barricaded side bridge leads to a stolen-goods store. A broad goblin with an iron maul demands food or coin. The ordinary route downward remains elsewhere.
- **Fight:** deliberately announced crushing blows, with a clear recovery window. A small attendant can protect or distract, but this is not another captain rally/horn fight. The core test is spending actions on defence at the right time.
- **Approach:** pay for access to a smaller trading/cache opportunity, challenge him for the full hoard, or back away. Payment must not secretly start the fight too. No option requires a persuasion class.
- **Reward/tradeoff:** a believable store of seized gear, plus an optional local shortcut. Paying avoids combat attrition but yields less; fighting risks wounds for the better cache. Losing access to this side route cannot block the main descent.
- **Why use it:** a mini-boss who creates a social decision. Existing brute behaviour makes the first combat trial comparatively small.

### 4. The Furnace Keeper

- **Warning and place:** a heavy masked goblin works bellows beside a cracked forge. Gas-bloats gather around its warm exhaust; scorched tools and a flickering blue seam warn what a flame could do.
- **Fight:** the Keeper winds up while a gas-bloat swells. The party can kill the bloat from the back, defend and wait, or throw a torch to burst it against the other enemies at a known cost to themselves and their light.
- **Preparation:** spend time opening a local vent to reduce the gas threat, or retain that gas as an offensive opportunity. This is a package state, not a mine-wide gas simulation. Any extra gas release has a fixed, declared limit.
- **Reward/tradeoff:** the forge's finished equipment and a useful repair/tool find. The dangerous gas is both the problem and a weapon; preparation changes the plan instead of making the encounter disappear.
- **Why use it:** a strong candidate for an early prototype using the already-built brute, bloat, back-row kill and thrown-torch interactions. The bellows/vent logic would be additional work.

## Flooded passages: the room matters as much as the creature

### 5. The Sluice Maw

- **Warning and place:** stripped fish, scored sluice gates and a pale jaw rising between two walkways. A large eel-like animal occupies the basin below an abandoned control platform.
- **Fight:** rising water lets it hide and prepare a lunge; after striking, its upper body is exposed on the ledge. Every ordinary weapon gets an attack window. Operating a local control can expose it earlier but costs a hero's action.
- **Preparation:** drain part of the basin from a side chamber or observe the cycle before entering. No swimming, oxygen bar or pixel-precise movement is required.
- **Reward/tradeoff:** recover a waterworks component and reach a stranded explorer's cache. After securing the basin, choose a useful drainage route or preserve a local water supply/rest opportunity; do not silently change the whole camp's economy.
- **Implementation:** local water state, valve action and exposed/submerged poses are new. Test with a small static basin and two or three states, not fluid physics.

### 6. The Drowned Hookman

- **Warning and place:** a hook scrapes the same arc across a wet landing. A drowned worker in a broken hauling harness drags an impossibly long chain behind him. His identity is still an open story choice.
- **Fight:** the hook catches an exposed hero and threatens to pull them out of the protective formation. Another hero can hit the Hookman to release the grip, or the victim can spend an action escaping. A solo hero retains that independent escape.
- **Preparation:** secure a loose winch or brace the landing before entry, reducing the drag's consequence. It cannot become a mandatory tool check or a coin that permanently removes a hero.
- **Reward/tradeoff:** recover a winch component, worker's token and the load the harness guarded. Freeing the captive competes with attacking the boss; protecting a weak companion becomes an active decision.
- **Implementation:** the existing miner grab/release is a useful starting point. Actual row displacement, bracing and harness state would be new rules; there is no current drowning system to reuse.

## Fungal hollows: tempting living resources

### 7. The Graft

- **Warning and place:** a humanoid shape kneels inside feeding roots. A translucent bulb visibly sends nourishment into it; smaller medicinal growth surrounds the same stem.
- **Fight:** one feeding bulb restores the body, using a small visible reserve that eventually runs out. Destroying it makes the fight easier. Preserving it requires surviving those extra recoveries while defeating the body. There must be no endless regeneration stalemate.
- **Preparation:** learn what the bulb contains from the nurse's description or a local sample. The player can spend time separating useful growth before fighting, accepting an expedition cost instead of a mandatory combat shortcut.
- **Reward/tradeoff:** more intact medicinal material if the bulb survives; a less costly fight if it is destroyed. Show the consequence before an irreversible attack. Essential medicine for a main quest must have another source.
- **Why use it:** the reward is part of the combat problem. This tests whether players value preservation over simply killing every target.

### 8. The Spore Cantor

- **Warning and place:** a folded fungal fan repeats fragments of a familiar voice from different distances. The sound is unsettling, but the combat interface stays truthful.
- **Fight:** it visibly inhales for a strain-inducing call. Hitting the full sac interrupts the call but sprays irritants; defending lets the call finish with a different, clearly stated cost. The question is which resource the party can afford to lose: health or composure.
- **Preparation:** clear a vent or use a one-use treatment to reduce one consequence. A torch can be a proposed stronger interruption at the cost of light and useful organic material. None of these counters is secretly essential.
- **Reward/tradeoff:** a usable sample, rescued traveller's cache, or a known boon with an attached burden. Not every version needs a new item. A “quiet heart, weaker healing” bargain would use existing effect fields, but needs tuning.
- **Implementation:** paired attack outcomes and a legible sac state are new. Prototype one inhale/call cycle; do not add a general hallucination or infection system.

## Buried city: fights with rules you can learn

### 9. The Procession Warden

- **Warning and place:** a motionless stone-and-bone bearer blocks an optional processional arch. Three restraints are visible around the arch; repeated marks connect them to the figure.
- **Fight:** the party can break those restraints while surviving announced blows, opening the side passage and ending the confrontation without destroying the Warden. Alternatively, defeat its body for the full guarded cache. Its purpose and builders are not settled by this working name.
- **Preparation:** nearby reliefs explain the sequence; an optional rubbing can clarify it earlier. The local package always contains enough information, even without a scholar or an earlier hidden quest.
- **Reward/tradeoff:** an earned side route for the faster resolution; more recoverable equipment for the more dangerous full fight. Recognize the non-kill resolution as success so the player is not tricked into thinking they failed.
- **Implementation:** breakable objectives and alternate combat completion are new. This is a later objective-fight prototype, not a data-only variant of a guard.

### 10. The Memory Custodian

- **Warning and place:** a thin keeper in an archive moves an instant after the party does. A pale imprint rehearses one visible attack before it happens again.
- **Fight:** it records one attack and repeats a bounded version a full round later. The recorded action remains visibly queued, giving the party time to defend, change formation or finish the keeper. It cannot copy arbitrary item effects or reproduce unlimited damage.
- **Preparation:** disturb a rehearsal surface to remove the first stored echo, or study the pattern to recognize its next cycle. The normal fight remains winnable without either.
- **Reward/tradeoff:** choose which optional fragile record to recover: a practical equipment pattern or a more personal historical account. Main-route temple information remains available elsewhere. No record automatically proves the commander guilty.
- **Implementation:** delayed action storage and clear echo feedback are new. Start with one fixed attack family and one queued echo, not a clone of all three heroes or deceptive copies of their HUD cards.

## Temple approaches: increasingly wrong bodies and costly promises

### 11. The Votive Knight

- **Warning and place:** a kneeling armoured figure wears half-melted offerings where its heart should be. It is a local temple encounter, not an assumed identity for the commander or his allies.
- **Fight:** healing a hero lights a visible votive, strengthening the Knight's next announced heavy strike. Healing is still allowed and can save someone; the party must prepare for what it awakens. Avoid an undetectable damage escalation or a blanket ban on recovery.
- **Approach:** a proposed conversation offers a modest boon with a known burden in exchange for leaving its vigil intact. Fighting yields a different guarded prize. An offering does not grant the same full combat reward for free. Holy water could extinguish one charge, not automatically win.
- **Reward/tradeoff:** a distinctive oath-linked trinket or access to a side reliquary. Keep benefit, burden and cleansing behaviour explicit. Exact religion, oath, numbers and item remain open.
- **Why use it:** builds on the game's healing, intentions and bargain themes. It needs a new charge trigger and dialogue branch, so follow the simpler prototypes first.

### 12. The Kneeling Thing

- **Warning and place:** a folded body appears smaller than the chamber it fills. Its motion leaves a second posture behind, and the dust shifts twice after a single blow. One dominant anatomical impossibility should remain readable in 2D.
- **Fight:** a heavy strike leaves one announced echo that lands a full round later, while the creature begins its next motion. The party reads the queued danger and chooses defence versus damage. No real-time dodging, input reversal or lying intentions.
- **Preparation:** a visible anchor can be disturbed before entry to suppress the first echo, or the party can preserve it for a different optional reward. This needs a clear explanation, not a guessed ritual.
- **Reward/tradeoff:** a sealing fragment, a warded side route or a specific trinket opportunity. The encounter does not define the relic, portal, final boss or the civilization's fate. Victory/retreat clears pending echoes; there is no hidden post-victory hit.
- **Implementation:** new delayed-strike rule and presentation proof. This is a later concept, distinct from the unselected [deeper-horror studies](descent-horror-concepts.md); it does not assign those paintings to runtime roles.

## Making these encounters worth seeking

- **Discoverable:** distinctive room dressing, sound and a threshold warning before combat. Preserve free Back away before commitment. Avoid a surprise mini-boss in an ordinary encounter slot.
- **Optional:** place lairs on branches, keeping a valid route to stairs and required quest targets. A local shortcut can be a prize without making the boss mandatory.
- **Readable:** one signature rule per first prototype, a visible setup and a recovery/counter window. A floor should teach the relevant ordinary mechanic before its mini-boss combines it with another.
- **Bounded:** finite reinforcements, healing reserves and delayed attacks. Count the complete encounter, not just the boss's starting HP. Retain independent escape/counterplay for a solo hero without making solo safe.
- **Rewarding:** locate valuables on defeated adventurers, in stores or at guarded structures when that origin fits. Let animal parts/materials have specific uses before making them new currencies. Existing #145 guaranteed item/gold/XP rewards stay as agreed.
- **Consequential:** a secured route, personal discovery, preserved resource or known mixed boon can matter alongside equipment. Give the player enough information to choose the cost they accept.
- **Persistent:** track paid tolls, preparation, alternate resolutions, claimed rewards and defeated lairs separately from regenerated coordinates. Match #145's completion policy and existing daily regeneration; do not duplicate loot after reload or a camp rest.

### Where gambling fits

Use it as an occasional voluntary second stake: after winning, take the visible cache or commit to opening its warned sealed compartment for a larger prize and a stated temporary curse risk. Make the lesser reward worth keeping. Show odds and outcomes before the committing action, then keep the owner's non-cancellable rare coin rule. Do not add a coin to every boss, make the required reward depend on one, or secretly roll away the prize the player already earned.

This connects to the [boon/curse review](boons-curses-and-gambling-review.md). Fully known bargains and deterministic preparation can provide tradeoffs without another roll.

## Best first candidates

**Rat King:** simplest new early lair to test readable preparation with existing foes.

**Furnace Keeper:** strongest reuse of current tactical interactions; tests whether gas, formation and throwing away light make an interesting fight together.

**The Graft:** clearest new fight-versus-reward dilemma; preserve the useful resource or destroy it for an easier victory.

Finish and observe the existing Broodmother/captain lairs first. If selecting one new trial, prefer the Furnace Keeper for combat reuse or the Graft for a stronger preservation tradeoff. Validate the encounter in its authored room with one, two and three heroes, including wounded parties and a party without a counter-item, before building a larger roster. There are no balance claims or new HP/damage targets in this brainstorm.
