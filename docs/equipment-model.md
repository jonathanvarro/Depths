# Equipment model: rolls, growth, mastery and a worked region (#193)

Claude, 2026-10-31, under #192 and following the owner's direction recorded there. **This is a model for owner review: it changes nothing in the game.**
- **What's here:** a specification, six linked tables in `docs/equipment-model/` and a reproducible probe (`python tools/balance/equipment_probe.py`, seed 193).
- **Results:** [probe-report.md](equipment-model/probe-report.md).
- **Status of the numbers:** every coefficient is a proposal. Changing one in the JSON changes the model, with no code edits.

## The idea in one paragraph

Every weapon or piece of armour is its own object.
- **When it's found,** it rolls how well it was made (its **quality**), a little variation within that, how fast it will improve (its **growth**), and up to two **modifiers**. Those rolls never change.
- **As it's used,** it gains **mastery**, and each mastery level adds its growth.
- **At mastery 3 and 6,** the smith turns mastery into one chosen improvement.
- **If it's lost,** everything on it goes with it.

A badly made piece that grows fast can end up better than a fine one that doesn't. A cheap counter (a mace against armour, a goblin-bane blade against goblins) can beat a well-mastered general weapon in the right fight. That's what makes carrying, swapping and losing gear matter.

## What an item is

| Part | Rolled | Changes? | Notes |
|---|---|---|---|
| **Base** | Chosen from the region's pool | Never | Stable ID, slot, region tier, starting numbers (`bases.json`) |
| **Quality** | At creation | Never | Cracked, bent, ordinary (no word), fine, exceptional |
| **Stat roll** | At creation | Never | Weapons: ±1 to top damage (rare), −2 to +2 points to hit. Armour: ±1 health |
| **Growth** | At creation, once | Never | Slow, steady or swift per growing stat, **shown on the item** |
| **Modifiers** | At creation, 0–2 | Never | Within a budget, with conflicts and drawbacks (`modifiers.json`) |
| **Mastery** | Earned | Grows | Points kept as fractions; level 0–6 |
| **Tempering** | Bought at the smith | Grows | One choice each at mastery 3 and 6 |

**Generation order:** region and base → quality → stat roll → growth → modifier count → modifiers (no duplicates or conflicts, within budget; a drawback only alongside a strength). Nothing rerolls on equip, stash, travel or reload.

**Why growth is rolled once and shown:** you can judge an investment before you make it. A per-level roll would hide whether an item is worth mastering, and could punish you for investing.

## Formulas

- **Weapon damage:** base range + quality + stat roll (top only) + ⌊mastery × damage growth⌋ + modifiers.
  - Both ends shift together; the minimum is 1, and min ≤ max.
  - Example: an ordinary sword (3–5, steady 0.5) is 4–6 at mastery 3 and 6–8 at mastery 6. A cracked one (2–4, 0.5) is 5–7 at mastery 6. An exceptional one with slow growth (4–6, 0.25) is 5–7 at mastery 6.
- **To hit:** the weapon's part (base + quality + roll + mastery × accuracy growth + modifiers) is added to the hero's accuracy. The game's existing hit chance does the rest: strain, light, webs, and the 10–95% clamp. Nothing is counted twice.
- **Armour:** a base's armour number never rolls, because flat armour is very strong against small enemy damage. Quality and growth change **health** and **handling** (less slowing) instead. The only extra armour is the smith's mastery-6 "plate".
- **What grows:** each base lists its growing stats.
  - Swords, maces and spears grow damage.
  - Knives, axes and cleavers grow accuracy too.
  - Jerkins grow health; scale shirts grow health and handling.

## Quality and the existing tiers

Today's ladder (common, fine, magic, rare, unique) mixes two things: how good the base is, and how many modifiers it has. The model separates them:
- **Quality** is the five words above, shown in the name: "Cracked iron sword", or no word for ordinary.
- **Modifiers** are shown by the border, as now: none, blue for one, gold for two. **Unique** stays for named story pieces.
- **"Fine"** therefore means only quality. Today's "fine" tier (a sharpened or balanced base, no modifier) becomes quality *fine* with no modifiers.

**Cracked and bent are fixed quality, not damage to repair** (recommended). It's simpler, and it can't wipe out an investment by accident. If the owner wants repair later, the smith's tempering already gives a place for it, and repair would change quality only, never growth or modifiers.

