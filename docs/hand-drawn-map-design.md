# A map drawn by the party

The owner requested rougher paper and a map that feels hand-drawn by the heroes rather than a perfect visible grid (#34). [Visual study](../art/concepts/map/hero-map-v1.png). This records that direction and proposes its presentation; it does not change the current map renderer or navigation rules.

## Appearance

Use a practical expedition sheet: coarse dirty parchment, softly frayed edges, a few nicks/folds and rubbed corners. Concentrate damage around the border; keep the drawing area quiet and high-contrast. Avoid ornate treasure-map decoration or dense paper grain competing with the route.

Draw chamber contours and corridor edges in charcoal/sepia, with small irregularities, occasional doubled strokes and sparse exterior rock hatching. Hide the square cell grid and merge adjoining known floor tiles into continuous regions. Preserve right-angle routes and recognizable junctions. The caves can look organic in their outlines while the underlying movement remains on the same grid.

Amber marks the party, with a dark contour and an obvious facing point. Other information uses simple drawn symbols with distinct shapes, supported by a short legend. Colour can reinforce meaning but must not carry it alone.

| Information | Proposed drawing |
| --- | --- |
| Party and facing | Clear amber arrow, drawn over the charcoal lines |
| Ways up/down | Small ladder/step mark with a distinct up/down arrow |
| Rest spot | Bedroll sketch |
| Discovered chest | Simple box/open-lid sketch; used state subdued but legible |
| Closed passage | Cross-bar across the actual passage, retaining a different shape from a blocked passage |
| Blocked passage | Crossed root/barrier mark at the actual blocked cell |
| Known danger / strange object | Distinct warning/object symbols; exact icon drawings to review |
| Unexplored territory | Blank paper; unfinished strokes only at a known exploration frontier |

The mockup illustrates five chambers and a few symbols, not a real seed or the complete icon set. Its large root drawing is an art-direction cue; production markers must sit at the actual blocked passage, not arbitrarily inside a room. Match the established content/discovery states when choosing icons.

## A trustworthy sketch

The human quality comes from the marks. Room connections, turn order, relative scale, position and facing remain reliable. Keep a consistent map orientation (currently north-up) in both views. No invented shortcuts, false junctions, random map errors from fear, or changing geometry while the player studies it.

Only show what the current game knows: explored cells, discovered contents, visible ways up/down and passage states. Keep used/cleared discoveries distinguishable from active ones, following existing triggered-state behaviour. A handwritten annotation such as “roots” or “way up” can reinforce an observed fact. Automatic note templates are a proposal; manual notes, mapping skills and personality-specific handwriting are not new mechanics required by this design. A sketch must not reveal hidden rooms or future encounters.

## Full map and corner map

Full screen: a broad sheet, large route drawing, floor title, short symbol legend and a clearly accessible Close control. Let unexplored areas remain blank. Handwritten notes should be sparse and separated from corridors. Use real interface text for labels and legend rather than baking them into a background image. Keep controls in the phone safe area with at least 44pt touch targets; the concept image's drawn button is not a final control specification. Preserve existing tap/map-key/Escape open-and-close behaviour.

Corner map: a small quiet parchment fragment with the same charcoal contours, party arrow and essential symbols. Omit marginal writing, heavy hatching and deep edge damage. Keep its existing tap-to-open action and party-following window. It must remain readable at the actual phone HUD size before adding texture.

## Implementation handoff

Retain `DungeonMap` and discovery data. Change the drawing layer in `scripts/minimap.gd`: derive boundaries from adjacent explored floor cells, merge shared edges, then apply small deterministic line variation. Use common vertices at junctions and a stable cell/edge seed so both views agree and the ink does not crawl between redraws. Keep variation much smaller than corridor width; do not move route centres or markers. Bound drawing to the current visible window and scale stroke/icon sizes for legibility.

Use one reusable subdued parchment texture behind lightweight line geometry; cache line points when layout/discovery changes. Do not generate a new painted map per floor. Add phone-sized review captures of sparse/complex maps, adjacent parallel passages, all four facings, closed versus blocked passages, used markers and exploration frontiers before replacing the live renderer. The title, legend and controls remain separate crisp UI elements.

The raster study is concept art, excluded from Godot import via `.gdignore`; it is not a production background, accurate tile layout, finished minimap or phone validation. [Full generation prompt and provenance](../art/concepts/map/generation-manifest.json). Exact texture size, icon set, line jitter and annotation scope remain implementation choices for review.
