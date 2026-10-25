# Equipment left, shared pack right · #109 refinement

**Live implementation · 2026-10-25:** this composition is now connected in
Godot, including current back gear/trinkets, real item permissions, capacity
and supply targeting. See [the live kit handoff](combined-kit-live.md).
The browser studies and their original validation below remain historical.

Owner direction, 2026-10-18: the player needs to see inventory and equipment together. Keep the approved physical backpack on the **right**, put equipment on the **left**, and combine them into one view. This supersedes v3's separate Pack/Equipment pages while retaining its leather/canvas art.

## Recommended view

A compact **portrait plus loadout** suits the current game better than a full-body equipment diagram. The left panel shows the selected hero, their weapon/body equipment and brief health/strain context. Portrait selectors sit beneath it. The shared backpack remains on the right throughout browsing, equipping, switching heroes and visiting Status. Equipment is the default left tab; Status replaces that panel only and can scroll independently for longer descriptions.

Selecting an item reveals a **reserved bottom inspection row**, so its description/action never covers either side. A carried weapon highlights the corresponding left slot and names the item it would replace. Click/touch pins details; explicit Equip confirms the swap, immediately returning the previous item to the visible bag. Hover/focus only inspects. Unequip also returns gear to the same bag. Switching heroes clears stale inspection details before a later action can target another person. No separate Pack/Heroes navigation button or duplicate spare-item strip is needed.

A full-body **paper doll** is an alternative if later equipment includes head, boots, hands and accessories. It would communicate placement spatially, but requires coordinated body art, more room and more supported slots. The current portrait/loadout view works with the existing Weapon/Body model and preserves space for readable bag icons. No new equipment categories, full-body artwork or gameplay rules are added by this review.

## Review files

- [Combined phone view](../art/concepts/interface/pack-heroes-v4/phone-combined.png)
- [Selected item and replacement](../art/concepts/interface/pack-heroes-v4/phone-compare.png)
- [Status with bag still visible](../art/concepts/interface/pack-heroes-v4/phone-status.png)
- [Compact landscape](../art/concepts/interface/pack-heroes-v4/compact-combined.png)
- [Interactive review](../art/concepts/interface/pack-heroes-v4/combined-kit.html) — open from a full repository checkout in a browser.

Editable [layout](../art/concepts/interface/pack-heroes-v4/layout.html) and [style](../art/concepts/interface/pack-heroes-v4/combined.css) remain separate from the generated page. `tools/art/build_combined_kit_study.py` reuses v3's interaction source/art and records provenance in [manifest.json](../art/concepts/interface/pack-heroes-v4/manifest.json). There is **no newly generated raster art**. The approved bag/roll masters and exact built-in ImageGen prompts remain in [v3's source manifest](../art/source/pack-heroes-v3/generation-manifest.json).

## Scope and verification

This remains an isolated visual/interaction study. The shipping Godot Pack is unchanged. Inventory, loadouts, health, strain and lantern values are fixtures; example companions are not approved starting party members. Using a sample ration only changes the demonstration stack. The twelve visible compartments do not set capacity, weight, stacking or backpack upgrades. Actual comparisons, supply targeting/time costs and combat/opening permissions must bind to the game model during live integration. Larger inventories need paging/scrolling without shrinking the touch targets. Physical-iPhone review remains #66; shared Godot styling remains #51.

The focused browser check (`tools/art/check_combined_kit_study.cjs`) passes **157 checks with twelve captures**, covering desktop 1280×720, phone 1278×590, SE 1334×750 and compact 736×590. It checks simultaneous panel visibility, left/right placement, minimum 44px enabled targets, viewport bounds, complete equipment fit, bottom-detail separation, persistent bag during Status/hero changes, mouse/touch inspection, replacement highlighting, swapping/unequipping into the bag, independent example loadouts, unavailable reasons, keyboard tabs and Escape/reopening. The report and captures are preserved beside the review and phone/compact views were visually inspected. No engine tests are needed for these browser-only files; no live-Godot or physical-device validation is claimed.
