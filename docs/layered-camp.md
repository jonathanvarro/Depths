# Layered relief camp and local light · #108

The owner approved the connected-camp study, requested independent landscape/sites for story arrivals, and asked for simple lantern/fire glows. The live camp now uses that layered arrangement.

## Assets and layers

`art/camp/organic-v3/terrain.png` is a complete 640×360 landscape with paths, natural shelves, forest and cave geology. It has no tents, people, camp furniture, lamps or light pools. Hiding every site leaves a coherent empty clearing.

Six independent scenes preserve the existing IDs: `supplies`, `treatment`, `rest`, `smith`, `fire`, `cave`. Their small cropped transparent textures are registered to the shared canvas in `layout.json`. The cave mouth is permanent geology; its scene adds the removable trail post and lantern. The nurse's occupied cot and cave's paper notice are separate children. Existing NPC portraits remain separate and unchanged. Recruit figures and meal follow the actual available candidates, not painted people in the background.

Sources retain neutral overcast material shading. Dynamic light is supplied separately. The static layers share at most 64 colours, nearest filtering and binary alpha; a high alpha cutoff drops soft extraction halos. The first generated hearth wrongly included other sites, so it remains an unused source and a corrected single-hearth master is exported instead.

## Availability and saving

`CampState.site_presence` stores optional story-controlled flags. `site_present(id)` reads them; `set_site_present(id, present)` updates them and emits the existing changed signal. Site art, lamps, labels and hit targets change together. Removing an active site closes its activity, and hidden/unknown services reject direct opening. Back does not revive a missing target.

**Arrival follow-up (#80):** the owner has now chosen [the initial camp and two opening triggers](camp-arrivals.md). Your tent/fire/nurse are established, the visible caravan is unloading with trading closed, and the smith has not arrived. The first post-tutorial expedition return opens trading; the first camp night brings the smith. Missing presence keys still default to present, preserving established saves. Existing save serialization stores the arrival state inside the camp object, with no version bump. Prices, day progression, treatment and recruitment rules are unchanged.

Story code can set a site's flag when the story requires it, for example:

```gdscript
camp.set_site_present("smith", false)
# Later, after the chosen story condition:
camp.set_site_present("smith", true)
```

The earlier partial-camp review image explicitly selects rest/fire/cave only. It remains a compositing fixture; use the [new initial-state capture](../art/concepts/camp-arrivals-v1/starting-1278.png) for the owner's actual day-one composition. The unloading wagon is a separate child layer; the original established stall remains intact for the transition.

## Animation and interaction

`warm_light.gd` adds four small local lights for the merchant/personal-tent/cave lanterns and smith's brazier, plus the hearth's separate warmth. Brightness drifts gently within ±10% using deterministic slow waves, without consuming random numbers, oil, days or expedition time. Small glass/coal cores and the reused six-frame hearth flame make the light sources visible. Artwork uses light mask 2; interface text and controls stay on mask 1.

Hidden sites have no visible lights. Hidden camp animation pauses. `CampScreen.animate_lights = false` gives a still presentation with steady light and the flame paused at frame zero, ready for later motion-preference integration. It does not add a new settings screen option.

The six large non-overlapping targets still open activities with one mouse click or touch and keyboard focus. Small outlined names follow the sites instead of full-width black button bars. Focus/hover gently warms the site's art and name. Save/Settings move to the foreground edge so they do not cover the cave; global/activity controls retain at least 44 logical pixels of height at Larger UI size.

## Sources, exports and review

Built-in **ImageGen** supplied eight initial masters and one hearth correction. Originals, the hearth reference crop and exact prompts are preserved in [`art/source/camp-layered-v3/`](../art/source/camp-layered-v3/): [initial manifest](../art/source/camp-layered-v3/generation-manifest.json), [hearth correction](../art/source/camp-layered-v3/fire-correction.json). No paid API fallback was used. Existing authored paper, seated figures and flame frames are reused.

`tools/art/build_layered_camp.py` rebuilds registered textures/scenes/layout and export hashes. `tools/art/validate_layered_camp.py` checks source/output hashes, alpha, shared palette, canvas bounds, lamp alignment, documentation links and preserved camp rules. `tools/art/check_layered_camp.gd` exercises actual Main/CampScreen input, presence, recovery, contract, save serialization, animation and phone safe areas. `tools/art/build_camp_glow_preview.py` encodes the captured animation.

The focused check passes **258 checks with 18 captures** at desktop, 1278×590 and 1334×750, including Larger UI. Empty/partial/full scenes, both input types, disabled targets, removing an active service, recruit count, recovery/notice layers, animated/still/hidden states and unchanged time/oil/day are covered. Existing camp, save, recruitment and opening-playthrough checks also pass with clean engine error logs. Physical iPhone testing remains separate.

- [Full camp](../art/concepts/camp-layered-v3/all-sites-1278.png)
- [Empty terrain](../art/concepts/camp-layered-v3/terrain-only-1278.png)
- [Partial-camp fixture](../art/concepts/camp-layered-v3/partial-fixture-1278.png)
- [Animated review](../art/concepts/camp-layered-v3/camp-glow.gif)

The earlier [composition study](camp-composition-v2.md) remains preserved for reference. Its painted lights and figures are superseded by these independent live components.
