# Starting camp and arrivals · #80

Owner decisions, 2026-10-18:

| Stage | Visible camp | Services |
| --- | --- | --- |
| First arrival after tutorial escape | Your tent, recruitment fire, nurse's tent; merchant wagon visibly unloading. Cave path remains. No smith. | Rest/stash, recruitment, treatment and cave departure available. Merchant can be inspected, with an explanation; no trading. |
| First post-tutorial expedition return | Merchant switches to the established stall. | Supply buying, lantern purchase and selling open. |
| First morning after resting at camp | Apprentice smith and his working area appear. | Existing basic smith stock becomes available. |

The merchant and smith triggers are independent. Resting before the first expedition brings the smith, while the merchant remains unloading until an expedition return. The tutorial escape does not count as that return. Returning again or resting later never resets the camp. No extra stock tiers, prices, threat growth or waiting penalty are invented.

## Live implementation

`CampState.begin_arrivals()` sets the new-story composition, merchant unloading flag and the smith's due day. Main opts in for a fresh story or a restarted tutorial, excluding explicit debug starts and existing non-tutorial campaigns. `expedition_returned()` opens trading only on the later return path; `rest()` brings the smith on the first morning. Existing save-object serialization carries `merchant_unloading`, `smith_arrival_day` and `site_presence`; missing new fields preserve older campaigns' established services. No save version change.

Buy/sell/lantern transactions check the merchant's readiness in the model, so a hidden UI action cannot bypass the closed shop. Smith purchases require the site to be present. Existing opening gifts are unchanged, and the merchant can still front emergency torches through the existing once-a-day charity rule: this keeps the party supplied without opening trade. No costs or supplies were added by this story pass.

CampScreen uses a distinct `Unloading` layer beneath the same merchant site. The map label says **Merchant · Unloading**, and inspection explains why trading is unavailable. The normal stall and lantern return when trading opens. The absent smith has no artwork, light or target. Shared theme colours/focus are retained, with compact local button padding for the camp's 640px scaled canvas; global controls fit the screen, and activity views show Back without partly obscured Save/Settings buttons.

## Artwork and sources

Built-in **ImageGen** authored one transparent unloading-wagon master from the existing merchant cutout and full-camp perspective reference. Loaded wagon, lowered tailboard, crates and bundled awning/poles communicate unpacking without a shop counter or extra NPC identities. The original established stall is unchanged.

- [Master and exact prompt/reference roles](../art/source/camp-arrivals-v1/generation-manifest.json)
- [Runtime wagon](../art/camp/arrivals-v1/caravan-unloading.png) and [registered scene](../art/camp/arrivals-v1/caravan-unloading.tscn)
- [Source/export hashes and registration](../art/concepts/camp-arrivals-v1/export-validation.json)
- [Starting camp, phone](../art/concepts/camp-arrivals-v1/starting-1278.png)
- [Starting camp, Larger UI](../art/concepts/camp-arrivals-v1/starting-1278-larger.png)
- [Closed merchant inspection](../art/concepts/camp-arrivals-v1/unloading-1278.png)
- [Trading established after return](../art/concepts/camp-arrivals-v1/trading-1278.png)
- [Smith present the next morning](../art/concepts/camp-arrivals-v1/morning-1278.png)

`tools/art/build_camp_arrivals.py` crops/registers the generated alpha, reduces with nearest filtering, uses only the existing camp's 64 colours and exports binary alpha at the same cutoff as the other sites. It changes no original camp textures, site scenes or terrain. No paid API fallback.

## Checks

`tools/art/check_camp_arrivals.gd` passes **101 checks with 15 captures** across desktop, 1278×590 and 1334×750, including Larger UI. Checks cover actual new-story setup and tutorial return, mouse/touch inspection, clear unavailable actions, model-level rejected transactions with unchanged money/items, saved stages and older defaults, emergency kit limits, actual departure/preparation/return and first rest, independent trigger order, repeated rests, stage artwork/labels, absent targets and safe global controls. Existing camp, saving, gold/economy and full opening-playthrough checks also pass with clean engine logs. Captures of the starting camp, merchant and morning were visually reviewed. Physical iPhone remains untested.
