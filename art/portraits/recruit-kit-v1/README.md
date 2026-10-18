# Recruit portrait kit · v1

Two distinct heads share body.png and jerkin.png from shared/. Full
contract, paths, sources and checks: [recruit-portrait-kit.md](../../../docs/recruit-portrait-kit.md).

catalog.json maps warden-a/scout-a to neutral PortraitSet resources, flat
fallbacks and separate upper-left light masks. All layers are 192 × 192;
keep origin (0,0), full canvases and one common display scale.

Neutral resources blink and talk in the existing PortraitView. Worried/
exhausted resources are static with no animation arrays. Conditions:
blood, dirt, bandage, pallor. The optional lit_portrait_view.gd adds
neutral/warm/dim authored light presets above character and conditions.
This does not migrate Mara or change the existing portrait renderer.

F6 on preview.tscn opens the isolated 192px/96px review. It has no
recruitment, stats or campaign logic. Shared body/outfit reuse is checked
by resource identity, with 424 Godot checks and 24 captures.

Artwork #84; two-face first pass toward #82. More faces and Brawler remain.
