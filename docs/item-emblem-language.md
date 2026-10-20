# Reusable item marks

The coin and signet artwork already suggests a shared angular, branching seal. Use that family to connect selected manufactured valuables and the small currency indicator. Keep the different materials, silhouettes and wear that make individual finds recognisable.

## Evidence and interpretation

These observations come from viewing the full original masters and the actual 64/40px treasure review, rather than inferring a symbol from filenames:

| Existing artwork | Visible design | Decision |
| --- | --- | --- |
| [Three coins](../art/source/treasure-v1/coins-small.png), [heap](../art/source/treasure-v1/coins-heap.png) | Hammered discs with shallow angular stems, branches and loops; marks vary between coins | Keep the worn mint language. The exact generated engravings are not an established identical logo. |
| [Signet](../art/source/treasure-v1/gold-signet-ring.png) | Deep-cut branching mark on a flat, roughly octagonal seal face | Strongest jewellery reference for a reproducible seal. |
| [Silver ingot](../art/source/treasure-extra-v1/silver-ingot.png) | A small punched circular stamp on a broad cast face | Preserve its small scale; do not describe the unreadable stamp as a proven match. |
| [Locket](../art/source/treasure-extra-v1/silver-locket.png), [brooch](../art/source/treasure-v1/silver-brooch.png) | Curved leaf sprig and a leaf-shaped pin | Retain this softer personal ornament rather than replacing every decoration with the seal. |
| [Military medal](../art/source/treasure-extra-v1/military-medal.png) | Broad radial sunburst and faded crimson ribbon | Keep its distinct badge. No unit, deity or named order is established. |
| [Coin-flip faces](../art/source/backlog96-v1/coin-faces.png) | Explicit crown and skull | Preserve these existing outcome faces; the currency mark does not change their meaning. |

The [original treasure prompts](../art/source/treasure-v1/generation-manifest.json) requested worn unreadable stamps, not a named crest. The [additional valuables guide](treasure-extra-art.md) likewise assigns no faction or religious meaning. **“Forked seal” is an art-production label**, not new in-world lore, a quest symbol or a gameplay property.

## Canonical drawing

- [Forked seal, editable SVG](../art/symbols/crest-v1/forked-seal.svg): 64×64, transparent, one colour. Upright stem, one short upper-left fork, angular upper-right loop and two lower branches. This is a deliberately regularised companion derived from the existing shapes, not an exact tracing or a retroactive claim that every old coin matches it.
- [Small currency coin](../art/symbols/crest-v1/currency-coin.svg): native 20×20, irregular hammered edge and a reduced version of the same stem and branches. Use beside the actual amount, without also spelling out “gold” or adding a second purse total in the same panel. It remains a gold/currency indicator, not a denomination or a rarity badge.
- [Single-colour impression](../art/symbols/crest-v1/seal-impression.svg): native 64×64, uneven enclosing ring and the same canonical seal. A flat production guide for a wax impression, cargo stamp or textile label; it is not a new treasure item.

The full mark occupies x=9…51 and y=8…57 on its 64px canvas. Preserve the upright stem and the two alternating side levels; the upper-right and lower-left cuts distinguish it from a generic tree. Do not mirror the canonical mark casually. A physically impressed negative may be mirrored only when both the signet and its impression are intentionally shown together.

At small sizes use the reduced currency drawing rather than scaling every fine loop into noise. Keep the 20px currency canvas at least 16px on screen; the currency silhouette carries recognition at that size, while the stamp becomes a quiet material detail. Item-slot targets still need at least 44px; a small glyph is not the button target.

| Application | Proportions and treatment |
| --- | --- |
| Coin stamp | Seal height about 50–60% of the face diameter, inside an uneven raised rim. Some worn coins may lose an entire branch; do not fill a heap with equally sharp identical logos. |
| Signet / jewellery | Seal height about 65–75% of the flat seal face. Deep, dark incisions and one rubbed edge; retain the ring's broad gold shoulders and finger opening. Use on signets or an appropriate flat clasp, not every pendant. |
| Ingot punch | Small recessed mark, at most 15–20% of the long face. It must remain subordinate to the cast bar silhouette. |
| Crate / trade-cloth seal | A single subdued impression about 15–25% of one visible panel; align to the surface. Keep cord knots, wax edge or fabric weave more visible than fine seal detail. Use only where an existing cargo/seal surface supports it. |
| UI currency | One 20px coin beside the number, no glow, extra crest frame, repetition or floating text label. Muted gold differentiates currency from silver items and the red warning/cross palette. |

Do not stamp raw ore, nuggets, loose gems, food, a rough club or all recovered possessions. The medal's sunburst, locket's leaf and gems' colour/cut should continue to provide variety. Applying one symbol everywhere would erase the desired distinctions.

## Item identity and interface review

Descriptions should give one concrete construction or wear detail, then any necessary use information. Leave computed damage, armour, price and duration to their interface fields. Avoid invented provenance, rarity, healing claims, faction names and hidden item effects. “A deep-cut branching seal survives on the flattened face” fits the signet; “the king's sacred signet” adds unsupported story.

The existing runtime Pack repeats each hero's name in condition, strain explanation, injury, wielded gear, each gear comparison and each Equip button. One selected-hero heading and portrait can supply that subject; concise condition icons, weapon/body slots and one contextual Equip action can carry the rest. Retain a name where choosing between patients or equip recipients would otherwise be ambiguous.

The combined browser study also repeats the hero name in both the heading and portrait selector, and repeatedly displays “Browsing costs no time.” Keep the heading, use the selected portrait state for the selector, and remove that idle reminder. Preserve actual action costs, replacement previews and unavailable-action reasons. Camp likewise need not show both its purse total and a second “Your purse” paragraph, or repeat the same patient's name twice within a single treatment sentence.

The SVGs are authored native vector companions. Original generated masters, current treasure silhouettes and coin-flip faces are preserved. They introduce no economy, inventory, arrival, faction or quest rules.
