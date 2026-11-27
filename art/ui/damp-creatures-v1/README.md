# Damp Caves creature contours

Original code-native SVGs, matching the four approved creature families. Each
has a 32px map glyph and 128px bestiary contour with a common 128-unit drawing
space. No raster concept pixels were edited or traced by image-processing code.

`tools/damp_caves/prepare_creatures.py` regenerates these. Native review renders
the contours at 16/24/32/64px; they are unassigned assets, not additional live
map discoveries or bestiary facts. Caller still owns discovery and named-pack
map tint. See the creature catalogue for exact symbol URIs.
