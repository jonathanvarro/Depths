# Pack slots and the hero window

Owner direction, 2026-10-17 (#61): revise Pack into **image-only slots**, revealing descriptions on **hover or touch**. Put **Equipment and Status in the same hero window**, open it on Equipment by default, and use **hero portraits to switch the inspected person**. This supersedes the labelled-row layout of the [first Pack study](pack-screen-design.md).

An interactive review was supplied in the design chat. Its editable source, self-contained fragment, source-art/font manifest, captures and validation are in [pack-heroes-v2](../art/concepts/interface/pack-heroes-v2/README.md). This remains a browser design study; the live Godot Pack and hero cards are unchanged.

[Equipment](../art/concepts/interface/pack-heroes-v2/desktop-equipment.png) · [Status](../art/concepts/interface/pack-heroes-v2/desktop-status.png) · [Pack](../art/concepts/interface/pack-heroes-v2/desktop-pack.png) · [Item detail](../art/concepts/interface/pack-heroes-v2/desktop-item-detail.png)

## Pack

Use a quiet dark bag interior with clear item silhouettes. Slot contents have **no always-visible item name or description**. Small quantity badges remain on stackable supplies. Every occupied slot still has an accessible item name and quantity; icons are not a replacement for assistive labels.

Mouse hover or keyboard focus reveals a temporary description. Click, Enter or touch **pins** the details, with a clear close control and an explicit use/equip action. A first touch inspects; it does not consume the item. On small layouts the temporary hover card ignores pointer hits, so it cannot obstruct the very slot the player is trying to select. A pinned card accepts interaction and stays open while the pointer moves toward its action.

The description card shows item identity, effect/description, recipient or equipment role, known time cost, and the action or unavailable reason. It stays inside the visible window. Empty slots do not open a blank item card. Depleted supplies stay inspectable at ×0, with **None left** instead of an enabled action. Live integration should apply the existing `PartyState.cannot_use_reason()` and `use_item()` rules, including full lanterns, retained partial flasks, automatic draught targeting, gradual recovery, injuries, combat and opening restrictions.

The sample uses twelve visible inventory cells, reflowing to three columns in the narrow review. **Twelve cells is a layout example, not an agreed carrying limit**, and the blank spaces do not settle weight, stacking limits or backpack upgrades. A larger inventory needs paging, scrolling or an expandable layout during implementation, with the capacity rule decided separately. Equipment and supplies can coexist visually in the shared bag.

Lantern quantity/light/burn remain above the slots. Browsing stays free. No money, weight counter, new fear gauge or permanent extra HUD is introduced.

## Hero window and portrait selection

- Open a hero from their portrait on **Equipment**. Highlight the selected portrait and show their name and role next to the local Equipment/Status tabs.
- Select another portrait to inspect that specific hero. Keep the currently viewed tab while switching, so Status can be compared without reopening it each time.
- Selecting a portrait from the shared Pack opens that person's Equipment. Pack itself stays a shared inventory; selecting a hero does not silently turn it into a private bag.
- Closing and reopening the hero window defaults to Equipment. Status is a sibling tab, not a second modal or a separate portrait page.
- Back closes the window and restores its opener's focus. Escape closes pinned/temporary item details first; a later Escape closes the window. Preserve visible selection and avoid immediately reopening a dismissed hover card under a stationary pointer.
- All portrait, slot and tab interactions are available through normal keyboard focus. Left/right arrows switch between the two focused tabs. Touch does not require hover, drag-and-drop or double-tapping.

The Equipment composition pairs the existing head-and-shoulders portrait and brief health/strain context with a small equipment grid. The sample places Head, Body, Accessory, Main hand, Off hand and Feet in six labelled regions. **Those six equipment categories are a visual proposal**, not settled game rules. They do not decide two-handed weapons, rings, clothing layers, item restrictions or loadout statistics. The owner has requested the window, not a new full-body character-art system.

A short row of spare equipment from the shared Pack makes the frequent task accessible from Equipment. Click/touch a spare item, read its card, then explicitly equip it for the selected hero. The preview demonstrates replacement and returning unequipped items to the shared bag; no hidden item deletion or duplication. Actual equip costs, permissions, comparison numbers and combat availability belong to #48. Do not derive damage/armour bonuses from the source artwork.

Status groups existing information: health, strain and condition; base combat values; personality, vulnerability and motive. Mara's sample uses her current definition (14/20 health, strain 55/Shaken, fed, no lasting injuries, base attack 2–4, base accuracy 75%, initiative 10). Base values are labelled because strain affects performance. This does not settle the proposed attribute, outlook, relationship, fear-randomization or progression systems.

## Visual language and examples

Use the accepted Cinzel 600 headings and Source Sans 3 400/600 body/actions, dark Field kit surfaces, parchment text and amber selection/focus. Item art comes from the existing starter/Pack sets. Keep focus outlines distinct from selected fills, and keep colour paired with text or a border. Paper remains reserved for maps/documents.

Mara is the only defined hero. **Hero II and Hero III are clearly labelled example companions**, with neutral numeral portrait placeholders and unknown status values. They demonstrate switching and independent sample loadouts; they are not approved recruits, names, classes, portraits or statistics. The optional review control can show Mara alone. Live empty party slots must remain empty until recruitment exists.

The knife/coat on Mara and spare club/spear/staff/shield are **demonstration stock**, not a starting-equipment grant. The current game has no equipment inventory model. Source portraits still contain baked lighting; the independent lighting work remains #36. Equipping an item in this study does not change the portrait layers.

## Validation and integration boundary

The browser study was checked at 1024×720, 1278×590, 736×590 and 320×900. The landscape-phone composition reserves side/top/bottom space and fits the 590px study canvas. The narrow review stacks content for readability; it is not portrait gameplay. Current validation has **146 passing assertions**, covering viewport/window bounds, touch-target sizes, both bundled fonts, hover vs touch, pinned actions, stack depletion, unavailable treatment, portrait/tab selection, separate loadouts, equip/unequip, keyboard tabs, Back/Escape/focus and restoring local review state. Captures of all three screens and pinned details were reviewed. No physical-iPhone or Godot-integration claim is made.

Actions change **local demonstration state only**. Stack changes and equipment swaps make the design inspectable; healing, strain, clock, lantern simulation, real item permissions and game saves are not connected. In particular, the fixed lantern and Mara status are sample readouts, not results calculated from browser item-use clicks. The existing game remains authoritative. Use the old isolated Godot Pack preview if exercising actual supply rules is needed before live integration.

Implement the accepted design later through #48/#51, adapting the current `scripts/pack_screen.gd` and portrait input with real model data, existing safe-area scaling and input locks. Keep the opening's special restrictions and no-cost browsing. Check long names/descriptions, additional heroes, larger inventories, missing art and real iPhone readability before calling the interface complete.
