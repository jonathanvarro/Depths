# Campaign art delivery · 2026-10-18

Artwork for #99, #103, #105, #96, #50 and #89 is exported and connected. Presentation changes preserve current hero stats, enemy numbers, equipment rules and discovery rules.

## Live assets

| Area | Assets and connections |
| --- | --- |
| Fortress (#99) | Queen idle/attack/hurt and three enraged poses; archer idle/draw/release/hurt; guard idle/bash/hurt/brace. `art/enemies/campaign-v1/` includes six complete families, adding the great rat, webspinner and drummer from #47. Each has `scene.tscn` and `frames.tres`. |
| Environment | Four worked-stone/timber textures and materials in `art/textures/fortress-v1/`, wired through `themes/fortress.tres`. Barred/broken gate and closed/open hall doors in `art/features/fortress-v1/`. Marked gates retain broken remains. |
| Dressing | Palisade, watch post, painted rock, trophies and throne in `art/props/fortress-v1/`. Main places outskirts props and a seat in the existing hall. Decorative only, with no new collision or rewards. |
| Victory | `art/illustrations/fortress-v1/victory.png`, connected to the queen's defeat brief. An empty throne avoids assuming which heroes survived. |
| Heroes (#103) | `data/portraits/corin.tres` and `alwen.tres`, with layers in `art/portraits/main-heroes-v1/`. Neutral character, blink/talk, four conditions and separate lighting masks. Companion resources use these sets. Hero selection keeps choice buttons visible while details scroll at Larger text size. |
| Equipment | Broken short sword and cracked staff in `art/items/campaign-v1/`, wired to gear resources. Padded coat now uses its existing icon; leather jerkin already had its correct icon. |
| Feedback (#105) | Twelve replacement 32px PNGs at the existing `art/ui/visual105-v1/` paths: rush, recover, beat, webbed, venom, guard, drummed, armour, miss, heart, nerves and rest. Editable original SVGs are preserved. Existing slash/claw effects remain. |
| Backlog (#96) | Main instantiates the existing held torch/lantern using actual supplies and places the existing daylight exit only in the opening. Held art hides during menus/camp/combat and does not consume fuel or advance time. |
| Map (#50) | Both views use existing paper/glyphs with joined charcoal boundaries, stable irregular strokes, blank unknown regions and sparse notes. [Implementation guide](hand-drawn-map-design.md). Owner review of the new preview is pending. |
| Camp (#89) | Two anonymous seated recruit silhouettes, a meal, drying cloth and local fire warmth. Presence follows available recruits. [Before/after review](camp-dressing-review.md). |

## Production contract

Enemies and world features use 128×128 transparent canvases, at most 32 visible colours, nearest filtering and shared ground pivot `(64,120)`. Each pose family shares scale and horizontal registration; floor contact is registered vertically. Queen phases share one palette. The catalog records world heights and the export report records bounds/transforms. Tiny detached alpha specks are removed only during enemy export; the exporter does not repaint poses.

Portrait layers remain full 192×192 transparent canvases, with four-pixel base padding and at most 48 colours. Registered eye/mouth patches, blood, dirt, bandage, pallor and separate light masks are supplied for both heroes. Body/head components compose the neutral base. OpenRaster masters retain editable layers. The existing renderer supplies neutral/warm/dim presentation; no automatic fuel-to-face rule is introduced.

Inventory icons and camp cues use 64×64 transparent canvases. Victory is opaque 640×360. Native 32px glyphs retain antialiased edge alpha.

## Sources and rebuilding

Built-in **ImageGen** authored 23 raster masters. Originals, two portrait references, two layered `.ora` files and all exact prompts/reference paths are in [`art/source/campaign-v1/`](../art/source/campaign-v1/), excluded from Godot import. The [generation manifest](../art/source/campaign-v1/generation-manifest.json) records tool provenance and filenames. No paid API fallback or external stock art was used. Small glyphs are original SVG drawings.

With Python/Pillow and Godot available:

```
python tools/art/build_campaign_art.py
python tools/art/build_main_hero_portraits.py
python tools/art/build_campaign_glyphs.py
godot --headless --path . --script res://tools/art/rasterize_campaign_glyphs.gd
python tools/art/review_campaign_art.py
```

Builders regenerate art and reports. Optional `--wire-icons` / `--wire` flags set corresponding resource art references. Theme/Main hooks stay in their normal source files; rebuilding art does not rewrite them. Existing gameplay values are preserved.

## Validation and review

The [review directory](../art/concepts/campaign-v1/) contains native/small dark/light sheets, actual Godot desktop/landscape-phone captures, expression/condition/light comparisons, and machine-readable export/portrait/runtime reports.

- `check_campaign_art.gd`: **286 checks, no failures, 50 captures**. Actual portraits/tweens, lighting, held-light supply states, hero choice, camp input/state, all six enemies, queen rage/guard brace, victory, four map facings and discovery/cache invariants.
- `check_campaign_map.gd`: **22 checks, no failures, eight captures**. Gate transitions versus ordinary doors, sparse/complex maps at 1278×590 and 1334×750, normal/Larger text. Notes deduplicate and fit available height.
- Existing `fortress_check.gd`, `hero_check.gd`, `visual_check.gd`, `camp_check.gd` and `opening_playthrough.gd`: all pass at landscape-phone size with clean engine error logs. The visual test selects a normal goblin swing instead of randomly waiting at an interactive killing-blow coin prompt, and finishes its fight before shutdown.

Previews: [hero choice](../art/concepts/campaign-v1/hero-choice-phone.png), [queen poses](../art/concepts/campaign-v1/queen-dark.png), [enraged queen in combat](../art/concepts/campaign-v1/combat-queen-enraged-phone.png), [map](../art/concepts/campaign-v1/map-facing-0-phone.png), [camp](../art/concepts/campaign-v1/camp-after-phone.png).

## Remaining work

Owner review of the new map remains pending (#50). Physical iPhone rendering/touch and subjective audio listening were not tested. #99's drums, gate break and screech, and #96/#54's accepted live sound replacements remain unfinished. Existing darker sound auditions are unchanged. Later merchant portraits remain conditional on a second site. No new class, encounter, recruit or economy decisions are implied.
