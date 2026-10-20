# Camp, items and quieter interfaces · #112 / #120

Owner requested higher camp resolution, more distinctive items and descriptions, reuse of the coins/jewellery mark, less repeated text, more visual controls, and coherent portrait blinking/speech. This pass installs the camp/item/portrait changes and focused live UI cleanup. The combined physical equipment/backpack remains an interactive study for later Godot integration under #51/#48.

## Camp

[Starting camp at phone size](../art/concepts/camp-highres-v4/starting-1278.png) · [after the first night](../art/concepts/camp-highres-v4/morning-1278.png) · [merchant](../art/concepts/camp-highres-v4/unloading-1278.png)

Runtime art is now [highres-v4](../art/camp/highres-v4/layout.json). Terrain is **1600×900**, site textures have **2.5× density** on the same logical 640×360 canvas, and NPC portraits are **512×512**. [The exporter](../tools/art/build_highres_camp.py) returns to the retained original masters, rather than enlarging the old 640px terrain or 192px portraits. Full source colour and linear filtering replace the old common 64-colour camp reduction. Every original master and earlier export remains intact.

Independent terrain/sites, unloading caravan, occupied cot, contract notice, anonymous occupancy and animated local lights remain separate. Existing logical positions, target rectangles, site presence and service timings remain: merchant opens on the first post-tutorial expedition return; smith arrives after the first camp night. Light animation still supports the existing still mode. The sharper textures total **11.96 MiB uncompressed RGBA** before engine/GPU overhead; physical iPhone performance has not been measured. Source/export hashes and actual 101-check/15-capture arrival run are in [the review folder](../art/concepts/camp-highres-v4/godot-validation.json).

## Items and shared mark

Every current **22 supply/treasure and 10 equipment resources** now uses an individual native **128×128** icon exported directly from its larger original master. Two lantern states use the same format. The 112px content box leaves at least 8px around each silhouette; transparent cutouts and the established 64-colour-per-icon limit remain. Long shafts stay long, gems differ by cut and colour, and cloth, metal and worn leather keep distinct shapes. Review [64px/40px on dark](../art/concepts/items/refined-v2/library-64-40-dark.png), [on light](../art/concepts/items/refined-v2/library-64-40-light.png) and [old/new at 64px](../art/concepts/items/refined-v2/before-after-64.png).

Names and descriptions now call out visible construction and wear: Riveted knife, Knotted oak club, Amber tear pendant, Silver sprig locket and Faded campaign medal, for example. Supply use/targeting information remains. Resource filenames remain stable for saves; prices, effects, quantities, damage, armour, reach and all other resource contents are unchanged against commit `56f6ca6` (**164 explicit gameplay fields**, plus complete non-visual text comparison).

[The catalogue](../art/items/refined-v2/catalog.json) records each old/new name, description, source/crop/scale, design rationale, resource path, unchanged gameplay values and hashes. Rebuild with [build_refined_items.py](../tools/art/build_refined_items.py); only `--wire` updates live resources. [validate_refined_items.py](../tools/art/validate_refined_items.py) checks the recorded baseline and source preservation. The 34 textures total **2.125 MiB RGBA**. No new raster artwork or upscaling was needed for this pass.

[The reusable forked seal](item-emblem-language.md) derives from the angular coin/signet language. Its small currency glyph is shared by Camp, Pack and the new browser review. The full seal and impression are editable SVGs. The medal's sunburst and locket's leaf remain distinct; this does not assign a faction, quest or rarity to the mark. Original generated engravings are related rather than falsely treated as identical logos.

## Interface

The shipping **Camp** has a gear icon and back chevron, accessible names/tooltips and existing 44px minimum physical targets. A single purse amount replaces repeated purse paragraphs. Nurse recovery copy keeps the patient context and consequences without repeating the name in the same sentence.

The shipping **Pack** uses gear/close icons, the shared currency mark and sharper item/light icons. Fuel amount/bar and meaningful action costs remain visible. Secondary lantern explanation moves to a tooltip; item descriptions still explain use. Injury and strain paragraphs use their hero heading for context. **Preparation** relies on each party card for identity, health, strain and conditions, with a nurse-care note where needed, rather than repeating those values in another paragraph. Its supply list scrolls. Pack/Preparation backgrounds are opaque so the underlying HUD names and dialogue do not show through.

