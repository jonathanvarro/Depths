# Starter weapons and supplies — inventory art v1

Issue #29. Thirteen transparent item images for the cave/campsite, matching the approved rough, lightly rusty knife. Twelve images were generated individually with the built-in image tool on 2026-10-17; `plain-knife.png` is an exact copy of the previously approved `art/concepts/items/plain-knife-v2.png`. Original files are preserved. No artwork was resized or retouched for this delivery.

## Asset map

Use `res://art/items/starter-v1/` followed by the filename below. Images have real alpha transparency and no embedded labels or UI frames.

| Item | File | Distinguishing features |
| --- | --- | --- |
| Approved plain knife | [plain-knife.png](plain-knife.png) | Short iron blade, subtle rust, two-rivet wood grip |
| Wooden club | [wooden-club.png](wooden-club.png) | Knotted blunt head, wrapped grip |
| Simple spear | [simple-spear.png](simple-spear.png) | Full shaft, small iron point |
| Woodcutter's axe | [woodcutters-axe.png](woodcutters-axe.png) | Curved wood handle, practical single iron head |
| Plain staff | [plain-staff.png](plain-staff.png) | Full-length wood shaft, central cloth grip |
| Well-made iron sword | [iron-sword.png](iron-sword.png) | Straight double edge and simple crossguard; cleaner quality upgrade |
| Wooden shield | [wooden-shield.png](wooden-shield.png) | Round planks, central boss and lightly rusted rim |
| Padded coat | [padded-coat.png](padded-coat.png) | Sleeveless quilted coat, tied front |
| Oil flask | [oil-flask.png](oil-flask.png) | Squat leather body and practical metal pourer |
| Party ration | [party-ration.png](party-ration.png) | Bread, preserved meat and cheese in one tied cloth bundle |
| Clean dressing | [clean-dressing.png](clean-dressing.png) | Clean linen roll and loose folded end |
| Restorative draught | [restorative-draught.png](restorative-draught.png) | Round amber bottle, reddish herbal liquid and cloth neck wrap |
| Antivenom | [antivenom.png](antivenom.png) | Tall narrow vial, olive liquid and teal thread |

## Handoff to Claude

The existing `SupplyItem.icon` field can reference these textures when integrating the supply screen. At the time of creation, the implemented definitions map as follows:

- `data/items/oil_flask.tres` -> `res://art/items/starter-v1/oil-flask.png`
- `data/items/ration.tres` -> `res://art/items/starter-v1/party-ration.png`
- `data/items/restorative_draught.tres` -> `res://art/items/starter-v1/restorative-draught.png`
- `data/items/dressing.tres` -> `res://art/items/starter-v1/clean-dressing.png` (added by Claude while this art set was being prepared)

Antivenom art is ready for its later item definition. Weapon/protection images do not add an equipment system. This art task intentionally leaves the ongoing supplies/portrait code and resource definitions untouched; it does not change item stats, prices, uses or starting quantities.

## Style and production status

Muted wood/iron/linen, warm upper-left highlights, deliberate pixel texture and clear silhouettes. Rust is restrained on ordinary ironwork; the quality sword is cleaner. Medical cloth remains clean. Containers differ in shape as well as hue. Long weapons fit completely within their own square canvases; relative icon size does not depict real-world scale.

These are usable generated source textures, not hand-cleaned native 128 x 128 pixel masters. Final native icon dimensions remain to be agreed. Review at the actual inventory display size, simplify dense detail where necessary, clean alpha edges, standardize padding and prepare optimized exports before treating them as a final mobile art library. Do not load all full-size sources into a phone inventory without checking texture memory and the UI's import/display settings. Keep these sources for future export work rather than overwriting them.

The preview is a browser-rendered review sheet of the source images at small display sizes; it is not a production sprite atlas. The actual assets are the thirteen individually named PNGs.

All thirteen source icons are 1254 x 1254 RGBA. See [the overview](preview.png) for a compact visual review.

## Provenance and validation

Full prompts and original output paths are in [generation-manifest.json](generation-manifest.json); they are provenance only and are not needed to use the copied assets. The reused knife's generation/edit history is in [the earlier README](../../concepts/items/README.md). Each new item was generated separately, using text descriptions of the approved style, rather than extracting icons from a generated sheet.

All images were visually inspected for subject, silhouette, consistency and unwanted labels/backgrounds. [validation.json](validation.json) records PNG decoding, true alpha transparency, dimensions, nonempty silhouettes and SHA-256 equality with each original source. In-game integration, phone readability and pixel-perfect edge cleanup remain untested. No game scripts changed and no mechanic is implied by visual wear.
