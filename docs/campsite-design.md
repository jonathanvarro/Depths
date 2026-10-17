# Cave campsite — interaction and layout concept

Design study recorded 2026-10-16 for #22. This specifies a proposed refuge screen; it does not implement the campsite or advance gameplay work past the current milestone.

## Owner's direction

The cave's refuge is a campsite with several little tents or activity areas. Areas can be highlighted and clicked/tapped to take the player into their respective views. Retain this spatial presentation as the camp's main navigation.

The owner subsequently specified a greedy recurring merchant who follows the party between rest locations and becomes increasingly obese and gross. He occupies the existing supply awning; see [the merchant design](merchant-design.md) and [revised progression concept](../art/concepts/merchant/merchant-progression-v2.png). The character design is approved, starting with the original middle figure's build, less gold/jewellery and increasing wealth location by location. Name, trading rules and precise stage mapping remain open.

## Proposed composition

### Cave-area staff and starter equipment — owner decisions (#24)

The cave camp needs a blacksmith sent from a nearby village and a nurse. The smith is an **apprentice**: his limited experience explains why so few quality items are available. This is the starting location, so keep equipment **very basic**, with a small selection and little high-quality stock.

Possible starter items include a plain knife, simple spear, woodcutter's axe or rough wooden shield. These are illustrative candidates, not an approved inventory or new equipment-type requirements. Equipment should be usable and plain; an apprentice does not imply randomly defective items. Exact categories, armour, quantities, prices and any exceptional quality item remain undecided.

Proposed presentation: a modest smith lean-to with an anvil, tools and portable forge, positioned between the merchant and party tent with clearance around hot work. The nurse occupies the existing Treatment tent. This adds a sixth clickable destination to the original five-area layout; recompose positions and hit areas together before implementation. Names, appearances and personalities remain proposals. Both staff are established for the cave; following the party onward is not established as it is for the merchant.

Suggested roles: merchant for provisions/trade goods, apprentice for basic equipment, nurse for treatment. Limited repairs/fitting are possible smith services, but durability, repair costs, crafting and upgrades are not decided or implemented. Nurse treatment follows the existing delayed-recovery direction; exact supplies, costs, timing and limits remain open.

### Clearing layout proposal

A single fixed landscape view looks into a sheltered clearing at dusk. The central fire provides the warmest light. Patched canvas, bedrolls, crates and a treatment cot make it a small expedition camp. A rocky escarpment and dark trees frame the clearing; the cave path remains visible at the back right.

Use simple pixel environments and clear silhouettes, with detailed companion portraits inside activity views. No walking avatar or free camera is required. Reuse the same clearing on each visit so returning feels familiar. Later art can show party condition and discoveries without moving the navigation targets.

```text
                  ROCK FACE / TREES
       Merchant awning    Nurse's tent        Cave path
          Smith lean-to
                 Small background shelter
             Paths into the clearing
       Your tent          Campfire
                  FOREGROUND BRUSH
```

Suggested positions are proportional to the scene, excluding interface chrome. They describe a composition, not mandatory collision rectangles. The background shelter remains decorative; the smith is the new sixth service. The coordinates below predate a full layout pass with the smith and must be recomposed to preserve separate touch targets.

| Area | Approximate centre (x, y) | Visual cue | Proposed destination and choices |
| --- | --- | --- | --- |
| Merchant (supply awning) | 19%, 44% | Open awning, recurring merchant, counter, coin scales and provisions | Meet the merchant; trade and review carried supplies. Exact buying/selling rules, prices, stock and a persistent stash are undecided. |
| Smith | To be placed between merchant and party tent | Apprentice, anvil, tools, portable forge beneath a lean-to | Basic equipment; possible repairs/fitting. Exact stock and mechanics remain open. |
| Treatment / nurse | 61%, 43% | Nurse, pale canvas, hanging cloth, low cot | Select a companion, inspect injuries and arrange treatment. Costs and recovery rules remain open. |
| Your tent | 21%, 78% | Broad low tent and bedrolls | Review party condition and equipment; arrange a rest. Show expected recovery, duration and supplies before confirming. |
| Campfire | 48%, 71% | Fire ring, kettle, seats, companions | Speak to companions and review discoveries. Dialogue, journal and relationship effects are proposals. |
| Cave path | 87%, 37% | Dark opening and final route lantern | Review the party and carried supplies, then deliberately confirm entry into the cave. |

