# Loot and merchant Field kit · #155

2026-10-25. Chest loot, reward overflow and the merchant now share the live
Equipment/Pack visual language. [Review the actual Godot captures](../art/concepts/interface/exchange-live-v1/inspector.html).

Loot or shop stock lies on the canvas roll at the left; the real shared pack
stays visible in the physical backpack at the right. Icon slots carry quantities
or prices. Hover/focus previews; click/touch pins inspection in the reserved
lower panel. Take, Leave, Buy and Sell are separate actions. Gear inspection
includes base properties and quality; existing item descriptions are reused.
Escape clears inspection, then closes. Closing the merchant restores focus to
his campsite. Stock scrolls independently; bag pages retain large targets.

`scripts/kit_exchange.gd` owns the common presentation. `chest_screen.gd` retains
the public open/take/put_back/take_all/closed/took interface used by Main.
`merchant_screen.gd` calls existing CampState economy methods. Camp mounts the
merchant outside its scaled 640×360 landscape canvas, so safe areas and the
Normal/Larger setting operate in actual UI pixels as they do in the Pack.
The smith and other services retain their current screens.

## Existing rules preserved

- Real capacity, partial stacks, open oil, spare gear and overflow come from
  Supplies. Twelve visible bag compartments are a page, not a new capacity.
- Taking moves only what fits; the remainder stays. Leave follows the existing
  part-full-stack-first rule. Dragging and Take All remain available; invalid
  drag payloads cannot create an item. Repeated identical spare gear now retains
  its exact quantity on Leave and partial Take, repairing the old overwrite.
- Merchant stock, supply prices, treasure values, the 30% spare-gear resale and
  the 40-gold lantern upgrade remain CampState rules. Supplies stay visible in
  the bag but cannot be sold. Lantern oil waits for lantern ownership.
- The unloading caravan does not trade. Emergency torches still follow the
  existing once-per-day charity rules, including during unloading. An absent
  merchant closes his view. Stale purchase actions cannot outlive a refresh.
- Browsing and transfers do not advance expedition time. The opening chest and
  full-pack tips now describe inspection followed by an explicit action.

## Art and verification

No new raster art was generated. The approved bag and roll remain byte-identical
to their recorded sources in [physical-kit-v1/catalog.json](../art/ui/physical-kit-v1/catalog.json).
Original prompts remain in [pack-heroes-v3/generation-manifest.json](../art/source/pack-heroes-v3/generation-manifest.json).
The only added artwork is the original native SVG Take All glyph. Merchant
portrait, quality frames, currency seal and close glyph reuse current assets.

Godot 4.7.2, Mobile renderer, Windows AMD RX 9070 XT:

- `tools/art/check_kit_exchange.gd`: **310 checks**, seventeen captures, clean
  exit. Real models and mouse/touch/key input; native drag; explicit transfers,
  repeated gear, empty/full/partial states, stock/values, stale actions, lantern,
  charity and overflow pages. Desktop 1280×720, phone 1278×590 and SE 1334×750
  at Normal and Larger: visible targets at least 44 UI pixels, independent
  scrolling, both panels and inspection fit. [Recorded results](../art/concepts/interface/exchange-live-v1/validation.json).
- `tools/art/check_kit_exchange_main.gd`: **26 checks**, five actual Main
  captures: camp integration, safe areas, service availability transitions,
  sales, Escape/focus and full-pack reward handoff. Private save under ignored
  `build/exchange-review`; owner saves/settings were not used.
- Maintained gold, camp, small-items, boons, quality and full opening playthrough
  harnesses: **163 passing assertions**, zero failed assertions or runtime script
  errors. Inspection selectors replace old immediate-tap/text-price selectors;
  the existing gameplay expectations remain. [Run summary](../art/concepts/interface/exchange-live-v1/regressions.json).
- Headless editor import passes. Review captures are excluded from runtime by
  `.gdignore`. The two art fixtures can be rerun with `--path . --script
  res://tools/art/check_kit_exchange.gd` (or `check_kit_exchange_main.gd`), using
  the normal rendered executable, not headless capture.

Physical iPhone interaction/performance remains untested (#66). Main teardown
still reports 1 CanvasItem RID, 33 objects and 27 resources held; older full-game
harnesses also report shutdown leaks, as before this task. These are distinct
from passing behavior checks; a leak-free full game is not claimed. Concurrent
mini-boss/lair, combat and condition work is excluded from this change.
