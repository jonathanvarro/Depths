# Combined Equipment and backpack · #51 / #48

2026-10-25. The approved physical kit is now the live Godot Pack screen.
[Review captures](../art/concepts/interface/combined-live-v1/inspector.html) ·
[In-game phone](../art/concepts/interface/combined-live-v1/main-1278-normal.png) ·
[Larger text](../art/concepts/interface/combined-live-v1/main-1278-larger.png)

Equipment opens on the left; the shared backpack stays on the right. Selecting
a party portrait changes the inspected hero and clears stale item actions.
Status replaces only the left panel and scrolls independently. Only current
party members appear, with one name each. Their registered PortraitView rigs,
conditions and existing blink system are reused; fallen heroes do not blink.

The loadout uses current Weapon, Armour, Back and Trinket slots, with quiet
empty-slot outlines on the approved canvas roll. The twelve stitched bag
compartments show item art and stack counts. Real capacity, stacks, backpacks
and limp penalties come from the existing model. Additional pages preserve
large targets; an over-full bag retains all items. The twelve visible cells
are a page size, not a new carrying limit.

Hover/focus previews an item. Click/touch pins it; explicit Equip, Wear, Use,
Take off or Drop performs the action. Inspection occupies a reserved lower
row instead of covering equipment or inventory. Gear comparison and replacement
identity come before longer descriptive text. The receiving slot highlights.
Escape dismisses inspection, then closes the kit; keyboard focus returns to
Close on reopening. Header settings, journal, gold, fuel and Save & exit remain.

Existing party methods handle swaps, back gear, trinkets, supplies and drops.
Weapon/armour removal uses the same guarded return-to-pack pattern as the old
weapon UI. Founders still replace their weapon rather than stow it bare-handed;
cursed worn items remain locked. Wearing a hidden cursed weapon announces its
curse. Item details name the actual automatic treatment target (for example the
most hurt hero); selecting a portrait does not silently retarget a draught.
Use costs remain visible. Browsing and gear swaps spend no time, and no explanatory
"browsing is free" copy occupies the interface.

## Art and source preservation

`art/ui/physical-kit-v1` contains byte-identical runtime copies of the approved
bag and roll from the v3 browser study, plus original native SVG empty-slot
outlines. [Catalogue and hashes](../art/ui/physical-kit-v1/catalog.json) link to
the retained [original built-in ImageGen prompts](../art/source/pack-heroes-v3/generation-manifest.json).
No new raster generation or repainting was needed for this interface. Earlier
browser studies are preserved; their isolated-only status describes the earlier
delivery, superseded by this live implementation.

## Verification and limits

- `tools/art/check_combined_pack.gd`: **321** passing checks and nineteen
  captures, using real PartyState/PackScreen and mouse/touch events without Main,
  saves or settings files. Desktop 1280×720, phone 1278×590 and SE 1334×750,
  at Normal/Larger scaling: simultaneous panels, fitting loadouts, targets of at
  least 44 UI pixels, comparison, Status, stale-action cancellation, swaps,
  actual supply targeting/cost, jewellery, curses, drops, pages and Escape.
- `tools/art/check_combined_pack_main.gd`: **68** passing assertions and four
  actual Main captures. Checks real party membership, safe areas, movement lock,
  refill rules and return to exploration, using a project-local fixture save.
- Existing back/trinket/gear/quality/boon/recruitment checks pass, as does the full
  opening playthrough (equipping, dropping, draught, relight, torch throw and camp).
  Their Pack selectors were updated for inspection-based actions; the recruitment
  comparison now uses the selected hero's actual damage range.

The isolated Pack and fog fixtures exit cleanly. Main teardown reports two
CanvasItem RIDs, 34 objects and 27 resources still held at shutdown, while the
older full-game harnesses also report shutdown leaks. These are recorded separately
from passing behaviour assertions; this work does not claim a leak-free full game.
Actual phone readability, thumb reach and device performance remain #66.
Concurrent combat, held-light, loot and balance changes belong to other work.
