# Physical Pack and Equipment · #109

Owner direction, 2026-10-18: revisit the interfaces, specifically **visual style and a more physical backpack**. This extends #61's accepted icon-slot and tabbed hero-window design.

## New visual direction

The shared Pack is an opened, repaired leather travelling bag, with coarse olive canvas and shallow stitched compartments. Existing item illustrations sit inside the compartments, with quantity badges only. Empty cloth remains visible. Hover/focus reveals details; touch/click pins them and exposes an explicit action. The first touch never consumes an item.

Equipment uses a matching canvas maintenance roll beside the selected hero's portrait. The review shows **Weapon and Body**, which correspond to the game's current supported categories. No helmet, boots, accessory, shield slot or full-body character drawing is introduced. Spare equipment stays close below. Equipment remains the default; Status is its sibling tab, and the portrait rail changes the inspected hero while retaining the chosen tab. Selecting a portrait from Pack opens Equipment.

Both surfaces use neutral material shading. Existing Cinzel headings, Source Sans 3 text, parchment lettering, restrained amber selection and visible keyboard focus carry through. Item outlines remain separate from the textured cloth. Browsing remains free; use/equip is explicit.

## Review

- [Interactive browser study](../art/concepts/interface/pack-heroes-v3/pack-heroes.html) — open in a browser from a full repository checkout.
- [Phone Pack](../art/concepts/interface/pack-heroes-v3/phone-pack.png)
- [Phone Equipment](../art/concepts/interface/pack-heroes-v3/phone-equipment.png)
- [Pinned item details](../art/concepts/interface/pack-heroes-v3/phone-detail.png)
- [Phone Status](../art/concepts/interface/pack-heroes-v3/phone-status.png)

This is an isolated visual/interaction study. It does **not** replace the live Godot Pack. The knife/coat/spares, quantities, health, strain and fixed lantern readout are review fixtures, not starting grants or simulated outcomes. Hero II/III remain clearly marked example companions. Mara uses her current neutral portrait and Rogue role. The twelve compartments demonstrate placement; they do not establish inventory capacity, carry weight, stacking, upgrades or a physical item-size system. Production needs a scrolling/paged bag treatment for larger inventories and real model-driven comparisons/permissions.

The generated shells have richer cloth texture than the small item icons; these are review exports, not a new library-wide resolution/palette standard. If this direction is selected for live integration, reduce/palette-check it at the chosen runtime size, retain the phone-safe input requirements from #61, and bind actual items, equipment, light, costs and opening restrictions to the existing game model. Do not copy fixture numbers into game data. Physical-iPhone review remains #66; a shared Godot theme remains #51 and shield rules remain #48.

## Sources and verification

Built-in **ImageGen** created two separate empty surfaces. Untouched 1536×1024 RGBA masters and the exact two prompts/tool parameters are preserved in [art/source/pack-heroes-v3](../art/source/pack-heroes-v3/generation-manifest.json). No paid API fallback. The review exports are 768×512 nearest-neighbour reductions retaining original alpha. Existing project icons/fonts are referenced; no new item art or portrait paint was substituted.

`tools/art/build_physical_pack_study.py` combines the original #61 editable interaction source with [physical.css](../art/concepts/interface/pack-heroes-v3/physical.css), the current Mara portrait, updated role/trait and two supported equipment regions. [manifest.json](../art/concepts/interface/pack-heroes-v3/manifest.json) records source/export hashes and existing-art paths. The original v2 study remains untouched.

`tools/art/check_physical_pack_study.cjs` passes **117 checks with 16 captures**, across 1280×720, 1278×590, 1334×750 and 736×590. Checks cover visible bounds, minimum 44px targets, loaded artwork/fonts, mouse/touch inspection, no consumption on inspection, explicit demonstration use/equip/unequip, independent sample loadouts, portrait/tab behaviour, keyboard switching, Escape and reopening. No browser errors. Captures were visually reviewed, including phone Pack/Equipment/details, compact and Status. No physical-device or live Godot integration claim.
