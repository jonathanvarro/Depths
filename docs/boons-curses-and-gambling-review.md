# Boons, curses and gambling — review and recommendations

2026-10-21 · [Review #134](https://github.com/jonathanvarro/Depths/issues/134) · [Shrines #133](https://github.com/jonathanvarro/Depths/issues/133) · [Coin #77](https://github.com/jonathanvarro/Depths/issues/77) · [Trinkets #135](https://github.com/jonathanvarro/Depths/issues/135).

## Verdict

**The game captures the ingredients of the original idea, but the choices do not consistently fulfil it yet.** The current system connects offerings, pack space, temporary advantages, lasting penalties, preparation and retreat. Blood of the deep is a particularly good foundation: the same effect grants power and weakens healing, so the player must live with a bargain rather than just win or lose a roll.

The weaker pattern is **bring the counter-item and take a safe reward, or gamble blind for a small reward and potentially leave**. That creates preparation decisions, which are valuable, but often gives a knowledgeable player a repeatable answer instead of a new dilemma. The goal should be circumstances in which an informed player can reasonably accept, prepare differently or walk away.

Keep all three forms: a modest paid favour, a known benefit with a known burden, and an occasional high-stakes gamble. More randomness alone will not make them more interesting.

## Scope and evidence

This reviews the committed shrine system through `7560c71`, its four new events, eleven effect definitions, the older rigged strongbox and preparation events, combat coin integration, camp cures, saving and player-facing information. During the review, separate work on #135 appeared in the shared working tree. The trinket brief and its direction are assessed below; its unfinished integration and balance are not certified by this review. Those changes were left untouched.

The [research probe](../tools/boon_tradeoff_review.gd) runs the real event and effect rules, measures lantern endurance, samples 10,000 seeded weighted outcomes, and drives an actual event-screen choice through its Continue button. [Recorded observations](boons-curses-review-data.json) include runtime source hashes because #135 was changing shared files. Nineteen observations passed; these document the audited behaviour, including undesirable behaviour, rather than define new design requirements. They are not nineteen assertions that the design is good.

The existing `tools/boons_check.gd` also completed its 37 checks with `fails=0`, using a project-local test-save fixture. Its headless shutdown still reported one CanvasItem RID, twelve ObjectDB instances and five resources in use. The focused research probe exited with clean final logs after explicitly releasing its short-lived chest audio. No whole-campaign simulation or physical iPhone playtest was performed for this review. No shipping gameplay, data or balance was changed.

## What actually exists

Seven definitions are classed as boons, including one mixed bargain; four are classed as banes. A three-fight effect survives a return to camp. An until-camp effect disappears on return, without a night's rest. Reapplying the same definition refreshes its duration rather than adding another copy; different definitions can combine.

| Effect | Actual effect | Duration | Design assessment |
| --- | --- | --- | --- |
| Miners' luck | +8 percentage points to hit | 3 fights | Useful paid favour; value depends on weapon, light and hit-chance cap |
| Blessed | +1 damage | 3 fights | Clear, useful preparation for an approaching fight |
| Blood of the deep | +2 damage; newly scheduled healing is halved | 3 fights | Strongest existing example of power with a cost |
| Quiet heart | Positive strain gains multiplied by 0.5 | Until camp | Connects the shrine to expedition endurance |
| Lamp blessing | Lantern oil burn multiplied by 0.75 while bearer is alive | Until camp | Relevant effect; current full-flask price is often unattractive |
| Deep eyes | Party sees traps | Until camp | Useful without Mara; duplicates her existing Keen eyes benefit |
| Hearty | Newly scheduled healing multiplied by 1.5 | Until camp | Relevant to healing supplies and willingness to continue |
| Withering | −4 maximum health; current health is clamped if necessary | 3 fights | Meaningful persistent cost, especially on the lead hero |
| Shaking hands | −8 percentage points to hit; −1 damage | 3 fights | Compounds an expedition's combat costs |
| Sickness | New healing ×0.5; positive strain gains ×1.5 | Until camp | Potential retreat trigger; not just a small HP penalty |
| Marked | Doubles the weights of eligible ambush outcomes | Until camp | Relevant threat, but current “twice as often” description overstates the normalized probability |

Single-target outcomes currently affect the **first living party member**, without an actor-selection step. Whole-party outcomes affect all living members. Holy water removes one recognized bane from the first eligible living hero; the nurse charges 20 gold for one bane. Blood of the deep is not classified as a bane, so cleansing cannot remove its healing drawback while retaining its damage. Preserve that useful integrity when adding more mixed bargains.

Sources: [Boon definitions](../data/boons), [effect rules](../scripts/companion.gd), [party rules](../scripts/party_state.gd), [event resolver](../scripts/room_events.gd), [camp cures](../scripts/camp_state.gd).

### Current shrine choices and actual chances

These chances come from normalized resource weights. They are not all shown to the player and are not all affected by Luck.

| Event / choice | Cost and actual result | Tradeoff quality |
| --- | --- | --- |
| Miners' shrine: ration | One ration, 1 time → Miners' luck on lead | A real food-versus-combat choice, stronger near difficult fights |
| Miners' shrine: gold | 10 gold, 1 time → Quiet heart on lead | Money versus expedition endurance |
| Miners' shrine: oil | One full 100-oil flask, 1 time → Lamp blessing | Often gives up more remaining range than it buys |
| Miners' shrine: pray | 2 time → 40% −10 strain, 20% Deep eyes, 40% nothing | Small time gamble; trap reward can be redundant for Mara |
| Defiled shrine: study | 2 time → narrative clue suggesting roughly equal outcomes | Some information, but benefit, downside and duration remain unspecified |
| Defiled shrine: holy water | One holy water, 1 time → everyone Blessed | Clear preparation reward; water also has a field-cleansing use |
| Defiled shrine: smash | Reusable pick, 2 time → 2/3 everyone −6 strain; 1/3 lead Marked | Some risk, but the bad outcome does not offer a different play plan |
| Defiled shrine: touch | 1 time → 50% Blood of the deep; 50% Withering | Closest to the intended dark gamble; insufficiently disclosed before commitment |
| Fouled well: antidote | One antidote, 1 time → everyone schedules 8 healing, then gains Hearty | Good inventory opportunity cost: save the antidote for venom, or use it here |
| Fouled well: drink anyway | 1 time → 1/3 lead schedules 4 healing; 2/3 lead loses 2 HP and gains Sickness | Modest successful reward against a severe expedition cost; likely an emergency-only gamble |
| Buried cache: spade | Reusable spade, 3 time → 8 gold and 2 valuables | Good packing reward; once prepared, a fairly straightforward choice |
| Buried cache: pick | Reusable pick, 2 time → 1 valuable | Faster and less rewarding; text also promises ore, but the outcome currently grants none |
| Buried cache: hands | 4 time → 50% 1 valuable; 50% −3 HP and Shaking hands | Time plus a potentially long combat penalty; avoiding it is often sensible |

“Leave it” remains available before choosing. This is important: refusal is a valid outcome, not a design failure. The issue is when refusal becomes the routine answer in almost every ordinary state.

None of these four new events enables `coin_flip`. Their weighted choices bypass both the visible coin and its Luck adjustment. The older rigged strongbox does use the coin: normally 50% for 15 gold and a valuable versus −4 HP and +8 strain; the Lucky recruit strength can improve its heads chance. Combat killing blows also use the coin, with defending able to improve survival odds. This combat integration is a good existing example of doing something meaningful **before** the roll.

Sources: [miners' shrine](../data/events/object_miners_shrine.tres), [defiled shrine](../data/events/object_defiled_shrine.tres), [well](../data/events/object_fouled_well.tres), [cache](../data/events/chest_buried_cache.tres), [strongbox](../data/events/chest_strongbox.tres), [coin/event UI](../scripts/event_screen.gd), [combat odds](../scripts/combat_state.gd).

## Where the current choices fall short

### 1. Important information arrives after the decision

The touch button says “Touch the dark stone”; its initial clue says the stone feels warm. Study adds the fist/skull tally, but not +2 damage/half healing versus −4 maximum health, three-fight duration, or who bears it. Effect descriptions are mainly on condition-icon tooltips after acquisition. The result chip for Blood is marked positive, even though it is a mixed bargain.

Keep uncertainty about what a shrine means in the world. Give the player enough information about the **kind and scale of the stake** to take responsibility for the result. A paid study could reveal the exact pact, affected hero, duration and odds. Known encounters should retain learned information. At a rare lethal or lasting-injury gamble, disclose the stakes before the choice that commits the player, not only on the subsequent non-cancellable coin screen.

The 14px HUD icons and hover tooltips also need an accessible touch route: a tapped hero/status view showing benefit, burden, remaining duration and removal options. The current Pack condition list does not provide the full boon/bane explanation. This is a source-based interface gap; phone usability still needs a real-device check.

### 2. Costs and rewards sometimes make a branch unattractive for the wrong reason

The oil offering is the clearest numeric example. Using the actual variable-burn rule:

- A full normal lantern burns for **110 time units**.
- A full blessed lantern burns for **146 time units**.
- With one full lantern and one spare full flask, keeping/refilling yields **220 units**, compared with **146** after donating the flask.

This is an isolated fuel-endurance comparison, excluding offering/refill time, light's combat benefit, free oil discoveries and more carried flasks. It does not prove the blessing is never useful. It does show that sacrificing one's only refill is usually a poor endurance bargain. A partial measure or another modest payment would let the effect fulfil its purpose; simply making all boons stronger is unnecessary. A partial-oil payment needs a new cost option, because the current `requires` field consumes one whole item.

The bare well gamble similarly offers only four delayed HP on success against two immediate HP lost plus weakened healing and faster strain on failure. Consider a better upside, a small safe alternative, or an informative preparation choice. Do not try to force everyone to drink poisoned water by removing “Leave”.

### 3. Preparation sometimes eliminates the decision instead of changing it

Durable tools and pack limits are a good foundation. However, once a player can routinely carry all the useful counters, many encounters become recognition tests: see shrine, spend holy water; see cache, use spade. That is fine for some encounters, but insufficient as the main source of dilemmas.

Create competing uses for the same resource and vary the useful offer. One holy water might bless this shrine, lift an existing bane, or remain insurance for deeper exploration. Some prepared choices can trade reward size for time, noise or a different burden. Do not make every tool unexpectedly break or every safe option secretly harmful; preparation should still be dependable.

The older goblin stash already provides a good model: cutting its charm down sets a real flag and removes the ambush outcome. Keep that cause and effect. Study should sometimes teach a plan, not merely add flavour text.

### 4. There is little control over who accepts a bargain

Putting the same lead hero under every single-target shrine effect limits party decisions. Let the player choose the actor and preview that person's circumstances. The wounded front fighter may value a damage pact very differently from a back-row recruit. A party-wide fuel benefit borne by one nervous companion can create a genuine protection decision.

Make sacrifice deliberate. Avoid a system where assigning every burden to a disposable recruit becomes the universally best answer; test how the benefit behaves if the bearer falls or is left at camp. The current living-member checks already provide a sensible starting boundary.

### 5. Duration, cleansing and effect wording need precise contracts

- **Fight duration:** Main counts down effects after every completed combat result, including retreat. A player can potentially spend time/light repeatedly entering and fleeing a known encounter to wear off a three-fight curse. This is a source-confirmed possibility, not a measured best strategy. Define what counts: victories, meaningful encounters, or any fight end. Apply a coherent rule to both benefits and costs; do not secretly count wins for benefits and retreats for penalties.
- **Healing:** modifiers apply when a healing dose is scheduled, not continuously. The well schedules its own eight healing before granting Hearty, so that dose stays eight; a later eight-point dose becomes twelve. Healing queued before Blood is acquired remains unchanged. Camp rest directly restores health. Decide whether this is intended, then use accurate wording or change the application order. This is not evidence that all healing is broken.
- **Marked:** doubling weights gives `2p / (1 + p)`, not `2p`. A goblin-stash ambush rises from 25% to 40%; the seeded probe produced 4,019 ambushes in 10,000 marked rolls. “Ambush outcomes are more likely” is honest. Existing preparation can still rule them out completely.
- **Mixed bargains:** cleanse the whole pact if an exit is allowed, not just its cost. The current Blood behaviour already avoids that loophole. Separate bad-only effects can retain straightforward cures.
- **Redundant rewards:** Deep eyes adds no trap visibility when Mara already supplies it. Offer an alternative or acknowledge the duplication before payment, rather than pretending the party gained a new capability.

### 6. An event reward can be lost at the full-pack handoff

The resolver returns `no_room` for overflow. EventScreen replaces its result with only `left` and `ambush` when Continue is pressed. Main expects a `no_room` payload to open the swap view, so that view is not reached through this event-screen path. The focused probe reproduced this with a full pack and the spade cache.

This undermines the basic promise of a gamble: the advertised reward must actually be claimable. Fix the payload handoff and cover the full choice → Continue → Main flow. The older check calls the resolver and opens the overflow view manually, so its passing assertion does not cover this connection. Spare-gear overflow is a related separate path to review; the confirmed reproduction here concerns supply/treasure overflow.

Confirmed reward follow-ups are tracked separately: [#136, full-pack event handoff](https://github.com/jonathanvarro/Depths/issues/136) and [#137, promised cache ore missing from the loaded resource](https://github.com/jonathanvarro/Depths/issues/137). The shrine builder already requests that ore; investigate the builder/resource discrepancy rather than silently changing the promise.

## Research and what it suggests for Depths

Soren Johnson argues that visible probability helps players treat chance as something they can reason about, and warns against rare destructive surprises that cannot be learned fairly. For Depths, that supports clear stakes and learned shrine knowledge while preserving dangerous outcomes. It does not require revealing story secrets. [Playing the Odds, by Soren Johnson](https://www.gamedeveloper.com/game-platforms/analysis-soren-johnson-on-playing-the-odds).

David Talton distinguishes randomness that establishes the situation before a decision from randomness that resolves after it. My application to Depths: randomize which legible bargain a shrine offers, then let the player choose how to adapt; reserve some uncertainty for the actual gamble. A changing offer creates variety without making every interaction another opaque roll. [Level 99 design guidelines: input and output randomness](https://www.level99games.com/blogs/guidelines/3-5-1-3-5-2-input-output-randomness).

Supergiant's original Chaos announcement explicitly pairs powerful blessings with side effects. The transferable idea is a benefit whose attached burden changes how the player proceeds. Depths' own Blood effect already does this; expand from its structure rather than importing another game's full progression system. [Supergiant: The Chaos Update](https://www.supergiantgames.com/blog/hades-the-chaos-update-is-now-available/).

These sources motivate the recommendations; they do not validate proposed numbers or prove that a particular choice will be fun. The balance judgments above come from Depths' current costs, effects and state transitions.

## Recommended shape: three kinds of encounter

| Kind | What the player decides | Good use |
| --- | --- | --- |
| Paid favour | Is this modest benefit worth this supply or gold now? | A dependable miners' shrine, especially before a difficult branch |
| Binding bargain | Is this known power worth carrying this known burden? | A dark shrine that changes the next few fights or the remaining trip |
| Studied gamble | Given the stated outcomes and my preparations, is the chance worth taking? | A rarer, memorable coin moment with meaningful stakes |

Not every favour needs a curse. Not every curse needs a random roll. The important requirement is that the available alternatives depend on party condition, supplies, route and intention.

For gambling, retain the owner's #77 rule: the choice commits; the coin cannot be declined after that. Show odds and stakes **before that commitment**, then let the coin supply suspense. Promote a small number of suitable two-outcome events, such as the defiled stone, to this treatment. Do not animate every prayer, mining action and ordinary combat hit.

### Concrete examples to test

All new offers and numbers below are proposals; none are implemented by this review.

| Offer | Benefit and burden | Why the answer can change | Work required |
| --- | --- | --- | --- |
| **Blood of the deep**, disclosed | Existing +2 damage / half new healing for 3 fights, offered as a readable pact; a riskier variant can remain a separate gamble | Valuable before a short offensive push; dangerous for a hurt party relying on draughts | Existing effect; choice/preview and actor selection changes |
| **The Dread Lantern** | Slower oil burn, but the bearer gains strain faster until camp | Helps a fuel-poor party with one steady companion; worsens an already frightened party | Existing oil/strain fields; new mixed definition and offer |
| **A Measure for the Lamp** | Spend a small amount of oil for the existing fuel blessing, or retain fuel | Depends on expected remaining distance and other refill sources | New partial-resource cost; tune against real lantern range |
| **The Well's Mercy** | Antidote gives the dependable reward; a modest safe sip gives little; a deep drink offers a larger disclosed reward with a stated sickness risk | Changes with wounds, antidote stock and plans to continue | Existing outcome fields; revised choices/odds; tune rewards |
| **The Following Shadow** | Accept Marked knowingly in exchange for a guaranteed worthwhile find | Potentially acceptable on a surveyed return route; dangerous while exploring fresh event rooms | Existing Marked/reward fields; new offer and clear description |
| **One More Offering** | Bank a small find, or stake it on one further coin for a larger find and a disclosed penalty | Players compare secured gains with need, health and risk tolerance | New multi-stage event/escrow state; not just another static outcome |

Keep a first push-your-luck prototype to one extra decision. For example: bank 6 gold; or stake it for a 50% chance at 15, with a stated temporary bane and loss of the stake on tails. Those numbers are illustrative. Store the stage, committed stake and claimed reward so reopening, leaving, regeneration or saving cannot duplicate payment or reroll it for free. This needs deliberate event-state work, so it belongs after basic information and handoff fixes.

### The trinket direction already addresses an important gap

#135's owner-approved direction adds one trinket slot per hero, common benefit/drawback pairs, better tiers, playstyle rewards and cursed items. Its Bloodstone, light-sensitive brooch, back-row ring, torch enhancer, defending token and luck/ambush knucklebone already supply conditional choices. These are existing owner ideas, not new inventions of this report. Prefer finishing and testing that small set over adding a parallel collection of dozens of passive shrine percentages.

Two things to watch:

- Freely replacing common tradeoff items with rare two-benefit items can remove the tradeoffs later. Keep some common/unique effects useful for particular plans instead of making rarity alone decide every slot.
- Hidden curses are an explicit owner choice. Preserve that discovery, while making the category risk legible through provenance, suspicious clues or a proposed identification route. Exact curse identity can stay hidden. A permanently cleansed fine item may become a straightforward “pay 15 gold once” purchase, so measure that economy before making curses harsher or cleansing more expensive.

A slot is already a meaningful limit for trinkets. Do not add another arbitrary boon-cap system until stacking and player comprehension show a concrete need. Mixed shrine pacts should still keep both halves attached, regardless of trinket cleansing rules.

## What to do first

1. **Restore trust in outcomes:** preserve overflow payloads; reconcile promised ore, healing order and effect wording. Separate definite bugs from intentional rules needing clearer text.
2. **Improve the existing choices:** show actor, benefit, burden, duration and known odds before commitment; make details reachable by touch. Keep mysteries in the fiction.
3. **Tune two weak offers:** the full-flask price and bare well's reward. Keep useful prepared options and the right to leave.
4. **Test one explicit mixed pact and one rare visible shrine coin.** Preserve Blood's bundled cost, the established duration categories and #77's commitment rule.
5. **Finish and test #135, then consider one small push-your-luck event.** Avoid increasing content count before the current decisions are readable and worthwhile.

### How to tell whether the choices improved

The #133 issue records 30 campaigns per hero for a careful bot and a naive one. The careful bot avoided curse-bearing choices, carried counters and gained about two boons/no banes per campaign. Its wins were 23/30, 26/30 and 20/30, compared with the pre-feature baseline's 24/30, 29/30 and 21/30. These are existing measurements, not rerun here. They show that caution can remain viable; neither the policy nor the sample establishes whether informed gambling is attractive or whether overall difficulty is unchanged.

Use representative decision states: healthy before a hard fight, wounded and reliant on healing, low on oil far from safety, nearly home, and carrying either one counter-item or several. Record which options players choose **and why**, how often they regret a misunderstood rule, whether a boon changes their next few actions, and how often a bane is managed rather than prompting immediate retreat.

For automated comparisons, evaluate policies that actually consider mixed bargains, not only “always gamble” versus “avoid every bane.” Track choices offered, item availability, actor, known odds, selected branch, duration used, cure cost and subsequent outcomes. A healthy result is different decisions in different circumstances, not a mandatory 50/50 selection rate. Whole-campaign win rate is a guardrail; understandable, consequential decisions are the primary test.

## Handoff boundaries

Keep the owner's strong-fight/mild-trip duration distinction, rare coin moments, non-cancellable committed flips, meaningful pack preparation and recoverable temporary curses. The expanded cave proposal supplies good later homes for these ideas, but this review does not authorize twelve floors of new systems.

If changing generated shrine data, update `tools/story/build_shrines.gd` as well as its resources. Retain the committed audit as a dated record; once fixes land, update the observational probe/data or archive it rather than keeping assertions that require a known bug to survive. #133 remains open; #135 was in progress during this review. All follow-up gameplay and balance changes need their own focused implementation and validation.
