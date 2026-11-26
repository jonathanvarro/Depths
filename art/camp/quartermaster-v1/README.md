# Quartermaster Garran (#296)

Original static camp-service illustrations generated with the built-in OpenAI image tool on 2026-11-25. Exact prompts and output provenance/hashes are retained beside the PNGs in `generation-manifest.json`. No external stock or private body/face sources are used. The existing merchant painting was a style-only reference for the station; Garran has his own generated face, clothes and proportions.

The unchanged RGBA originals are `portrait.png` (1145×1374) and `station.png` (1132×1390). Godot imports are limited to 1024 and 512 respectively. Portrait is used directly in `QuartermasterScreen`; its compact header crops the same texture with AtlasTexture. CampScreen places the complete grounded station at the existing cave site, sharing that site's highlight.

This is a static non-recruitable service NPC, with no facial rig, companion definition, animation or new save identity. Dialogue lives in `scripts/quartermaster_screen.gd`. See `docs/quartermaster-character-and-planning.md` for live authority and review.
