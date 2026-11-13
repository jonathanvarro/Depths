# Balance report: full-campaign bot (11 November 2026)

*Supporting data for #119, on the build after the Goblin King moved to the
board (#257) and the armour/shield mastery change (#219). The October report
is `balance-report-2026-10.md`. A bot can't say what a player understands:
for that, use `playtest-observation-sheet.md`.*

**How:** `tools/campaign_playtest.gd -- 10 60`: 10 campaigns per starting
hero, from camp after the opening until the King is dead (up to 60 days).
Same rules as the game, nothing drawn; 30 campaigns in 103 s. No stuck runs.

## Results

| | Mara | Corin | Alwen |
|---|---|---|---|
| King beaten within 60 days | 6 / 10 | **10 / 10** | 9 / 10 |
| Days to win (median) | 24 | 13 | 22 |
| Wipes per campaign (most on floor 4) | 2.7 | 1.2 | 0.9 |
| King fights won per attempt | 6 / 25 | 10 / 19 | 9 / 17 |
| Reach floor 4 (median day, party level) | day 4, level 4 | day 4, level 4 | day 4, level 4 |
| Health lost per visit, floors 1 / 2 / 3 / 4 | 1 / 7 / 8 / **43** | 3 / 8 / 9 / **46** | 2 / 7 / 6 / **31** |
| Trips ended for want of light | 32 | 8 | 22 |
| Steps with the light out | 22% | 16% | 21% |

## What stands out

1. **Floor 4 is still a cliff.** Floors 1–3 cost single-digit health a
   visit; the fortress costs 30–46. October's report said the same.
2. **Parties are at the level cap (4) by day 4.** Every hero reaches floor 4
   on day 4 at level 4, so the last three-quarters of a long campaign earns
   nothing. Losing campaigns just repeat floor 4 until day 60.
3. **Mara's runs are the weak ones:** 4 of 10 never beat the King, with the
   most wipes and the most trips cut short by darkness (32 per campaign).
4. **Light ends more trips than anything else.** About a fifth of all steps
   are taken with the light out.
5. **Banes never happen** (0.0 gained per campaign): the bot avoids risky
   shrine choices, so #133's curses go untested here.
6. **Report gap:** "floor XP used up by day" reads "0 runs" for every floor;
   that measurement in the bot is broken, not the game.

## Not covered

What players understand, camp as relief, companions they care about, touch
and iPhone (#66): all need the observed session in #119.
