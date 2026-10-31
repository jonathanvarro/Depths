# Contextual Field kit · #191

2026-10-31. The live backpack now uses a portrait rail, a larger bag, and item
cards beside their source. [Review actual renderer captures](../art/concepts/interface/pack-context-v1/inspector.html).
This replaces the reserved inspection strip in the [earlier combined kit](combined-kit-live.md).
The approved bag, equipment roll, icons and portrait rigs are reused.

The selected portrait highlights on the far left. Its full name, role, health
and strain appear once above Equipment/Status; other names remain available
through portrait tooltips and accessibility names. Portraits have 64-pixel
targets and retain their own animation and condition layers. The bag uses the
space released by the old description strip; tighter framing favours its twelve
stitched compartments. Capacity, stacks, extra pages and overflow remain real.

Hover or keyboard focus previews a brief; a click or tap pins it. The card
contains the item title, actual comparison/recipient, description and actions
underneath. Long descriptions scroll while actions remain reachable. The card
stays inside the safe area, moves beside a pocket when there is insufficient
vertical room, and leaves its source reachable. It appears after placement
settles and stays hidden during drags. Click outside, the card's close icon or
Escape dismisses it. A second Escape closes the kit.

Actions use the supported item effects: Equip/Wear, Eat, Drink, Bandage, Refill,
Light, Apply, Take off and Drop. Unavailable actions are disabled with a reason
inside the brief; tools and ordinary treasure have no redundant Use button.
Potion throwing is not implemented, so it is not advertised as an available
action. Existing combat torch throwing remains in combat.

Drag a supply onto a portrait to use it for that hero, or onto the selected
hero's Equipment/Status area to use it for the selected hero. Gear can be
dropped onto a portrait/the hero area or its matching equipment slot; worn gear
can be dragged back into the bag. These extend Claude's gear-drag work in
`479112d`. Payloads identify their party and originating hero and are rechecked
against current inventory/membership on drop. Wrong slots, stale items, foreign
parties, cursed removals and founder weapon removal remain guarded.

## Recipient and model contract

`PartyState.cannot_use_reason(item, in_combat=false, recipient=null)` and
`use_item(item, in_combat=false, recipient=null)` accept an optional hero.
The Pack passes its selected hero for draughts, dressings and holy water; the
model rejects invalid, absent, full-health or otherwise ineligible recipients
without consuming an item or time. An unconscious main hero can still receive
a draught. Failed treatment never silently moves to another hero.

Calls that omit the recipient keep their existing automatic targeting,
including combat callers. Rations still feed the whole party, and oil/torches
affect shared light. Costs, healing over time, medical bonuses, curses and
inventory swaps continue through existing PartyState methods. The draught's
description now says it heals one hero rather than promising an automatic
most-hurt target in every screen. No new save state is required.

`KitBag.pocket_focus` is opt-in for Pack. Chest and merchant retain their
original bag framing and exchange interface. This task does not alter them.

## Verification

- `tools/check_pack_context.gd`: 582 headless checks; 601 with nineteen actual
  D3D12 Mobile captures. Desktop 1280×720 and landscape 1278×590, 1334×750,
  844×390, all at Normal and Larger interface sizes. Checks full viewport and
  safe-area bounds, 44-pixel targets, source/duplicate-stack reachability, long text, explicit
  and legacy recipients, real mouse/touch actions and drag gestures, disabled
  treatment, stale actions/payloads and equipment returns. No player files.
- `tools/art/check_combined_pack.gd`: 326 checks for swaps, comparison, Status,
  costs, selected targeting, jewellery, curses, paging, drops, focus and Escape.
- `tools/art/check_combined_pack_main.gd`: 64 actual Main integration checks,
  private project-local fixture save, movement lock and supply use preserved.
- Existing chest/merchant fixture: 293 checks, with captures redirected to
  ignored build output and skipped in headless mode. Shared bag behaviour stays
  unchanged. Back-slot, trinket and drag-policy checks pass.

The isolated context/Pack/exchange fixtures exit cleanly. Main and older
Main-based checks retain their previously documented shutdown resource warnings;
these are separate from behavior assertions. The captured phone shapes simulate
safe areas and do not establish physical iPhone thumb reach/performance (#66).

Run the new fixture headless with `--script tools/check_pack_context.gd`; use a
renderer and `-- res://art/concepts/interface/pack-context-v1/` to refresh the
review. Capture launches should remain hidden and off-screen. Earlier captures
and their original prompts are preserved.
