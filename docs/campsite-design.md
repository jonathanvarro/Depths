# Cave campsite — interaction and layout concept

Design study recorded 2026-10-16 for #22. This specifies a proposed refuge screen; it does not implement the campsite or advance gameplay work past the current milestone.

## Owner's direction

The cave's refuge is a campsite with several little tents or activity areas. Areas can be highlighted and clicked/tapped to take the player into their respective views. Retain this spatial presentation as the camp's main navigation.

## Proposed composition

A single fixed landscape view looks into a sheltered clearing at dusk. The central fire provides the warmest light. Patched canvas, bedrolls, crates and a treatment cot make it a small expedition camp. A rocky escarpment and dark trees frame the clearing; the cave path remains visible at the back right.

Use simple pixel environments and clear silhouettes, with detailed companion portraits inside activity views. No walking avatar or free camera is required. Reuse the same clearing on each visit so returning feels familiar. Later art can show party condition and discoveries without moving the navigation targets.

```text
                  ROCK FACE / TREES
       Supply awning      Treatment tent      Cave path
                 Small background shelter
             Paths into the clearing
       Your tent          Campfire
                  FOREGROUND BRUSH
```

Suggested positions are proportional to the scene, excluding interface chrome. They describe a composition, not mandatory collision rectangles. The background shelter is decorative and is not a sixth service.

| Area | Approximate centre (x, y) | Visual cue | Proposed destination and choices |
| --- | --- | --- | --- |
| Supplies | 19%, 44% | Open awning, counter, crates, oil tins | Review provisions and equipment; pack for the next descent. Buying, selling, stock and a persistent stash are undecided. |
| Treatment | 61%, 43% | Pale canvas, hanging cloth, low cot | Select a companion, inspect injuries and arrange treatment. Exact service provider, costs and recovery rules remain open. |
| Your tent | 21%, 78% | Broad low tent and bedrolls | Review party condition and equipment; arrange a rest. Show expected recovery, duration and supplies before confirming. |
| Campfire | 48%, 71% | Fire ring, kettle, seats, companions | Speak to companions and review discoveries. Dialogue, journal and relationship effects are proposals. |
| Cave path | 87%, 37% | Dark opening and final route lantern | Review the party and carried supplies, then deliberately confirm entry into the cave. |

These are five destinations in the design, not five fully specified simulation systems. A separate forge, inn, recruitment hall, crafting station and town economy are outside this concept. Supplies and treatment can initially be modest activity views without a full shop or healer simulation.

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

When refuge implementation is scheduled, begin with the clearing and five labelled destinations, a reusable activity view with Back, and a deliberate cave-entry prompt. Introduce functional services only when their party, injury and inventory dependencies exist; make unavailable services explicit instead of pretending they work. Reuse the preparation flow from #18 where appropriate.

Represent destinations with stable IDs (`rest`, `supplies`, `treatment`, `fire`, `cave`), normalized scene positions, labels and a destination action. Keep these separate from resource/party logic. In Godot, this can be a Control scene with scenery behind accessible buttons and one shared activity container. The precise scene structure remains an implementation choice.

Before integrating: review the composition with the owner; resolve required rest/treatment/re-entry rules; then check all destinations with mouse, keyboard and simulated touch at a landscape phone resolution. Check safe areas, focus return, readable labels, non-overlapping targets and explicit confirmation of consequential actions.

## Review concept

The accompanying in-chat interactive study illustrates the clearing, highlights, destination views and Back interaction. Its scenery is a procedural pixel layout study, not final campsite art. Action buttons explain proposed flows; they do not simulate a working economy, recovery system or dungeon transition. The persistent specification is this document.
