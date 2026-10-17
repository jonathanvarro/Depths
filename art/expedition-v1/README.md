# Expedition art pass v1 — Claude handoff

Completed for the owner's seven-part request (#31), including the combat mockup for #13. All generated originals and exact prompts are preserved in [the source manifest](../source/expedition-v1/generation-manifest.json) and [its addendum](../source/expedition-v1/generation-addendum.json). Generation used the built-in image tool. A deterministic export pass produces the fixed canvases below; original Mara/item art is unchanged.

## What is connected already

| Request | Runtime assets | Integration |
| --- | --- | --- |
| Mara blink | `art/portraits/mara-animation-v1/eyes-half.png`, `eyes-closed.png` | Assigned in `data/portraits/mara.tres`; existing automatic blink uses them |
| Mara talk | Same folder: `mouth-small.png`, `mouth-open.png`, `mouth-round.png` | Assigned as talk_frames; existing `PortraitView.talk(seconds)` uses them |
| Mara conditions | Same folder: `blood.png`, `dirt.png`, `bandage.png`, `pallor.png` | Assigned under those exact dictionary keys; existing blood/bandage injury wiring and Claude's strain pallor wiring can display them. Dirt still needs a gameplay trigger when desired |
| Cave surfaces | `art/textures/cave-v1/wall.png`, `floor.png`, `ceiling.png` and matching `.tres` materials | `themes/cave.tres` now uses them; both wall slots use the same natural-rock material. Stone theme remains unchanged |
| Cave features | `art/features/cave-v1/`: web-intact/torn, root-barrier, pit-opening, hanging-roots PNGs | `closed/opened/blocked/descent/ascent.tscn` assigned in cave theme |
| Pack icons | `art/items/pack-64-v1/`: oil-flask, ration, restorative-draught PNGs | Assigned to the three corresponding `data/items/*.tres` icon fields |
| Enemy art | `art/enemies/cave-v1/{rat,spider,goblin}/`: idle, attack, hurt PNGs | Each enemy has `frames.tres` and `scene.tscn` ready for combat integration; no encounters/combat logic added |
| Combat mockup | [Desktop](combat-desktop.png), [landscape phone](combat-phone.png) | Actual Godot Mobile-renderer layout study using the new assets; illustrative encounter, not playable combat |

## Exact canvas and registration contract

**Mara:** every frame/overlay is exactly 192 x 192 RGBA, origin (0,0), with transparent pixels outside its patch. No per-frame trimming. The original base, neutral patches, tunic and background in `mara-layered-v1` are preserved. Generated expression references are reduced onto that same grid. Only the eye regions `(85,65)-(106,76)` and `(118,64)-(135,76)`, or mouth `(96,96)-(124,106)`, may change in a composite. Outside those regions the neutral composite is byte-identical. Replacement patches include original surrounding skin so old features are covered. Registration checks selected zero translation for all five source expression drawings. Condition overlays are clipped to the original silhouette/skin, with eye/mouth windows kept clear; pallor is a translucent tint so expressions still show. Layer combinations still merit editorial polish; no claim that the entire original portrait has now been separated into reusable head/body/hair masters.

**Cave features:** every image is exactly 256 x 256 RGBA on one fixed normalized passage canvas. Intact/torn webs have byte-identical outer anchors outside the central tear rectangle `(48,48)-(208,240)`. The hole is genuinely transparent. Pit exterior is transparent; its interior is dark, not transparent. Scenes use cell-centre floor origins and face along the passage, with vertical art sized for the current 2m cells / 2.4m walls. The pit scene sits on a floor plane; it is a visual transition marker, not falling physics. Sprite features use alpha scissoring and nearest filtering; check fine silk at other camera distances before final production.

**Enemies:** all nine poses are exactly 256 x 256 RGBA. Each enemy uses one common scale across its three poses, a fixed `(128,240)` pivot and a solid ground baseline within one pixel of y=240. `registration.json` records translation/scale. The supplied world scenes use a low rat/spider and taller goblin; the SpriteFrames names are `idle`, `attack`, `hurt`. These are three discrete starter drawings, not a complete walk/death animation set. No creature stats or combat timing is implied.

**Surfaces:** three opaque 64 x 64 RGB tiles, nearest filtering and roughness 1.0. Opposite outer texel rows/columns are numerically equal after seam cleanup. [The 4x4 repeat preview](../textures/cave-v1/repeat-preview.png) was visually reviewed. Repetition and the existing BoxMesh UV stretching remain prototype limitations; edge equality does not guarantee a final seamless natural-rock library. No expensive normals, reflections or version/renderer changes.

**Pack:** three exact 64 x 64 RGBA exports of the approved source set, retaining its full framing and transparency. This task uses the explicitly requested 64px size; it does not silently make 64px the standard for all future weapon art. Generated masters remain under `art/items/starter-v1`.

The owner subsequently requested simpler enemies. This detailed set is preserved as reference. The complete [128px replacement family](../enemies/cave-simple-v1/README.md) now provides all nine poses and the current EnemyType.scene paths; see [the lower-detail guide](../../docs/enemy-art-direction.md) before generating more enemies.

## Previews

- [Mara expressions/conditions](../portraits/mara-animation-v1/preview.png), [blink GIF](../portraits/mara-animation-v1/blink-preview.gif), [talk GIF](../portraits/mara-animation-v1/talk-preview.gif)
- [Feature sheet](../features/cave-v1/preview.png)
- [Enemy pose sheet](../enemies/cave-v1/preview.png)
- [64px Pack sheet](../items/pack-64-v1/preview.png)

Combat uses the owner's Attack / Defend / Item direction, no magic actions, and the existing three party slots along the bottom. Empty slots intentionally reflect the lone-survivor opening; the mixed enemy encounter is a layout example, not an approved mandatory opening fight. Button labels in this static mockup do not decide which items can be used in combat or implement their effects. Mobile mockup uses 48px side margins and 48px-tall action buttons; real-device safe areas and accessibility still need testing.

## Rebuild and checks

`python tools/art/build_expedition_art.py` rebuilds from the local preserved sources with Pillow and NumPy. It crops only fixed facial replacement regions, clips condition masks, cleans observed red/yellow transparent matte contamination, normalizes canvas sizes, preserves web anchors, aligns enemy ground lines and exports icons. Review sheets/GIFs are generated for inspection; they are not runtime sprite atlases. Source originals are in a `.gdignore` folder to avoid importing large references into the game.

`tools/art/check_expedition_art.gd` runs in the existing Godot 4.7.2 and checks live blink/talk swaps and restoration, named overlays, icon sizes, cave materials/scenes and enemy pose resources (51 checks). `tools/art/render_art_review.gd` renders the two combat images with the unchanged Mobile renderer. No tests or script changes were made to the gameplay systems.

See [validation.json](validation.json) for PNG dimensions/alpha/hashes, zero changes outside facial regions, matching web anchors and texture-edge checks. See the same-sized preview sheets before producing more variants. No generation API key or external source path is needed to rebuild these exports.
