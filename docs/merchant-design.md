# Recurring merchant — character and visual direction

Recorded 2026-10-16 for #23, following the campsite design (#22).

## Owner's direction

- There must be a greedy merchant who follows the party from rest location to rest location.
- His appearance must be distinctive and memorable.
- As the campaign progresses, he becomes increasingly obese and gross, fitting the dark environment.
- The owner approved the character design and chose the original concept's **middle figure as the starting build**. He begins already markedly obese, with less gold and jewellery; visible wealth increases **location by location**. Body size and grossness continue to escalate from that larger starting point.

This establishes a recurring character, an approved visual identity, a larger starting build and location-by-location wealth progression. His name, history, precise services, exact location-to-appearance mapping and any supernatural explanation are not decided.

## Proposed identity

**Working name: Master Tallow.** This is a naming proposal, not a confirmed character name.

A solicitous, calculating travelling provisioner who treats the party's survival as repeat business. He remembers what they bought and notices what they now need. His helpful manner makes every transaction feel faintly predatory. Keep him sharp and observant throughout his physical transformation.

Suggested dramatic contrast: the party returns battered while his clothes become more expensive, his table more lavish and his personal habits more repellent. This suggests that he benefits from their expeditions; it does not establish a literal mechanic in which every purchase increases his body size.

## Recognizable visual anchors

Keep the approved character's crooked dark-red cap with its pinned brass coin, thin forked moustache, conspicuous gold tooth and calculating smile. A ledger and tarnished coin scales establish his trade. Begin with little jewellery; add rings, chains and richer ornament at successive locations. The cap pin and gold tooth can remain recognizable anchors even in the less wealthy starter.

Maintain his facial identity, gaze, hand gesture and framing across later portrait variants. The concept's upper-left lantern light is a presentation reference; production portraits must keep neutral character colours/form separate from lighting, following [the portrait lighting contract](portrait-lighting.md), so the light can match the rest location. Clothing can be altered to fit his increasing size while preserving the waistcoat's recognizable colour and pattern. Distinguish stages through silhouette and facial structure as well as surface grime, so the change remains readable at phone size.

| Suggested visual stage | Silhouette and face | Clothes and surrounding details |
| --- | --- | --- |
| Starting location | Already markedly obese, matching v1's middle figure; full cheeks/jowls and substantial belly | Worn brocade waistcoat, little jewellery, no lavish chains, less displayed gold |
| Later location (illustrative) | Heavier than the revised starter; more pronounced jowls and belly | More rings and a chain, better but stained clothes, growing coin piles, sweat and food stains |
| Much later location (illustrative) | Massively obese beyond the revised starter; layered jowls and belly dominate, same alert eyes and smile | Rich but filthy finery, extravagant jewellery, greasy fingers, stained collar/bib and ostentatious accumulated wealth |

The grotesque treatment combines increasing size with neglect, stained finery, unpleasant eating habits and avaricious behaviour. He remains fully clothed and recognizably human in this concept. Body horror, demonic identity, a final transformation or a villain reveal would need a separate decision.

The three panels illustrate a longer location-by-location progression; they do not limit the campaign to three sites. Treat advancement to a new campaign location as the proposed appearance update point, rather than changing him on every camp revisit or transaction. Exact steps and how revisiting an earlier location affects his appearance remain open. No per-floor transformation, real-time weight simulation or animation rig is implied.

## Place in the campsite

Make the existing supply awning his merchant area: the same five-destination clearing now has a recognizable character behind its provision counter. Label it **Merchant** in the eventual game interface; keep its internal destination ID `supplies` if useful. A red cap, coin scales and familiar hanging lantern can help identify his stall in later refuges.

Selecting the awning opens his portrait/dialogue and trading view. Proposed choices are Trade, Review carried supplies and Leave. Buying/selling is the natural service proposal; available stock, exchange rules, prices, discounts, scarcity and whether he provides storage remain undecided. Show the item, quantity, price and resulting balance before a transaction is committed. Merely opening his view spends nothing.

He follows the party between rest locations, including the initial campsite and later refuges. Whether he also appears at every small rest spot inside a dungeon, how he reaches later locations and what happens if a rest location is abandoned remain placement/story questions. Do not implement a trailing NPC, escort requirement or movement simulation based on this direction alone.

## Concept asset and production limits

See the revised [merchant-progression-v2.png](../art/concepts/merchant/merchant-progression-v2.png) and its [provenance/prompt](../art/concepts/merchant/README.md). V2 starts from v1's middle build with reduced jewellery and increases size and wealth across the sheet. The original [v1](../art/concepts/merchant/merchant-progression-v1.png) is preserved as concept history; its left figure is superseded as the starter. Both are generated concept art, not layered portrait masters, sprite sheets or final game UI.

Before production, review the identity and tone with the owner; clean and align each chosen stage; simplify enough to read at the established 192 x 192 portrait working size; and validate expression changes and framing. The merchant may require his own wider service portrait/body template as he grows; do not force his silhouette into the six proposed companion body templates. Portrait dimensions and animation coverage remain to be tested.