[Live Pack, Larger phone text](../art/concepts/interface/live-refinement-v1/pack-1278-Larger.png) · [live Preparation](../art/concepts/interface/live-refinement-v1/preparation-1278-Larger.png)

The revised **combined browser study** has one name per portrait selector, Equipment/Status on the left and the physical bag always on the right. Current resource names, descriptions and icons populate inspection, including replacement identity and receiving-slot highlight. Empty body equipment has a quiet garment outline. No browsing/no-time or review boilerplate occupies the game view. Explicit costs and unavailable reasons remain.

[Interactive review](../art/concepts/interface/pack-heroes-v5/combined-kit.html) · [phone Equipment](../art/concepts/interface/pack-heroes-v5/phone-equipment.png) · [item inspection](../art/concepts/interface/pack-heroes-v5/phone-inspect.png) · [Status](../art/concepts/interface/pack-heroes-v5/phone-status.png)

The browser uses isolated example inventory, oil/health and loadouts; showing the three starting choices together does not grant a three-hero starting party. Demonstrated Use only decrements its sample stack, with no game clock or healing simulation. Twelve compartments are illustrative, not an approved capacity rule; overflow uses pages without shrinking targets. Integration must bind real targeting, trait modifiers, costs, permissions and inventory paging to the model. The live Pack remains a scrolling list in this pass. Existing approved physical bag/roll art and original ImageGen prompts are reused from v3.

## Portrait coherence

**Follow-ups #121/#124:** the owner identified old lashes/lip corners beneath v2 drawings, then Claude identified flat mouth/lid rendering in v3. [The current handoff](portrait-rig-families.md) retains v3 clean/neutral/matte components with textured v4 animation: original lip tissue, smaller openings and curved lids retaining the lower iris halfway through a blink. The inspector exposes the underlying plate. Resting reconstruction, timing and filtering remain exact; dimension/playback checks alone do not certify style.

[Animation preview](../art/concepts/portrait-coherence-v1/motion.gif) · [hero frame registration](../art/concepts/portrait-coherence-v1/registration-0.png)

All **30 PortraitSets** were checked: three starting heroes, nine neutral recruit faces and eighteen static worried/exhausted variants. The twelve neutral faces each retain their own registered 192×192 transparent eye/mouth drawings; no face borrows another face's frames. Four native-size contact sheets show neutral, half lid, closed, small/open/round mouth and neutral again. No portrait pixels, lighting layers or character registration were changed.

`PortraitView` now holds the closed eye briefly and reopens through the half lid. Speech moves through small/open/small/rest syllables, using the third round drawing when available, instead of picking arbitrary mouths every 90ms. Each utterance ends at the resting mouth. Hiding, disabling or replacing a portrait immediately cancels old callbacks/layers and restores its neutral expression. Fallen heroes stay still and can animate after revival. A local cosmetic random generator schedules blinks/tremor without consuming gameplay random draws. This is expressive speech animation, not phoneme/audio lip sync. Flat camp NPC portraits and expression sets without authored frames remain static.

## Verification and handoff

- Godot 4.7.2 import, **163 item checks**, **101 camp arrival checks**, **40 live interface checks**, **450 portrait checks** and **129 browser checks** pass. Camp/input, commerce, save/load and full opening playthrough regressions pass with clean engine logs. Desktop, 1278×590 and 1334×750/compact browser shapes reviewed; live screen checks include Normal/Larger text and simulated safe areas.
- Portrait tests exercise neutral return, hiding/reopening, fallen state, mid-speech replacement, explicit interruption, speech pauses and RNG isolation. Runtime captures supplement the registration/contact review. Native art registration is unchanged; no physical iPhone claim.
- Two existing playthrough checks used literal former item names, and one expected an exact `Use` caption. They now read current resource names/accept visible time costs, while retaining their behavioral assertions. The initial stale-name failures were corrected and rerun.
- One UI-check run completed all assertions but Godot returned a native shutdown error without an engine diagnostic. An immediate repeat of the same run completed with exit 0 and an empty error log; the final report/captures are from that clean repeat.
- Reproduction: `tools/art/check_refined_items.gd`, `check_interface_refinement.gd`, `check_portrait_coherence.gd`, `check_camp_arrivals.gd` (optional output directory); `tools/art/check_refined_kit_study.cjs` uses Playwright/Chrome. Review JSON sits beside each capture set.
- Physical iPhone testing remains #66; the combined Godot layout remains #51/#48. Do not treat the browser's example counts or party as game data.
