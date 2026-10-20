# Balance report: full-campaign playtest (October 2026)

*Issues #49 and #119. The bot behind it is `tools/campaign_playtest.gd`, and the queen-fight lab is `tools/queen_lab.gd`. Nothing in this report has been changed in the game: every proposal below waits for the owner's decision.*

## How it was tested

A bot played **90 whole campaigns**, 30 for each starting hero (Mara, Corin, Sister Alwen). Each campaign starts at the camp after the opening escape and ends when the queen dies, or after 45 days without winning.

The bot uses the game's real rules: the same floors, enemies, room events, camp services, XP and saving rules a player meets. It doesn't draw anything, so all 90 campaigns run in about 90 seconds.

It plays sensibly but plainly:
- It explores each floor while there's still XP to learn there. On floors with nothing left to learn, it heads straight for the stairs.
- In fights it hits the weakest enemy in reach, braces against heavy blows when hurt, and drinks a draught when low.
- It turns for home when the party is hurt or out of light.
- At camp it levels up, sends lasting injuries to the nurse, fills the party with recruits, and buys torches, food, draughts and armour.
- It heals up before the gate and the queen.

A careful human would play better in places: arming recruits, choosing event options thoughtfully, using Defend more cleverly. Read the numbers as **an average player's experience**, not an expert's.

**Bug found and fixed along the way (9444b4e):** in about 1 cave in 6, the queen's hall was built over the stairs up on floor 4, leaving a party arriving from above with nowhere to stand and no way out. After the fix, no campaign got stuck.

## Results

| | Mara | Corin | Alwen |
|---|---|---|---|
| Campaigns won within 45 days | 16 / 30 | **23 / 30** | 9 / 30 |
| Days to win (median) | 19 | 19 | 24 |
| Party wipes per campaign | 2.1 | 1.4 | 2.8 |
| First reach floor 4 (median day / party level) | day 5 / 1.9 | day 5 / 2.1 | day 4 / 1.8 |
| Gate fight, wins per attempt | 30 / 40 | 29 / 37 | 29 / 38 |
| **Queen fight, wins per attempt** | **16 / 69 (23%)** | **23 / 60 (38%)** | **9 / 68 (13%)** |
| Fights won (all fights) | 93% | 95% | 92% |

**Health lost per visit to each floor** (a full party has roughly 60–75 health):

| Floor | Mara | Corin | Alwen |
|---|---|---|---|
| 1 | 1.1 | 1.6 | 1.5 |
| 2 | 3.2 | 3.7 | 3.8 |
| 3 | 7.0 | 7.9 | 7.6 |
| 4 (fortress, gate and queen) | 25.5 | 24.2 | 26.0 |

**Experience.**
- Each floor's XP is used up quickly: floor 1 by day 4–5, floor 2 by day 3–4, floor 3 by day 6–7, floor 4 by day 11.
- Heroes end the campaign at **level 2–3**. Before the queen, the most XP on offer is 380 (all four floors plus the gate), and level 4 needs 440. So level 4 can only come after the queen.

**Gold per campaign.** About 300–400 found, 50–60 from contracts and 115–145 from selling treasure; 410–545 spent, almost all on supplies.
- The lantern was bought in only 9 of 90 campaigns.
- The scouts' route was **never** bought: floors 1–3 are quick and cheap to cross, so 40 gold to skip floor 1 isn't worth it.

## What it means

1. **Floors 1–3 are gentle, and floor 4 is a wall.** Parties lose single-digit health per floor until the fortress, then about 25 per visit. Nearly every wipe happens at the queen, where the party can't retreat. The game ramps from easy to very hard in one step.

2. **The queen is mostly beaten by nerves.** A lab test of the queen fight alone (400 fights each, level 2, full health) shows how much starting strain matters:

   | Party | Strain 10 | Strain 30 | Strain 45 |
   |---|---|---|---|
   | Mara + Scout + Scout | 66% | 43% | 16% |
   | Mara + Warden + Brawler | 76% | 52% | 28% |
   | Corin + Scout + Scout | 96% | 83% | 58% |
   | Corin + Warden + Brawler | 95% | 85% | 75% |

   Real parties arrive at the hall at about **strain 30**, after floor 4 and the gate. Her screech then adds 15 to everyone, often more than once, so a party slides from Uneasy to Shaken mid-fight and hits less often and less hard. Fresh, the fight is fair; worn, it's mostly lost.