## Mastery

`mastery.json`. Owner direction: mastery comes from combat, including being struck.
- **Weapons:**
  - **Earning:** 1 point per hit and 0.25 per miss (taking part counts), +1 for a kill.
  - **Scaling:** by how threatening the foe is for the region (0.25× for trivial foes, up to 2× for tough ones).
  - **Limit:** at most 8 points per fight.
- **Armour:** 1 point per blow that reaches the wearer, blocked or not (scaled the same way), plus 1 for every fight the wearer stands in. At most 5 per fight.
  - **No point in taking avoidable hits:** the cap and the participation share mean a careful player progresses about as fast as a reckless one.
- **Bringing it home:** +3 for every worn item after a successful return (not a wipe).
- **Thresholds:** 12, 30, 54, 84, 120, 162 points for levels 1–6. The first run had half these; mastery 3 came in about 5 fights, which was too fast.
  - **Pace in the worked region:** **mastery 3 in about 9 fights (1.4 expeditions); mastery 6 in about 28 (4.3 expeditions).**
- **Practised hands (catch-up):** a newly found item learns twice as fast while it's 2+ levels behind the hero's best item of that slot. A new counter can catch up, but doesn't arrive already mastered.
- **Smith tempering, at mastery 3 and 6:**
  - **The choices:** +3% to hit or +1 top damage for weapons; −1 slowing for armour, or +1 armour at mastery 6 only.
  - **The cost:** gold plus a regional material (iron ore, goblin-forged scrap, black ore).
  - **After a loss:** the smith remembers the improvement, but rebuilding needs a new item and the investment again.
- **Proposed new rule — Brittle:** a drawback that needs 25% more points.

## Modifiers

`modifiers.json`. A budget of 3 per item; most modifiers cost 1, and strong ones cost 2. A drawback gives 1 back and only appears with a strength. The kinds:
- **Offensive:** Keen, Heavy, Light-balanced, Biting (ignores 1 armour), goblin-bane, hound-breaker.
- **Defensive:** Warded, Braced, of mending.
- **Positional,** for map fights: of the back rank, Flanker's (+1 against a foe beside the party), Sure-footed (rear blows ×1.25, not ×1.5).
- **Expedition:** of steady nerves, of the lamplighter, of the mole.
- **Drawbacks:** Unwieldy, Brittle, Thirsty.

How many an item has depends on the region: 80/18/2% for none/one/two in region 1, 60/32/8% in region 2, 45/40/15% in region 3. This is separate from quality and from drop chance.

## The worked region: the Goblin Marches and the Queen's Hold (floors 3–4)

`region_marches.json`. Monster numbers come from the game, scaled for floor 4.

**Proposed new combat rules.** Enemies have no armour today, and a weapon's "strike" type only changes the animation. The model proposes:
- **Enemy armour:** goblin guard 2, brute 1, hollow miner 1, **the queen 2**.
- **Strike types:**
  - **Smash** ignores 1 armour.
  - **Slash** does +1 to an unarmoured foe.
  - **Pierce** does +1 to beasts.

Every table shows today's rules beside the proposal.

**Loot:** iron sword, light mace, boar spear (new, reach), goblin cleaver (new), studded jerkin (new), goblin scale shirt (new, armour 3, grows handling).

### What the probe found

The boss is the goblin queen (40 health; guards join every 3 rounds, up to 2). Win rates are from 4,000 simulated fights per loadout, party level 3:

| Loadout | Wins |
|---|---|
| Fresh ordinary sword and jerkin (mastery 0) | 35% |
| Exceptional sword, slow growth (mastery 0) | 86% |
| Ordinary sword and jerkin, mastery 3 | 89% |
| Cracked sword, swift growth, mastery 6 | 99% |
| **Light mace as the counter**, mastery 2 | 95% |
| **Biting goblin cleaver**, mastery 1 | 89% |
| **Sword of the goblin-bane**, mastery 1 | 96% |
| Region-1 leftovers (oak club, old jerkin), mastery 3 | 82% |
| Deep start, level 1, fresh ordinary gear | 16% |
| Deep start, level 1, mastered mace and jerkin | 88% |

**What this supports:**
1. **Several ways to be boss-ready, and no single key:**
   - a counter weapon (mace, goblin-bane, Biting);
   - mastery on ordinary gear;
   - a lucky exceptional find.

   Fresh ordinary gear is not enough, which is your direction: mastery and counters matter for the boss.
