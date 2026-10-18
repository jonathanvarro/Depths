# Hero stats, monster library and experience — research proposal

2026-10-18 · [Research #97](https://github.com/jonathanvarro/Depths/issues/97) · Related: [XP #47](https://github.com/jonathanvarro/Depths/issues/47), [armour #93](https://github.com/jonathanvarro/Depths/issues/93), [role ideas #101](https://github.com/jonathanvarro/Depths/issues/101).

**Research for owner review, not an approved implementation specification.** The new attribute formulas, XP rules, armour values and additional monsters are proposals. Existing enemy data and measured simulations are identified separately. No shipping gameplay rules or resources were changed for this research.

## Short owner summary

- Use **Strength, Dexterity, Vitality, Wits and Resolve**, with small values and derived fighting numbers. Keep Warden, Scout and Brawler as role templates, plus each person's existing strength/weakness. A role should still matter when everyone holds the same sword.
- Keep HP, damage and hit chances near the current scale. The cave does not need hundreds of HP or a large statistical rebuild. Add choices at levels 2 and 4 and an attribute point at level 3.
- Use an **18-entry cave/fortress catalogue**, including the two special opening enemies, existing goblins and queen, ten proposed additions/variants, and two optional mini-bosses. Build it in stages; this is not a request to make eighteen new art sets now.
- Give enemies an encounter cost based on their whole tactical role. Three weak animals are different from three guards/archers; enemy count and HP alone are inadequate difficulty measures.
- Let all active companions receive the full XP award. Reward resolved challenges and discoveries, with persistent limits on repeat combat learning because the cave regenerates each camp day. Recommend **levels 1–4 for this four-floor site**.
- Add one body-armour slot with cautious flat reduction. One point is already valuable; a full party in armour 2 sharply reduces current attrition. Leather needs costs and speed trade-offs, not large escalating reduction.
- Preserve the gentle lone-survivor opening, current main-hero unconsciousness, coin attacks, visible intentions without advance target disclosure, daily cave regeneration, free recruits/treatment, and the torch-to-lantern progression.

The most important measured result: in a controlled trial the candidate level-3 party wins the queen fight 99.7% of the time when fresh, but only 70.2% at 75% HP and 35 strain. Preparation and condition can remain more important than another level. These are simulated policy outcomes, not forecasts of human win rates.

## 1. Research and current-game audit

### Sources and what transfers

The following sources supply design reasoning or original rules. Depths' numerical proposals below are my synthesis, not borrowed balance tables. Paizo's rule text is read through Archives of Nethys with its book attribution; developer discussions describe their historical design, not necessarily every final shipped rule.

| Evidence | Useful implication for Depths |
| --- | --- |
| Paizo's creature-building guidance starts with concept, combat role, a statistics roadmap and signature abilities; it advises limiting complexity. [Building Creatures](https://2e.aonprd.com/Rules.aspx?ID=995) | Create recognisable skirmishers, protectors, ranged attackers and controllers. Do not construct monsters as full player characters or give every stat a high value. |
| Paizo distinguishes threat categories and the condition/resources a party needs to face them. [Combat Threats](https://2e.aonprd.com/Rules.aspx?ID=2716) | A fresh-party victory percentage does not measure whether a third consecutive encounter is fair. |
| Paizo's XP rules reward encounters, exploration and accomplishments, award the full amount to each party member, and discuss catch-up. [Experience Points](https://2e.aonprd.com/Rules.aspx?ID=574) | Support actions and sensible nonviolent solutions should not disadvantage progression. Keep replacements reasonably close in level. |
| J. E. Sawyer describes progressive bestiary XP with a finite learning limit, and explains the wish to avoid making combat the universally best quest solution. These are his own marked developer posts. [Obsidian's XP discussion, 2014](https://forums.obsidian.net/topic/68476-discussion-the-poe-beta-xp-system/page/7/) | Separate learning from unlimited farming. Repeated cave days can still earn gold without guaranteeing endless character power. |
| Pillars of Eternity's official PlayStation introduction emphasizes useful attributes and making different builds viable. [Character-building introduction, 2017](https://blog.playstation.com/2017/08/28/how-to-begin-your-quest-in-pillars-of-eternity-complete-edition/) | Avoid a single attribute that grants damage, accuracy, evasion and speed while another has no practical use. |
| Subset's own product description emphasizes telegraphed enemy attacks. [Into the Breach](https://store.steampowered.com/app/590380/Into_the_Breach/) | Readable intentions let difficulty come from combinations and competing responses. Depths retains its own rule: the action is shown in advance, not the target. |
| Overhype describes character backgrounds, experience/perks and weapons with different actions. [Battle Brothers features](https://battlebrothersgame.com/features/) | Preserve identity and role separately from weapon quality. A recruit should have more character than a damage number. |
| Ian Schreiber discusses costs, benefits and the difficulty of establishing a new game's cost curve. [Cost curves, 2010](https://gamebalanceconcepts.wordpress.com/2010/07/21/level-3-transitive-mechanics-and-cost-curves/) | Use mathematical checks and actual combat trials together, then test players. A complete stat sheet is not proof of balance. |

No recommendation here depends on having watched an entire conference video or on copying an external game's combat formula.

### What exists at the research baseline

Measurement baseline: `c987f29` and its existing combat/data. The committed baseline's source hashes and the research probe hash accompany [the results](stats-monsters-xp-results.json). The reported baseline figures are pinned comparisons, not a promise about subsequent live changes.

- Three active slots; the opening starts with wounded Mara. Current recruit baselines are Warden 24 HP/70% accuracy, Scout 16 HP/85%, Brawler 22 HP/65%, with one strength and one weakness each.
- Weapons **replace** the attack range, then add an accuracy bonus. A rolled Strong arm/Weak grip currently edits the fallback maximum damage; equipping a weapon can therefore erase that trait's damage effect.
- Initiative orders one action per living actor per round. Front/back rows and reach are implemented. Guarding uses an action; the Warden takes a quarter of an ordinary defended blow.
- Strain affects both accuracy and damage at 100/90/75/60% effectiveness. Bright light adds 10 percentage points to hero accuracy; a steady torch does not. Enemies do not lose accuracy in darkness.
- Rats dart/flee, spiders web/poison, goblins flank/shield/prepare heavy or coin attacks. Guards protect back-row enemies; archers reach the back row. The queen starts behind two guards, may call one replacement guard, and enrages below half HP.
- Floors 1–2 are natural cave, 3 fortress outskirts, 4 fortress. Resting at camp advances the day and regenerates ordinary cave layouts/enemies. Gate destruction and queen completion have persistent flags.
- Main heroes fall unconscious and can recover; ordinary recruits can die. A wipe loses carried goods/gold, protects the tent stash and preserves main heroes with injury. Recruitment and nurse treatment remain free; there is no starting-gold grant.
- There are **no implemented XP/level fields or armour equipment definitions** yet. Shields and padded coats await rules. Current weapon prices, supply timing, paid lantern and charity torches are established elsewhere.

The [October 17 economy report](starter-cave-economy-research.md) is useful design history. Its finite cave, hypothetical 48g initial funding and paid recruits/treatment are not current rules. This report updates the hero/monster/XP proposal for the built game; it does not restore those older economic assumptions.

**Owner update during research (#95):** starting-hero choice is now decided: Mara as the rogue, Corin as a Brawler, and a healer, sharing the escape with individual presentation; unpicked heroes do not exist in that campaign. The named main-hero traits remain proposals on that decision. The numerical Guide benchmark below predates this update (75% accuracy, initiative 10); concurrent work is changing Mara's profile. Retain the choice and test every selected hero's solo escape and party combinations before adopting the proposed formulas. These measurements do not validate the new rogue/healer/Corin implementations or unique traits.

## 2. Hero stat model

### Separate identity, attributes, equipment and condition

Use four layers: role and personal identity; persistent attributes/talents; equipment; temporary condition. The player should be able to explain why a number changed. A wounded Warden is still a Warden; handing the Scout an axe does not turn them into a Brawler.

Start with attributes around 1–3, allow 4 through advancement, and reserve a larger campaign range for later sites. Generate templates rather than offering unrestricted point-buy before the effects are tested.

| Attribute | Concrete benefit | Limits |
| --- | --- | --- |
| Strength / STR | Force-weapon damage; forcing optional obstacles | Does not also grant armour or hit chance. Do not make per-hero encumbrance a dependency. |
| Dexterity / DEX | +4 percentage points to base accuracy and +2 initiative per point above 2 | No additional damage, dodge, critical chance or extra turns. |
| Vitality / VIT | +4 maximum HP per point | No passive healing or automatic injury removal; no flat reduction. |
| Wits / WIT | Interpreting clues, handling mechanisms and reducing investigation time where authored | Never silently solves all traps or reveals the enemy's target. Needs actual exploration content before free allocation is fair. |
| Resolve / RES | Moderates positive strain gains and supports composed behaviour | Does not erase fear, improve coin odds or increase damage directly. |

Wits can have a modest tactical talent later, such as clearing a web more efficiently, rather than another global accuracy bonus. The Fixer/exploration-class package in #101 remains a separate owner proposal; these stats do not approve that class, bargaining discounts, extra carrying capacity or recruitment changes. Keep personal fear triggers separate from class weaknesses.

### Role templates and formulas

Each template has ten attribute points. The Guide/Survivor row is the pre-#95 balancing reference, not a new starting class that overrides the selected rogue/Brawler/healer. Give those main heroes their own calibrated profiles and signature traits after their actual numbers are settled; preserve the shared escape.

| Role | STR | DEX | VIT | WIT | RES | Level-1 HP | Base accuracy | Initiative |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Guide / Survivor | 2 | 2 | 2 | 2 | 2 | 20 | 75% | 10 |
| Warden | 2 | 1 | 3 | 2 | 2 | 24 | 70% | 8 |
| Scout | 1 | 3 | 1 | 3 | 2 | 16 | 85% | 13 |
| Brawler | 3 | 2 | 3 | 1 | 1 | 22 | 65% | 9 |

Candidate derivation, deliberately calibrated to preserve these existing baselines:

```text
max HP = 12 + 4*VIT + role HP offset + 2*(level - 1) + personal HP modifier
  role HP offset: Brawler -2, everyone else 0

accuracy = role aim base + 0.04*(DEX - 2) + personal aim + weapon aim
  role aim base: Guide .75, Warden .74, Scout .81, Brawler .65

initiative = role speed base + 2*(DEX - 2) + personal speed - armour penalty
  role speed base: Guide/Warden 10, Scout 11, Brawler 9

force-weapon damage bonus = STR - 2
positive strain multiplier = clamp(1 - .08*(RES - 2), .75, 1.15)
authored investigation time = max(2, 8 - WIT) ticks, where that action uses Wits
```

Apply the existing injury penalty to maximum HP afterward. The personal Sturdy/Frail modifier stays explicit. The aim/speed offsets are calibration constants, not another set of points players allocate. Review them if templates change; otherwise an attribute migration could unintentionally rewrite class balance.

For weapon damage, add the Strength modifier to both endpoints of force weapons, clamp the minimum to 1 and the maximum to at least the minimum, then apply the existing strain/defence rules. Initially classify sword, club, axe and spear as force weapons. A light knife can ignore a *negative* Strength modifier; a sling uses its own range with no Strength damage modifier. These tags are proposals, not current fields.

Convert fallback/unarmed ranges once so their new Strength modifier preserves the old total range; do not add Strength twice to an already class-adjusted legacy range. A Brawler's existing 3–5 fallback can migrate to base 2–4 plus Strength 3's +1. Scouts retain their existing sling profile. Any weapon bonus must run through the same path as fallback damage.

**Same sword example, level 1, steady light and no strain:** a Guide deals 3–5 at 80%; Warden 3–5 at 75%; Brawler 4–6 at 70%; Scout 2–4 at 90%. Expected direct damage is 3.2/3.0/3.5/2.7 per attack before rounding/target protection. The Brawler hits hardest on average; the Scout is fast and reliable; the Warden's value includes protection. A single strongest roll is not the comparison.

Resolve only scales **positive** strain gains. Relief remains relief. Do not multiply a signed net gain and accidentally weaken recovery. Wits and Resolve were not simulated by the probe: their gameplay changes require implementation and whole-expedition validation.

### Traits, guard and Luck

Keep one strength and one weakness. Retain Sharp-eyed/Sturdy/Quick and their opposites at first. Move Strong arm/Weak grip to an explicit modifier on the final weapon-aware damage path; do not both convert them to an attribute and preserve their old bonus. The existing +1 **maximum** damage is only +0.5 mean damage before hit chance, so replacing it with +1 to both endpoints doubles its average contribution.

Keep guarding as a role/talent feature: ordinary guard factor .5, Warden .25. Do not derive it from Strength or Vitality. Keep the Brawler's current -1 toughness as a named class drawback while evaluating #101, rather than quietly removing it during the stat migration. No new evasion stat is needed initially.

Luck stays a rare personal/main-hero trait. Preserve the current best-living-hero party bonus; do not sum three Lucky heroes or let players buy coin certainty with attribute points. Main-hero special talents should provide a distinctive option, rather than secretly superior values in every attribute.

### Condition and phone presentation

Do not add a further generic fatigue multiplier. Existing strain already affects both the chance to land a hit and the damage of that hit. Ignoring light/rounding, 60% effectiveness on both gives roughly 36% of steady damage output. That compounding is significant; test it before adding Resolve, armour and new debuffs together.

On the HUD card show portrait, current/effective maximum HP, condition icons and row. Put level/ready-to-advance in one small badge. The hero sheet can show five short attribute labels, weapon damage, current hit chance, guard and armour. Explain penalties on tap: for example, base 80%, strain, dim light and web, followed by the actual chance. Do not squeeze five attribute numbers or an XP bar onto every exploration card.

## 3. Monster library and difficulty

### Use families, roles and encounter cost

Each definition needs a stable ID, family, habitat/floors, role, HP, damage, accuracy, initiative, row/reach, intent sequence, status parameters, rewards and encounter cost. Enemies do not need five unused hero attributes. Keep base stats fixed by type; do not secretly scale a known rat to the party's level.

The following **18-entry catalogue** includes 8 current definitions and 10 proposals. Values marked current are taken from game data. Proposed values are starting hypotheses, not new content already validated by the simulator. Tutorial entries are restricted to their authored opening and are excluded from ordinary XP farming.

TP means **threat points**, a designer-facing encounter cost. Nominal ordinary encounter XP is 4 × TP, before the learning limits below. Mini-boss/queen awards are one-time encounter packages including their adds; they replace per-creature XP in those encounters.

| ID / enemy | Status | Floors | HP | Damage | Accuracy | Initiative | TP | Nominal XP |
| --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| starved_rat / Starved rat | Current tutorial | Opening | 5 | 1–2 | 60% | 11 | — | 0 |
| small_spider / Small spider | Current tutorial | Opening | 6 | 1–2 | 75% | 9 | — | 0 |
| rat / Cave rat | Current | 1–3 | 4 | 1–3 | 70% | 12 | 1 | 4 |
| great_rat / Great rat | Proposed | 1–2 | 7 | 2–3 | 70% | 11 | 2 | 8 |
| cave_bat / Cave bat | Proposed | 1–2 | 5 | 1–2 | 70% | 14 | 2 | 8 |
| rock_beetle / Rock beetle | Proposed | 2 | 10 | 2–3 | 65% | 6 | 3 | 12 |
| spider / Cave spider | Current | 1–3 | 6 | 2–3 | 75% | 9 | 2 | 8 |
| webspinner / Webspinner | Proposed | 2–3 | 8 | 1–2 | 70% | 10 | 3 | 12 |
| venom_spider / Venom spider | Proposed | 2–3 | 8 | 2–3 | 75% | 9 | 3 | 12 |
| broodmother / Broodmother | Proposed mini-boss | Optional 2–3 | 20 | 2–4 | 75% | 8 | 6 + adds | 32 once |
| goblin / Goblin scavenger | Current | 2–4 | 10 | 2–4 | 70% | 10 | 3 | 12 |
| goblin_archer / Goblin archer | Current | 3–4 | 8 | 2–3 | 70% | 11 | 3 | 12 |
| goblin_guard / Goblin guard | Current | 3–4 | 12 | 2–3 | 70% | 8 | 4 | 16 |
| goblin_brute / Goblin brute | Proposed | 3–4 | 18 | 3–5 | 65% | 7 | 5 | 20 |
| goblin_trapper / Goblin trapper | Proposed | 2–3 | 10 | 2–3 | 70% | 10 | 3 | 12 |
| goblin_drummer / Goblin drummer | Proposed | 3–4 | 9 | 1–2 | 70% | 11 | 4 | 16 |
| gate_captain / Gate captain | Proposed mini-boss | Optional 3–4 | 22 | 3–4 | 75% | 9 | 6 | 24 once |
| goblin_queen / Goblin queen | Current boss | 4 | 32 | 3–6 | 75% | 10 | 10 + guards | 80 once |

The starved rat having more HP than the ordinary rat is current data; it does less damage, hits less often and lives in a protected scripted encounter. Its name is not a reliable numeric difficulty rating. The opening spider can be configured to take only glancing damage and require fire; that authored behaviour supersedes a generic HP comparison. Neither belongs in normal procedural groups.

### Readable identities and drops

| Enemy | Intent/action identity and response | Row/reach and drop |
| --- | --- | --- |
| Cave rat | Existing lunge at a vulnerable hero; defend draws it; it may flee when hurt. | Front; no coins. |
| Great rat | Proposed **Rush → Recover**: one heavier lunge, then a visibly weaker action. Protect the exposed hero or finish it during recovery. | Front; no coins. |
| Cave bat | **Swoop → Land**: can reach the back on the swoop but becomes reachable by ordinary melee afterward. No permanent flight immunity. | Alternates; no coins. |
| Rock beetle | **Curl → Unfold → Bite**: reduced damage while curled, a clear opening afterward. Attack its partner or wait/guard instead of chipping forever. | Front; no coins; nearby cache is a separate reward. |
| Cave spider | Existing web weakens one next action; bite refreshes bounded venom. Can attack past the front and ignores defenders when choosing targets. | Back/reach; no coins. |
| Webspinner | More frequent **Web**, weaker bite; control support paired with a single damage dealer. Never repeatedly skips all a hero's turns. | Back/reach; no coins. |
| Venom spider | **Venom bite**: proposed 2 damage for each of two victim turns, refreshing rather than stacking. Strong warning and only one in early groups. | Back/reach; no coins. |
| Broodmother | **Call hatchlings → Bite**; below half HP becomes aggressive. One call of two ordinary spiders total, with a fixed enemy-count limit. | Front; no purse; optional authored 10–16g cache. |
| Goblin scavenger | Existing swing, flank, shield, heavy wind-up and rare coin attack. Do not give the goblin's lethal coin behaviour to every goblin variant. | Front; current 2–6g purse. |
| Goblin archer | Existing **Nock arrow → Shoot**; guard or reach it through the front line. | Back/reaches anyone; current 1–4g. |
| Goblin guard | Existing **Brace/Bash**; protects back-row allies while standing in front. The wall does not stack for two guards. | Front; current 2–5g. |
| Goblin brute | **Heavy wind-up → Heavy blow → Recover**. Slow and dangerous; guarding is a strong response. No surprise critical on top. | Front; proposed 2–6g. |
| Goblin trapper | **Set snare → Strike**; proposed snare lowers one hero's initiative by 2 for one round, not a lost turn. Further floor tripwire mechanics remain #94. | Back/reach if using a thrown weapon; proposed 1–4g. |
| Goblin drummer | **Beat → Strike**: grants allies +1 on their next normal physical hit, then expires; no stacking or coin/venom amplification. Reach/focus the support. | Back, ordinary attack needs front; proposed 2–4g. |
| Gate captain | **Rally → Heavy wind-up → Strike**; the rally can brace one ally for one attack. Separate optional patrol leader, not a silent replacement for the built gate fight. | Front; proposed 6–10g; encounter package XP once. |
| Goblin queen | Existing call, screech and coin cleaver; below half HP steps forward and hits harder. Guards and phase transition are clearly announced. | Starts back, reaches anyone; current 20–30g purse and separate 50g site bounty. |

The two opening enemies keep their existing tutorial intentions and scripted restrictions. No animal-harvesting, crafting reagents or new currencies are implied by the catalogue. Different fur/silk colours alone do not justify another entry; a variant must add a decision the player can recognize.

**Intent contract:** plan the action before the player's response, display a short label/icon, execute that action, then plan again. Random choice may select the next advertised action, but must not replace it secretly at execution. Show action severity/reach where necessary, not an advance victim marker. Coin attacks still select a target when they reach their existing resolution step. Keep status duration and whether an effect refreshes visible on inspection.

### Encounter budgets and introduction order

Threat points are a sorting aid, not a complete combat equation. Count all enemies, then add **+2 once** when a front guard protects a meaningful back-row threat, and **+2 once** for a particularly dangerous control/damage combination such as two venom sources plus a flanker. Do not charge the same synergy once per pair. Reserve the cost of all possible summons before spawning the initial group.

| Full party, ordinary condition | Trial TP range | Example and purpose |
| --- | --- | --- |
| Floor 1, level 1–2 | 3–5 | Three rats (3); rat + spider (3). Learn focus/guard and web. |
| Floor 2, level 2–3 | 5–7 | Goblin + two rats (5); great rat + spider + rat (5). Mixed threats. |
| Floor 3, level 3 | 7–10 | Two goblins + archer (9); guard + archer (7 + 2 wall). Reach and support. |
| Floor 4, level 3–4 | 8–12 | Guard + goblin + archer (10 + 2 wall). Sustained tactical pressure. |
| Current gate set piece | 13 | Two guards + archer: 11 + 2 wall. Warn and allow retreat. |
| Current queen set piece | 24 | Queen 10 + two guards 8 + possible replacement guard 4 + wall 2. |

Broodmother with two reserved spider adds costs 6 + 4 = 10. Captain + scavenger costs 9. These are optional challenges, not mandatory random surprises. The current no-retreat queen rule stays, with an explicit pre-entry warning.

For one or two conscious heroes, lower ordinary budgets and use authored fitting groups. TP and row feasibility must supplement the existing party-size filter: two guards are not equivalent to two rats. Never generate a party/encounter combination with no legal offensive response. A back-row hero without reach must have a route to move forward; a flying enemy must eventually be hittable. The queen is an explicitly signposted full-party challenge, not an encounter automatically reduced to one enemy for a lone hero.

Introduce one mechanic at a time: rat, then spider; ordinary goblin before brute; archer before guard+archer; a support before a support+control combination. Gate/fortress mechanics build toward the queen. The bestiary can initially show habitat, observed intentions and a plain danger label; disclose precise HP/stat knowledge only if that is the desired interface. Runtime players do not need TP or an encyclopedia of formulas.

**Production stages:** retain the eight current entries; first add great rat, webspinner and drummer; then beetle/bat/venom/brute/trapper; add optional mini-bosses after ordinary group tests. Art can reuse a family base with a clear silhouette/prop change, but a mini-boss and support need recognisable identities. This is a roadmap, not authorization to implement new behaviours or commission the whole list.

## 4. Experience, talents and replacement heroes

### A small curve with meaningful choices

Recommend individual cumulative XP with **shared full awards** for the active party. It is not divided by party size, and last hits give no bonus. Include an unconscious main hero who participated and remains with the party; an ordinary dead recruit does not become an XP container for a replacement.

| Level | Cumulative XP | Growth |
| --- | ---: | --- |
| 1 | 0 | Role template, personal strength/weakness, basic actions |
| 2 | 80 | +2 maximum HP; choose one role talent |
| 3 | 220 | +2 maximum HP; +1 attribute, within the cave's proposed maximum 4 |
| 4 | 440 | +2 maximum HP; choose a second role talent; cave cap |

This is a revision of the earlier three-floor/three-level proposal for the implemented four-floor site. Aim for level 2 after one or two purposeful early outings, level 3 during the outskirts approach, and level 4 for a thorough fortress approach or site completion. Do not require exhausting all optional learning to fight the queen. Give the level choice at camp; a mid-fight threshold does not grant healing or a surprise extra turn. Raising maximum HP does not refill current HP, cure an injury or clear strain.

Example **candidate** talents; all need testing and owner selection:

- Warden: a once-per-fight explicit Interpose action versus improved ordinary guarding. Do not make both passive or bypass the existing spider/flanker identities without saying so.
- Scout: clear their own web when changing row, versus an additional clue from a risky investigation. No permanently hidden-target revelation or extra full turn.
- Brawler: once-per-fight +2 physical damage on a declared attack, versus less of their existing incoming-damage drawback while guarding.
- A generic survival talent could offer once-per-expedition small strain relief during a real rest versus a modest reduction to one retreat's time cost. This is not a replacement for the proposed #95 named hero signatures; calibrate those separately.

These alternatives deliberately combine combat and expedition value; comparing only combat DPS would miss some benefits. The healer choice in #95 does not itself define a full magic system. Magic, the Fixer, body-part targeting and pre-fight ambush systems remain their own open decisions.

### What earns XP, and preventing daily rat farming

Grant the encounter award once when it is meaningfully overcome: combat victory, driving it off with a paid resource, or an authored bypass/negotiation that resolves the challenge. Merely retreating, walking out of range, opening a menu or repeating a skill check earns nothing. A rat fleeing during a won encounter still counts as overcome. The tutorial's forced torch escape grants no per-enemy farming XP.

Ordinary rewards are nominally 4 × TP per foe. Sum the group, but **do not award extra XP for synergy surcharges**, since that would reward deliberately seeking dangerous stacking. Gate, mini-boss and queen packages include their guards/summons and replace individual awards. A normal creature and a special encounter must never be credited twice for the same resolution.

Because camp rest creates fresh enemies, use a persistent **combat-learning allowance per site and depth**, not a reset per day, seed, hero or expedition. Suggested maximum ordinary combat XP: floor 1 **60**, floor 2 **80**, floor 3 **110**, floor 4 **90**. Awards use the remaining allowance, including a final partial award. Once exhausted, familiar fights still give their established loot/contracts but no additional ordinary learning. Show a short explanation; the player need not manage another resource meter.

Alternative: use finite bestiary learning by enemy type, as in Sawyer's discussed approach. It is attractive if discovery knowledge is central, but requires defining species versus variants and can make players feel obliged to hunt every variant. The per-depth allowance is the simpler first implementation here. **Choose one limiting scheme**, not both stacked invisibly.

Add stable, once-per-campaign-site accomplishments:

- Floor 1: up to 20 XP from selected authored discoveries.
- Floor 2: up to 40 XP from a meaningful access/discovery milestone and noncombat challenges.
- Floor 3: up to 30 XP from fortress knowledge/access milestones.
- Fortress: gate victory 40 XP, queen encounter 80 XP, final site completion 40 XP.
- Optional mini-boss packages 32/24 XP, only once each, outside ordinary learning allowances.

Without mini-bosses, the illustrative ceiling is `80 + 120 + 140 + (90 + 40 + 80 + 40) = 590 XP`. It reaches the 440 threshold without requiring every available point. These are allocation targets: current random events do not yet guarantee these discovery milestones. Author actual accomplishments before promising the level timing.

Contracts already pay gold for encounters. **Do not add renewable contract XP on top** in the first version. A unique story contract can have a separate one-time accomplishment, but its kills still use the ordinary learning allowance. Finding treasure, depositing it and selling it are not three accomplishments. Normal gold progress remains possible after easy combat learning ends.

### Recruits, unconsciousness and wipes

Recruitment stays free as currently decided. A newly generated recruit can begin at **one level below the highest camp-applied level actually earned in the campaign**, minimum 1, at that level's minimum XP. Candidate creation and hiring should use a consistent rule; do not let daily roster refresh generate increasingly powerful recruits without campaign progress. Existing heroes do not get repeatedly reset to this minimum by dismissal/rejoining.

Give an active recruit below that benchmark double the ordinary award, capped at the benchmark's minimum XP; any remaining award in that resolution proceeds normally. The campaign learning allowance is spent once by the encounter's base award, not once per hero or catch-up multiplier. Banked progression/talents are never transferred by selling equipment.

Worked catch-up: a level-2 recruit at 80 XP joins a level-3 benchmark (220). Six 12-XP encounters give 144 catch-up XP: after five they have 200; on the sixth, 10 base XP gives the missing 20, then the remaining 2 applies normally, ending at 222. They catch up through participating rather than last hits. If the site's allowances are already spent, the recruit remains at level 2; the queen must still be feasible at that level or offer an explicit preparation/training alternative. Test this late-casualty case before adopting the rule.

Heroes recovering at camp keep their existing XP. Start with no full expedition XP for the entire idle roster; catch-up avoids making injury treatment a permanent punishment. Main heroes retain XP and talents through unconsciousness and a wipe, matching their preserved identity. Ordinary fallen recruits lose their personal progression; surviving stored equipment, campaign milestones and learning records remain. Do not reset the learning allowance on a wipe or replace lost recruits with the dead person's exact talents.

At the cave cap, no conversion of surplus XP into gold/stat boosts is needed. Either stop accumulation with a clear cap indication or retain a display-only total; decide how the next site resumes progression before allowing banked XP to skip it. Do not auto-scale cave monsters upward to cancel levels already earned.

## 5. Armour and shields

Recommend one body slot, with **0–2 ordinary flat physical reduction** in the cave. Keep shields separate from passive armour: they improve an active protective choice, not another unconditional reduction layer. Do not require durability or repair fees to make initial armour interesting.

For an ordinary physical hit, preserve current guard ordering:

```text
roll damage; apply the enemy's advertised heavy multiplier if present
if the existing heavy attack is completely turned aside by guarding: damage = 0
otherwise apply the target's guard factor, rounding as currently defined
then damage = max(1, guarded_damage - toughness - body_armour)
```

Venom ticks, strain, hunger and direct event effects bypass body armour unless explicitly tagged otherwise. Coin attacks retain their existing heads/defending odds and guard bypass; their landed physical damage can use armour once, with minimum 1. Armour must not reduce the chance of tails, and a coin miss remains zero.

Against unguarded 1–3 damage, armour 0/1/2 gives mean damage 2/1.33/1. Against 2–4 it gives 3/2/1.33. A small integer is a large benefit. Vitality and armour should not both increase flat reduction, and the Brawler's -1 toughness must remain visible in the final comparison.

| Body item | Trial reduction | Initiative penalty | Price proposal | Role in the choice |
| --- | ---: | ---: | ---: | --- |
| Plain clothes | 0 | 0 | Existing/free | No protection; no speed cost |
| Padded coat | 1 | 0 | 28g, existing proposed price | Affordable protection without delaying a turn |
| Leather jerkin | 2 | -2 | 48g | Stronger reduction, often acts later |
| Hardened leather vest | 2; +1 only against advertised heavy physical attacks | -4 | 60g | Specialist protection; extra reduction capped at 3 and applied once |
| Reinforced / studded leather | 2 | -1 | 72g, rare | Expensive quality item with a smaller speed cost |

These are candidates for #93, not three new mandatory shop items. First test padded coat and one jerkin. The hardened exception is deliberately a later option if its added rule earns its complexity. A better item can be rarer and more expensive, but do not let the apprentice stock a full excellent set on day one. Prices must also be tested against actual earnings and supplies; the combat probe did not simulate affordability.

For a wooden shield, trial an active guarding improvement such as a small improvement to the ordinary guard factor; give Wardens a distinct protective benefit rather than shrinking their .25 factor indefinitely. Define hand occupancy, two-handed weapons and guard redirection before implementing the shield. Do not assume the current spear automatically occupies two hands merely because the earlier paper economy suggested it.

## 6. Worked simulation evidence

### Method and reproducibility

[The research probe](../tools/stats_research_probe.gd) uses the live `CombatState`, current enemy definitions and isolated in-memory hero/weapon copies. It does **not** implement the new attributes, talents, XP, Resolve or Wits in the game. [Raw results](stats-monsters-xp-results.json) include 60 scenarios/encounters × 600 paired-seed trials = **36,000 fights**, with no action-limit timeouts.

Policy: Warden guards when a heavy/coin/cleaver intent exists; otherwise each hero attacks the lowest-HP reachable enemy. It uses no consumables, retreat, row moves or sophisticated planning. Calls/phases, hit rolls, injuries, venom, strain, rounds and burning light run through existing rules. The seed is set after construction and fresh intents are replanned before combat; recorded trials use seed 20261018 + trial index.

Baseline trio: the pre-#95 Guide/Mara profile at 20 HP with iron sword, Warden 24 HP with existing fallback attack, Brawler 22 HP with fallback attack. It matches the baseline balance tool's basic trio. Candidate trio: Guide's sword, Warden's club, Brawler's axe; proposed weapon-aware Strength and +2 HP per level. At level 3, Guide/Brawler choose Strength and Warden Vitality, producing **24/32/26 = 82 HP**. The candidate level-1 kit alone is a change from the baseline, so baseline-to-level-3 improvements cannot all be attributed to XP. These are controlled reference profiles, not the newly selected #95 heroes.

The armour proxies add the reduction through `toughness`, which is mathematically equivalent for current physical damage. They do not include the proposed initiative costs. Treat them as **upper-bound protection trials**, not validated leather items. Talents, random recruit traits, Resolve, Wits and the ten proposed monster definitions were not simulated.

Most trials start with a full lantern (the existing simulator's default), fresh HP and zero strain. Torch comparisons use one full 50-tick torch and no lantern. The worn scenario starts at floor-rounded 75% HP, 35 strain and no armour, isolating condition pressure rather than pretending to simulate a full approach through the cave.

### Three-hero examples on floors 1–3 and the queen

| Encounter | Current baseline: rounds / HP lost | Candidate level 3: rounds / HP lost | Candidate level-3 victory / any hero downed |
| --- | --- | --- | --- |
| Floor 1: three rats | 2.32 / 7.03 | 1.98 / 6.17 | 100% / 0% |
| Floor 2: goblin + two rats | 3.02 / 11.48 | 2.54 / 9.71 | 100% / 0% |
| Floor 3: two goblins + archer | 4.34 / 20.27 | 3.60 / 16.99 | 100% / 0.7% |
| Queen + two guards, including her possible call | 10.92 / 36.39 | 8.44 / 27.72 | 99.7% / 9.5% |

All damage-loss/round means include defeated trials. Ordinary victories do not imply no deaths: loss of a recruit can occur in a won fight. The current baseline queen victory rate is **92.2%**, with someone downed in **36.8%** of fights. The candidate level-1 kit yields 95.5% and 28.8%; progression/kit changes are not interchangeable.

| Queen scenario | Victory | Mean rounds | Mean HP lost | Any hero downed |
| --- | ---: | ---: | ---: | ---: |
| Candidate level 3, fresh, no armour | 99.7% | 8.44 | 27.72 | 9.5% |
| Same, armour 1 on all three, no speed cost | 100% | 8.28 | 22.20 | 4.0% |
| Same, armour 2 on all three, no speed cost | 100% | 8.22 | 17.51 | 1.8% |
| Level 3, Scout replaces Brawler, no armour | 99.5% | 9.65 | 30.23 | 11.7% |
| Level 3, 75% HP and 35 strain, no armour | 70.2% | 12.91 | 43.27 | 60.7% |
| Level 3, fresh, torch instead of lantern | 98.8% | 10.09 | 33.78 | 15.3% |
| Current baseline, fresh, torch | 79.8% | 12.90 | 44.40 | 54.2% |

Interpretation: modest growth plus usable gear is already powerful; start cautiously. A Scout party remains viable in this narrow combat comparison even without modelling its exploration benefits. Light and arrival condition materially change the boss. Blanket armour 2 reduces mean queen damage loss by about **37%** relative to the unarmoured candidate, before charging any speed cost, so it should not be handed out indiscriminately.

With 600 trials, a displayed 100% means no defeats were observed, not guaranteed success; a rough upper bound on an unseen defeat probability is about 0.5% under this same model. It says nothing about player mistakes or untested compositions.

The existing `tools/balance_sim.gd` also ran successfully. Its report averages fresh independent fights, rounds wins to whole percentages and uses one default composition. Its queen comment mentions an approach condition but it does not actually run that second scenario. Keep it as a quick regression check; add condition, lighting, composition and downed/death metrics before treating it as a campaign balance model.

### Targets for the next playable test

- Normal floor-1 groups: approximately 2–3 rounds; low chance of a fresh party losing a hero.
- Floor 2: 2–4 rounds, modest cumulative attrition and visible counterplay.
- Outskirts/fortress patrols: 3–5 rounds, meaningful cost without routine unpredictable deaths.
- Gate/mini-boss: about 4–7 rounds, clear warning and preparation value.
- Queen: around 8–12 rounds when prepared, with the upper tail inspected; being worn down should make entry an informed risk.

Use both victory and probability of losing/downing a companion. Investigate unwarned ordinary attacks that can remove a healthy hero before their first useful action. Do not inflate every HP value to force a round target or strengthen the queen solely because a simple fresh, geared simulation wins often.

## 7. Implementation handoff and owner decisions

### Suggested implementation order after approval

1. Preserve snapshots of current combat output. Introduce a single derived-stat calculation path, role templates and final trait modifiers; add an `attributes` resource/block so numeric Strength does not overwrite `Companion.strength`, which currently stores a trait description string.
2. Add a level/XP record and chosen talent IDs, plus the **campaign** learning allowances and accomplishment IDs. Keep the shared award transaction idempotent across interrupted fights/events. Save them explicitly through both `main.gd` save and restore paths, with defaults for old saves.
3. Integrate level review at camp and recruit catch-up. Verify main heroes, unconscious heroes, recovering heroes, deaths and wipes. Never award XP merely by reloading the unresolved cell or counting a summoned guard again.
4. Implement one armour slot and one leather trial, including speed penalty, rounding order and comparisons in the Pack/shop. Check gear traits still matter with the same equipment on every role.
5. Add threat-cost metadata and budgeted groups. Add proposed enemies a few at a time, with stable IDs, existing intent presentation and encounter/summon limits. Do not silently change the gate/queen narrative or no-retreat rule.
6. Re-run the live simulator, then test full expeditions on desktop and a landscape phone-sized view. Track gold, supply spend, time, strain, injuries, XP per outing and retreat reasons. The new enemies, talent actions and exploration benefits need their own tests.

Do not change supply costs, free hiring, nurse pricing, wipe losses, daily regeneration or the opening to make the proposed XP table fit. If funding or re-entry becomes a problem, open the relevant design decision explicitly.

### Decisions that matter first

1. **Five attributes or a leaner sheet?** Recommend the five above, with template-based starts and one later chosen point. Wits needs authored exploration utility; otherwise defer it rather than display a hollow stat.
2. **Growth pace/cap?** Recommend levels 1–4 for this site and modest growth. Level 4 should be achievable, not required for an exhaustive grind before the queen.
3. **Repeat-combat XP?** Recommend the persistent per-depth learning allowances. Choose the finite-bestiary alternative only if discovery knowledge will be a prominent system.
4. **Replacement investment?** Recommend one-level-behind recruits plus participation catch-up, retaining main-hero XP and respecting recruit death. Test late replacement when learning allowances are exhausted.
5. **Armour strength?** Recommend reduction 1 first, then a scarce reduction-2 leather piece with a real speed cost. Delay hardened/studded variants and shield rules until their trade-offs are clear.
6. **Monster scope?** Approve a staged subset of the catalogue; keep the two mini-bosses optional. The eighteen entries are a useful design library, not a requirement to ship every proposal together.

The intended result is visible growth without erasing vulnerability: the Brawler remains recognisable with a better weapon, a guard/archer pair changes the plan, the player learns from encounters, and a veteran party still needs light and the judgement to return home.