3. **The starting heroes aren't equal.** The opening hands every hero the companion's iron sword:
   - Corin's Strength makes it hit for 6–8.
   - Mara and Alwen lack the strength, so it hits for only 2–4.

   Recruits fight barehanded for 2–3. Corin's party simply kills the queen's side faster, which also means fewer screeches. Alwen, the healer, has no way to heal in a fight, so she plays as a weak fighter.

4. **Random recruits often make lopsided parties.** The three at the fire are random roles, so parties often end up with two back-row Scouts and one hero holding the front alone.

5. **Pacing.** Wins take a median of 19–24 days and 19–24 expeditions. That's mostly repeat attempts at the queen after wipes: the bot reaches floor 4 by day 5.

## Proposals for the owner (not applied)

Each item gives the change, the file, and the expected effect. They're listed from the most to the least impact.

1. **The queen's screech hurts less.** `scripts/combat_state.gd`: `SCREECH_STRAIN` 15 → **8**, and `QUEEN_SCREECH_CHANCE` 0.2 → **0.15**. The screech is still felt, but it no longer decides the fight on its own.
2. **Breaking the gate steadies the party.** `scripts/main.gd` `_break_gates()`: every hero loses **15 strain** ("The gate splinters — courage rises"). This answers the climb in nerves across floor 4.

   With 1 and 2 together, the lab suggests Mara's chances move from about 45% to roughly 65–70%. Corin's barely change, so the climax stays hard but winnable for everyone.
3. **Each hero's opening weapon suits them.** The opening currently hands everyone the iron sword. Instead, **Mara takes a light companion's short sword** (light, 3–5, no Strength penalty) and **Alwen a light mace** (light, 2–4, +5% to hit). Corin keeps the iron sword. This narrows the hero gap at the source. Files: `data/gear/` (two new items), and `scripts/main.gd` where the opening's body event hands the weapon over.
4. **Recruits arrive with their role's plain weapon.** Wardens bring a wooden club, Brawlers a woodcutter's axe, Scouts a simple spear (reach). File: `scripts/recruits.gd`. This fits the free-kit-then-pay decision in #42, and lifts recruits above fists.
5. **The fire always offers someone for the front.** At least one Warden or Brawler among the three recruits. Files: `scripts/camp_state.gd` `_fill_fire()` and `scripts/recruits.gd`.
6. **Floor 3 gets a little meaner, as a warm-up for the fortress.** Add one more three-enemy group with a goblin archer or drummer to depth 3 in `ENCOUNTER_GROUPS` (`scripts/main.gd`). Or leave floors 1–3 gentle as onboarding and rely on 1–2 to soften the spike. **This needs the owner's taste.**
7. **The scouts' route is worth buying.** Price 40 → **25** (`CampState.ROUTE_PRICE`), or let it reach floor 3 once the gate is broken. Low priority.
8. **Level 4 before the queen?** Today it's impossible: 380 of the 440 XP needed is on offer. If the owner wants the climax at level 4, raise `FLOOR_XP_LIMIT[4]` 90 → **150** (`scripts/progression.gd`). Otherwise keep level 4 as an after-the-queen reward. **This is a design call.**

After any of these are applied, rerun the playtest to compare:

```
Godot --headless --path . --script tools/campaign_playtest.gd -- 30 45 report.json
Godot --headless --path . --script tools/queen_lab.gd
```

## Not covered

- The opening escape: covered separately by `tools/opening_playthrough.gd`.
- Panic bolting while walking, and the coin-flip screens. The rules are the same, but the bot doesn't see the screens.
- A human's judgement on events and Defend timing. The observed fresh-player campaign asked for in #119 is still needed alongside these numbers.
