# A map drawn by the party

The owner requested rougher paper and a map that feels hand-drawn by the heroes rather than a perfect visible grid (#34). [Original visual study](../art/concepts/map/hero-map-v1.png). The drawing layer is implemented under #50; navigation and discovery rules remain unchanged.

## Owner refinement · 2026-10-18

The owner reviewed the live preview as “much improved” and requested simpler symbols without a legend, the same chest crossed with a red X once searched, and less straight lines to suggest drawing while moving. These refinements are now live in both map views.

The full-screen legend is removed, freeing more space for the drawing. A searched chest preserves the exact chest drawing with a muted red cross over it at full ink strength; it no longer needs a separate searched caption. Rest uses a bed symbol, a closed passage a door, blocked passages rocks, and a strange object a question mark. Ladder arrows, warning triangles and the party arrow retain their distinct shapes. The red cross is recognizable by shape as well as colour. Original 32px SVG sources and their generator remain editable; no generated raster art was needed for this revision.

Boundaries now drift gently between shared corners, with bounded, deterministic curves, slightly displaced vertices and occasional faint retracing. The roughness stays within a fraction of one cell. Junctions stay joined, passage centres and contents stay accurate, unknown territory stays blank and turning does not randomize the ink. Markers are slightly larger for readability at phone size.

`tools/art/check_map_refinement.gd` passes 48 checks with 15 captures: discovery isolation, stable/bounded curves, shared corners, chest identity and red ink, no legend, safe Close sizing, and touch/key/corner-map input. Desktop, 1278×590 and 1334×750 are reviewed at normal and Larger UI scale. [Symbol/state review fixture](../art/concepts/map/refinement-v2/symbols-1278.png), [Larger version](../art/concepts/map/refinement-v2/symbols-1278-larger.png), [actual generated floor](../art/concepts/map/refinement-v2/generated-1278.png). The symbol fixture is explicitly revealed for art review; it is not an invented live floor or a player save. Physical iPhone testing remains separate.

## Implemented · 2026-10-18

`scripts/minimap.gd` draws merged explored-floor regions on rough paper, with stable shared-vertex charcoal boundaries, restrained hatching against known walls and unfinished strokes at unknown frontiers. Unknown regions remain blank; changing unseen walls does not alter the sketch. Both views stay north-up and retain exact route centres, facing and discovery/triggered states. Geometry is cached until layout/discovery changes.

The full map adds at most three distinct observed event/way titles in a separate margin, further capped to available height at Larger UI size. Long titles shorten with an ellipsis. The Close button stays within the phone safe area. Existing mouse, touch and map-key/Escape closing remain. The original legend and separate empty-chest drawing have been superseded by the owner refinement above.

The original delivery reviewed sparse/complex maps, all facings, doors/blocked passages, used discoveries and unknown frontiers. Two Godot checkers passed 308 combined art/map checks. Historical previews: [first live map](../art/concepts/campaign-v1/map-facing-0-phone.png), [complex Larger map](../art/concepts/campaign-v1/map-complex-1278-larger.png); [delivery guide](campaign-art-pass.md). The owner has now reviewed that direction and requested the refinement above.

## Appearance

Use a practical expedition sheet: coarse dirty parchment, softly frayed edges, a few nicks/folds and rubbed corners. Concentrate damage around the border; keep the drawing area quiet and high-contrast. Avoid ornate treasure-map decoration or dense paper grain competing with the route.

Draw chamber contours and corridor edges in charcoal/sepia, with small irregularities, occasional doubled strokes and sparse exterior rock hatching. Hide the square cell grid and merge adjoining known floor tiles into continuous regions. Preserve right-angle routes and recognizable junctions. The caves can look organic in their outlines while the underlying movement remains on the same grid.

Amber marks the party, with a dark contour and an obvious facing point. Other information uses simple drawn symbols with distinct shapes and no separate legend. Colour can reinforce meaning but must not carry it alone.

| Information | Proposed drawing |
| --- | --- |
| Party and facing | Clear amber arrow, drawn over the charcoal lines |
| Ways up/down | Small ladder/step mark with a distinct up/down arrow |
| Rest spot | Bed symbol |
| Discovered chest | Chest sketch; the same chest with a red X once searched |
| Closed passage | Door symbol at the actual passage |
| Blocked passage | Rocks across the actual blocked cell |
| Known danger / strange object | Warning triangle / question mark |
| Unexplored territory | Blank paper; unfinished strokes only at a known exploration frontier |

The mockup illustrates five chambers and a few symbols, not a real seed or the complete icon set. Its large root drawing is an art-direction cue; production markers must sit at the actual blocked passage, not arbitrarily inside a room. Match the established content/discovery states when choosing icons.

## A trustworthy sketch

The human quality comes from the marks. Room connections, turn order, relative scale, position and facing remain reliable. Keep a consistent map orientation (currently north-up) in both views. No invented shortcuts, false junctions, random map errors from fear, or changing geometry while the player studies it.

Only show what the current game knows: explored cells, discovered contents, visible ways up/down and passage states. Keep used/cleared discoveries distinguishable from active ones, following existing triggered-state behaviour. A handwritten annotation such as “roots” or “way up” can reinforce an observed fact. Automatic note templates are a proposal; manual notes, mapping skills and personality-specific handwriting are not new mechanics required by this design. A sketch must not reveal hidden rooms or future encounters.

## Full map and corner map

Full screen: a broad sheet, large route drawing, floor title and clearly accessible Close control. Let unexplored areas remain blank. Notes should be sparse and separated from corridors. Use real interface text for notes rather than baking it into the background. Keep controls in the phone safe area with at least 44pt touch targets; the concept image's drawn button is not a final control specification. Preserve existing tap/map-key/Escape open-and-close behaviour.

Corner map: a small quiet parchment fragment with the same charcoal contours, party arrow and essential symbols. Omit marginal writing, heavy hatching and deep edge damage. Keep its existing tap-to-open action and party-following window. It must remain readable at the actual phone HUD size before adding texture.

## Implementation handoff

Retain `DungeonMap` and discovery data. Change the drawing layer in `scripts/minimap.gd`: derive boundaries from adjacent explored floor cells, merge shared edges, then apply small deterministic line variation. Use common vertices at junctions and a stable cell/edge seed so both views agree and the ink does not crawl between redraws. Keep variation much smaller than corridor width; do not move route centres or markers. Bound drawing to the current visible window and scale stroke/icon sizes for legibility.

Use one reusable subdued parchment texture behind lightweight line geometry; cache line points when layout/discovery changes. Do not generate a new painted map per floor. Keep phone-sized review captures of sparse/complex maps, adjacent parallel passages, all four facings, closed versus blocked passages, used markers and exploration frontiers. The title and controls remain separate crisp UI elements.

The raster study is concept art, excluded from Godot import via `.gdignore`; it is not a production background, accurate tile layout, finished minimap or phone validation. [Full generation prompt and provenance](../art/concepts/map/generation-manifest.json). Exact texture size, icon set, line jitter and annotation scope remain implementation choices for review.