2. **Ordinary regional gear handles ordinary fights:** two Strikes for most goblins and hounds, and 3–5 for guards and brutes.
3. **Counters compete with mastery:** a mace at mastery 2 (95%) beats a sword at mastery 3 (89%) against this armoured boss, so swapping is worth it.
4. **Deep starts (#189) work with the right gear:** at level 1, fresh gear struggles (16%) but mastered gear holds (88%). Character level still matters: fresh gear wins 35% at level 3 against 16% at level 1.
5. **No lottery:**
   - exceptional quality is 5.2% of drops;
   - exceptional with swift growth is 0.65%;
   - two modifiers is 7.9%;
   - all three together is 0.04%.

   Nothing required needs these.

**What needs care:**
1. **Flat enemy armour makes +1 damage swing hard.** Against the queen's proposed armour 2, a mere +1 damage (exceptional quality) lifts the win rate from 35% to 86%. Either give the queen armour 1, or let exceptional quality add +1 to the top of the range only. The probe makes this easy to compare.
2. **Old gear stays good with mastery.** Region-1 leftovers at mastery 3 win 82%. That may be fine (your favourite club carries on), but it weakens the pull of the new region's loot. One option is that tempering needs the region's own material, so old gear can't be tempered past its region.
3. **Swift growth at mastery 6 is very strong** (99%, finishing with 59% health). The cap of 6 and the slower thresholds keep it far off, at 4+ expeditions, but that is the ceiling to watch.

**What's untested:**
- The boss model is simple (both front heroes strike every round; no Brace, stepping, Flare or back-row attacks). Real fights have more tools, so treat these rates as a lower bound.
- Exact coefficients, the new strike rules and the enemy armour values are all unplayed.

## Inspection on a phone

A proposal for the pack's item panel (844×390):

```
Cracked iron sword        [blue border: 1 modifier]
Damage 2–4   To hit −4%   Slash
Mastery 2  ▓▓▓▓▓▓░░░░ 41/54 → 3
Growth: swift damage (+1 every 1⅓ levels)
Next level: damage 3–5
Keen: +4% to hit
vs worn: +1 damage, −2% to hit   [green / red]
```

- **What it shows:** quality, the current numbers, the mastery bar with fractional progress, the growth word with what it means, the next level's change, and each modifier in words.
- **Comparison:** a line against what the hero wears now.
- **Phone fit:** everything fits the existing pinned inspection panel in two columns.

## Saving and migration

- **What a saved item stores:**
  - its base ID;
  - quality;
  - the stat rolls;
  - each growth tier;
  - modifier IDs with any rolled values;
  - mastery points;
  - tempering choices;
  - a schema version and an instance ID.
- **What the saved data leaves out:** derived numbers, which are recomputed from the tables. This keeps saves small and lets balance change without rewriting saves.
- **Today's generated gear** (fine/magic/rare `Equipment` copies) migrates by mapping:
  - fine → quality fine;
  - magic or rare → quality ordinary, with the nearest matching modifiers;
  - mastery 0, steady growth.
- **Static `.tres` items** (starting weapons, the shop) are ordinary quality, steady growth, no modifiers, until found or bought as new instances.
- **Nothing in this model touches player saves.**

## Decisions for the owner

1. The quality words and what they do, and whether cracked/bent are fixed quality (recommended) or repairable.
2. Whether enemy armour and strike types (smash, slash, pierce) become real rules, and the queen's armour (1 or 2).
3. The mastery pace: mastery 3 in about 1.4 expeditions and mastery 6 in about 4.3, with tempering at 3 and 6.
4. Whether old-region gear can be tempered with newer materials.
5. The modifier list, and whether drawbacks belong on weapons and armour (today only trinkets have them).
6. The inspection layout.

## Next implementation scope

Once the owner has reviewed this:
- **Code:** an `ItemInstance` (or extended `Equipment`) with the stored fields, a generator that reads these tables, mastery credit in combat (#173), tempering at the smith, and inspection.
- **Data:** the region-2 bases.
- **Saves:** migration and a save check.
- **Rules:** enemy armour and strike rules behind a switch until they've been played.
- **The bot:** the campaign bot gains mastery, so its results reflect the new progression.
