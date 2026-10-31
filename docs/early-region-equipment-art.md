# Early-region equipment catalogue and art brief

Art requests: [#194 Cave & Mine](https://github.com/jonathanvarro/Depths/issues/194) · [#195 Goblin Territory](https://github.com/jonathanvarro/Depths/issues/195).

**Artwork available · 2026-10-31:** [Review the complete 22-design set](../art/concepts/early-equipment-v1/inspector.html).
Sixteen new drawings and six retained designs have individual candidate exports
and size/silhouette checks. [Source/reuse audit and mapping handoff](early-equipment-art-review.md).
Shape selection and explicit runtime reconciliation remain pending.

2026-10-31. Owner requested equipment tables and art tasks for Cave & Mine and Goblin Territory. Category direction is agreed; the specific names, appearance and role descriptions below are proposed bases for art review. No numeric stats or new item IDs are assigned. Coordinate with #192/#193 and Claude's current migration into data/equipment/.

## Cave & Mine — improvised tools and expedition equipment

| Proposed base | Family / slot | Design role | Distinct visual cue |
|---|---|---|---|
| Surveyor’s Shortsword | Blade / slash | Dependable cutting weapon | Short straight blade, plain iron guard, wrapped grip |
| Quarry Hammer | Blunt / impact | Impact option for hard targets | Compact rectangular iron head, thick timber handle |
| Shaft Spear | Reach melee | Back-row melee contribution | Long ash shaft, simple narrow iron point |
| Miner’s Sling | Ranged | Basic ammunition-based ranged option | Broad leather cradle, two clearly separated cords |
| Hazel Walking Staff | Staff / mage weapon concept | Mage equipment base; effects specified separately | Crooked hazel staff, plain bindings, no ornate crystal |
| Waxed Work Jerkin | Light body armour | Mobility-oriented armour | Sleeveless fitted waxed leather, thin shoulder straps |
| Quilted Work Coat | Medium body armour | Balanced protection and handling | Padded sleeves, broad quilt seams, reinforced elbows |
| Riveted Mining Coat | Heavy body armour | Protection with greater handling cost | Thick coat carrying broad iron reinforcement plates |
| Pit Shield | Back slot · combat | Rolls favour protection/survivability | Round timber shield, plain iron boss and rim |
| Survey Cape | Back slot · exploration | Rolls favour dodge and trap handling | Short hooded waxed cape, clear folded silhouette |
| Prospector’s Satchel | Back slot · capacity | Rolls favour carrying capacity | Low leather flap bag, broad strap, external tool loops |

Palette/materials: soot-dark iron, ash/hazel wood, weathered brown leather, muted ochre linen and waxed charcoal cloth. Practical reused work equipment; restrained and handmade.

## Goblin Territory — stolen military gear and crude specialisation

| Proposed base | Family / slot | Design role | Distinct visual cue |
|---|---|---|---|
| Notched Falchion | Blade / slash | Forceful cutting identity | Broad curved blade, asymmetric guard, coarse grip wrap |
| Gatebreaker Mace | Blunt / impact | Heavy impact identity | Short flanged iron head, thick reinforced haft |
| Garrison Spear | Reach melee | Back-row melee contribution | Long reinforced shaft, broad leaf-shaped point |
| Sentry’s Shortbow | Ranged | Specialised ammunition-based ranged option | Compact curved wood bow, visible string, cloth grip |
| Cinderwood Baton | Staff / mage weapon concept | Mage equipment base; effects specified separately | Short dark wood baton, one iron binding and charred tip |
| Raider’s Leather Vest | Light body armour | Mobility-oriented armour | Fitted asymmetrical leather vest, narrow overlapping panels |
| Riveted Guard Coat | Medium body armour | Balanced protection and handling | Padded coat with spaced riveted metal strips |
| Garrison Scale Coat | Heavy body armour | Protection with greater handling cost | Dense overlapping iron scales over a thick undercoat |
| Gate Guard’s Shield | Back slot · combat | Rolls favour protection/survivability | Tall plank shield, angular top, two broad iron ribs |
| Raider’s Mantle | Back slot · exploration | Rolls favour dodge and trap handling | Short hoodless dark mantle, split hem, restrained red lining |
| Quartermaster’s Pack | Back slot · capacity | Rolls favour carrying capacity | Tall canvas pack, visible timber frame, tied rolls |

Palette/materials: blackened iron, crude rivets, rough wood, scavenged leather and restrained oxblood cloth. Deliberate field modifications distinguish this from early mine equipment; avoid excessive spikes, gold or unapproved insignia.

## Shared art contract
- Each region has 11 proposed bases: three melee families, one ranged, one staff, three body-armour weights and three competing back-slot families. Names are working art/catalogue proposals, not new live item IDs or balanced stat assignments.
- The brief starts from ordinary base versions. Quality, growth and modifiers remain independent rolls. No requirement for 110 separate five-quality icons; propose economical, readable quality treatments after base silhouettes are selected.
- No item wear, condition meter, use-driven breakage or repair-upkeep imagery. Existing construction can look aged/repaired without implying deteriorating stats.
- Shields use the existing shared back/utility-slot choice; no second shield slot. Protection means survivability. Capes favour exploration/dodge/trap roll identity without promising trap immunity or replacing Scouts.
- Reach enables back-row melee contribution, not invulnerability to attacks from behind. Art does not implement damage weaknesses.
- Staff/ranged bases are visual proposals; don't invent spell effects, ammunition rules or class eligibility.
- Distinct heavy/medium/light silhouettes at inventory size, not merely different colours. Ordinary bases should remain legible without magic glows or rarity labels.
- Match the current Field kit materials and icon presentation. See docs/field-kit-art.md and docs/visual-refinement.md. Before drawing, audit existing items/source masters for reuse; don't overwrite approved art or silently rename data/equipment/bases.json entries.
- Concept/shape review first; production inventory icons after selection. Target current 128x128 RGBA format, at least 8px padding, hard alpha, <=64 colours. Review at actual current Field kit size plus 64/32px silhouette checks; compact64 is optional, not assumed required.
- No backgrounds, lettering, baked UI frames, rarity borders or unrequested faction/religious symbols in runtime icons. Preserve exact ImageGen prompts, input roles, source masters, registration/export data and a catalogue. Use true transparent backgrounds for isolated production icons.
- Compare native/enlarged/display-size, greyscale and dark/parchment backgrounds, then real Pack/merchant/loot rendering at desktop/landscape phone where integrated. Actual phone-device testing remains separate.
- No combat pose/portrait wardrobe assets, stats, prices, loot tables, save migration or runtime bindings changed by creating this brief.


Optional Spider Lair/prison drops and unique items are excluded from this first core batch. Armour-class eligibility and exact roll pools remain equipment-design work, not art decisions. Runtime mapping must explicitly reconcile working names with existing bases before binding.