These are six destinations in the revised design, not six fully specified simulation systems. The apprentice's modest forge is part of his area; a separate crafting station, inn, recruitment hall and town economy are outside this concept. Service views can start modestly without full crafting, shop or healer simulations.

## Interaction

- Keep short area names visible, with sufficient contrast against the scene. Distinguish a destination from decorative tents through both its label and highlight.
- Mouse: hover highlights the relevant tent/area silhouette and its label; a single click opens it. The hit area includes the tent front and its label, not only a small object inside it.
- Touch: a single tap gives highlight feedback and opens the destination. Do not require hover or a first tap just to reveal a label. Use non-overlapping targets at least about 44 logical pixels across.
- Keyboard: native focus order moves through the destinations; focus produces the same highlight as hover. Enter/Space opens the focused destination. A visible Back to clearing action and Escape return from an activity.
- Opening an activity replaces camp navigation with a close view, a companion/provider portrait when appropriate, and a compact set of choices. Keep only one activity active. Restore focus to the originating area on return.
- Opening, inspecting or leaving a view does not consume supplies or advance time. Any action that consumes resources or advances time presents its effects and cost before confirmation. Exact costs remain design decisions.
- On a landscape phone, preserve safe areas and readable text; scale/recompose scenery before shrinking text or targets. Closely spaced scenery can share less screen area while labelled targets remain distinct. The in-chat concept also offers a two-column area list at narrow portrait widths solely to keep the review usable.
- Highlights should be a restrained warm outline or local light change. Avoid continuous flashing. Optional smoke, flame and cloth animation should remain subtle, with reduced-motion support when added.

## Arrival, recovery and departure

Proposed flow: return through floor 1's way up -> review the expedition's gains and losses -> campsite clearing -> choose activities -> prepare at the cave path -> explicitly confirm descent. The results step should integrate with #17 rather than duplicate it.

Arriving at camp does not automatically clear injuries or refill supplies. Food and treatment follow the existing delayed recovery direction in DESIGN.md (#10/#11). Rest should be one clear commitment with visible effects, rather than requiring repeated clicks to process each companion. The exact time model, rest duration, pricing, recovery limits and persistence are unresolved.

The current floor-1 exit only says back to camp. Wiring it to a real refuge, preserving party/inventory state, deciding cave re-entry and revisits, and save/load all belong to later implementation. Do not assume the prototype's in-memory floor cache defines the final expedition rules.

## First implementation boundary

When refuge implementation is scheduled, begin with the clearing and six labelled destinations, a reusable activity view with Back, and a deliberate cave-entry prompt. Introduce functional services only when their party, injury and inventory dependencies exist; make unavailable services explicit instead of pretending they work. Reuse the preparation flow from #18 where appropriate.

Represent destinations with stable IDs (`rest`, `supplies`, `smith`, `treatment`, `fire`, `cave`), normalized scene positions, labels and a destination action. Keep these separate from resource/party logic. In Godot, this can be a Control scene with scenery behind accessible buttons and one shared activity container. The precise scene structure remains an implementation choice.

Before integrating: review the composition with the owner; resolve required rest/treatment/re-entry rules; then check all destinations with mouse, keyboard and simulated touch at a landscape phone resolution. Check safe areas, focus return, readable labels, non-overlapping targets and explicit confirmation of consequential actions.

## Review concept

The original in-chat interactive study illustrates the five-area clearing, highlights, destination views and Back interaction, before the apprentice smith was added. It has not been updated to the six-destination proposal. Its scenery is a procedural pixel layout study, not final campsite art. Action buttons explain proposed flows; they do not simulate a working economy, recovery system or dungeon transition. The persistent specification is this document.
