# Fortress structures and waterworks machinery

Built for Depths, #246, 2026-11-08. Source and tool hashes are in catalog.json.

The throne's underlying chair derives from the selected CC0 KayKit chair,
recorded under art/third-party/kaykit-fortress-v1. It is rotated, rescaled,
recoloured and gently warped, with authored backing, repairs and drapery.
All other geometry is authored with tools/fortress_waterworks/build_models.py
and the existing mine prop mesh helpers. No character or animation clip is used.
Editable per-piece Blender masters stay local in
build/local-fortress-waterworks-v1/masters. GLBs contain geometry and palette
UVs only, with no embedded source images, materials, skeletons or animation.

The existing fortress, cave-dressing, sluice and flow-gate paintings supply the
visual direction and mounting/state contracts. They are preserved. This is a
3D interpretation, not an automatic extrusion or a pixel-identical replacement.

Runtime scenes use one shared 26-colour nearest-sampled palette, roughness 1
and the earlier shared grain-floor1.png detail texture. That texture's record
remains in art/third-party/kaykit-dungeon-remastered/CREDITS.md. There are no
new world lights, emission, collision, occupants or gameplay state.
