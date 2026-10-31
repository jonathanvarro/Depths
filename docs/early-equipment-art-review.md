# Early equipment artwork · #194 / #195

2026-10-31. [Review all 22 base designs](../art/concepts/early-equipment-v1/inspector.html)
for [Cave & Mine](../art/concepts/early-equipment-v1/cave-mine-dark-colour.png) and
[Goblin Territory](../art/concepts/early-equipment-v1/goblin-territory-dark-colour.png).
The [original brief](early-region-equipment-art.md) remains the design reference.

Both eleven-piece sets are complete as **shape-review candidates**: sixteen
new individual ImageGen drawings and six retained designs. The review includes
native 128px candidate exports, 64/32px checks, enlarged pixels, greyscale,
silhouettes, dark/parchment backgrounds and the existing bag's pocket proportions.
Owner selection is pending; no new design is recorded as approved, no production
item is replaced, and these working names do not assign live base IDs or rules.
The candidate exports remain under a `.gdignore` review folder, outside runtime
`art/items`. After selection, promote the selected art and explicitly reconcile
names/IDs with Claude's #192/#193 migration before binding it.

## Design direction

Mine equipment uses ordinary work materials: warm hazel/ash timber, brown
leather, ochre quilting and dull soot iron. Five weapon silhouettes distinguish
a straight blade, rectangular hammer, narrow spear, open sling and crooked staff.
Fitted sleeveless leather, a padded sleeved coat and a broad plate-reinforced
coat separate the armour weights. A round shield, short hooded cape and low
satchel separate the competing back-slot choices.

Goblin equipment uses blackened iron, coarse reinforcement and restrained
oxblood cloth. Its curved falchion, flanged mace, broad-point spear, stringed
shortbow and short charred baton remain ordinary bases. The armour progresses
from an asymmetric sleeveless vest to a strip-reinforced padded coat to dense
overlapping scales. A tall angular shield, split hoodless mantle and framed
canvas pack give the back-slot choices different outlines.

No quality glows, rarity borders, lettering, faction/religious marks or new
durability/repair imagery are baked into these icons. Quality, mastery, modifiers,
eligibility and numeric stats remain separate. Spears/bow strings are the finest
features at 32px; the gallery provides actual-size inspection rather than assuming
that enlarged artwork proves phone readability. Physical device review remains
separate (#66).

## Reuse audit

| Working design | Retained source/export | Reuse decision |
|---|---|---|
| Surveyor’s Shortsword | `story-slice-v1/companion-short-sword-master.png` and its 128px icon | Straight short blade already fits. Visual reuse does not make the founder-only item droppable. |
| Shaft Spear | `starter-v1/simple-spear.png`, `refined-v2/simple-spear.png` | Narrow ash-spear silhouette already fits. |
| Waxed Work Jerkin | First cell of `backlog96-v1/leather-armour.png`, `refined-v2/leather-jerkin.png` | Existing fitted sleeveless light silhouette retained; finish/name are still proposals. |
| Pit Shield | `starter-v1/wooden-shield.png` | Round timber/boss/rim master already fits; directly reduced for this review. |
| Prospector’s Satchel | `field-kit-v1/leather-satchel-master.png` and its 128px icon | Low flap bag and broad strap fit. The written brief's external tool loops are not prominent in this retained design. |
| Quartermaster’s Pack | `field-kit-v1/miners-frame-pack-master.png` and its 128px icon | Tall exposed timber frame already fits; reuse does not change the existing pack's region. |

All six sources stay in their original locations. Existing 128px exports retain
their visible RGBA pixels in the candidate copies; invisible RGB is zeroed only
in those copies. No approved source or live icon is overwritten. Existing prompt
provenance is linked from each catalogue entry. The old sleeveless padded-coat
icon, long oilcloth cloak and broad wool cape were considered but do not meet the
new sleeved-coat, short hooded-cape or split oxblood-mantle briefs. The old light
mace/cleaver/scales also do not supply the full new goblin silhouettes.

## Working names and stable IDs

These are **advisory comparisons**, not new assignments. Every catalogue entry's
`runtime_binding` is null. Full per-item reasons are in
[catalog.json](../art/concepts/early-equipment-v1/catalog.json).

| Working design | Closest existing ID to reconcile |
|---|---|
| Surveyor’s Shortsword | None assigned; companion sword source is visual reuse only |
| Quarry Hammer | None |
| Shaft Spear | `ash_spear` |
| Miner’s Sling | None |
| Hazel Walking Staff | None |
| Waxed Work Jerkin | `leather_jerkin` |
| Quilted Work Coat | `quilted_coat`; new sleeves |
| Riveted Mining Coat | None |
| Pit Shield | `buckler` |
| Survey Cape | `oilcloth_cloak`; new shorter silhouette |
| Prospector’s Satchel | `satchel` |
| Notched Falchion | `goblin_cleaver`; curved-blade proposal |
| Gatebreaker Mace | `light_mace`; weight/name difference |
| Garrison Spear | `boar_spear`; head/crossbar difference |
| Sentry’s Shortbow | None |
| Cinderwood Baton | None |
| Raider’s Leather Vest | None |
| Riveted Guard Coat | `studded_jerkin`; strips, sleeves and coat differ |
| Garrison Scale Coat | `goblin_scale`; new coat/sleeve coverage |
| Gate Guard’s Shield | `goblin_shield`; current name says round |
| Raider’s Mantle | `shadow_cape`; no magical effect implied |
| Quartermaster’s Pack | `frame_pack`; currently region 1 |

## Sources, export and verification

- Sixteen unmodified new masters and every exact built-in ImageGen prompt:
  [generation.json](../art/source/early-equipment-v1/generation.json). Input images
  were not supplied to these calls; material/style guidance is in their prompts.
  No fallback API/CLI was used. Original generated paths and SHA-256 hashes are
  retained. [brief.json](../art/source/early-equipment-v1/brief.json) holds all 22
  design/reuse/mapping records.
- `tools/art/build_early_equipment_review.py` uses the existing inventory
  `fitted()` exporter: direct-source crop, reduction, hard alpha and no-dither
  palette reduction. It does not draw or repaint objects. New exports are native
  128×128 RGBA, have at least 8px padding and at most 64 visible colours. Existing
  small exports are retained rather than enlarged into fake new masters.
- **222 export checks pass**: coverage, source/provenance, immutable generated
  masters, retained visible pixels, no upscaling, RGBA, padding, palette, alpha,
  clean transparent RGB, eleven designs and three armour/back families per region.
  The gallery/contact sheets are generated by the same command.
- `tools/art/check_early_equipment_review.cjs` checks every regional item selector,
  all size/background/treatment combinations, exact display sizes, image/master/
  handoff links, touch targets and horizontal fit at 1440×1000, 1278×590 and
  844×390. All **491 browser checks pass**; recorded results are beside the review.

No game scenes, equipment data, prices, stats, rolls, saves, drop tables or stock
bindings are changed. Actual Pack/merchant/loot renderer review follows selected
production bindings; the bag view here is an art-size preview. Concurrent gameplay
and equipment-model files remain owned by Claude and excluded from this art change.
