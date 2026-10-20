# Textured portrait drawings · #124

Native pixel refinements of the existing twelve faces, following the owner's preference for precise edits. No generated redraw. Original resting faces, v3 clean plates, neutral layers and component mattes are immutable references.

`tools/art/refine_portrait_drawings.py --wire` fits each original lip seam and tissue around a smaller shaded cavity, with subdued tooth hints and local lower-lip motion. Rounded gestures contract the painted lips without replacing them with a black O. Integer sampling preserves the original skin/beard texture. Corin retains his tooth gap. Eyelids use individually fitted curved tapered lashes, soft creases and native skin colours; the half drawing keeps actual lower iris pixels. Corin's far lash ends at x128, before the cheek turns away.

Each face folder records contours and authored shape count, exact visible-iris/lash masks and mouth opening/tissue-motion masks. These are authoring aids inside the unchanged full v3 mattes, not new canvas registration. All output colours come from that face's original palette. Runtime exports live in `frames-pixel-v4/`; the three unique heroes keep three talking shapes, recruits keep their two real shapes and the existing timing sequence.

[Manifest and review](../../concepts/portrait-drawings-v4/README.md) · [handoff](../../../docs/portrait-rig-families.md). Static expressions and flat NPC portraits are unchanged.
