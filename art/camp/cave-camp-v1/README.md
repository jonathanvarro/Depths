# Cave campsite art · v1

Six transparent site layers/scenes, three neutral static NPC portraits and
one empty clearing background. Full integration contract, story direction,
sources and checks: [campsite-art.md](../../../docs/campsite-art.md).

Site canvases: 256 × 192, <=40 colours, ground pivot (128,184).
NPC canvases: 192 × 192, <=48 colours; static service art, not animated
PortraitSet layers. Background: 640 × 360, opaque, <=48 colours.
Nearest display, lossless imports, no mipmaps.

Each site scene is a ground-origin Node2D. fire.tscn reuses the existing
campfire-v1 flame frames, with separately registered animation and a
static base. It pauses when hidden; animate_flames=false holds frame 0.

preview.tscn is an isolated six-site art/input review. F6 to inspect.
It has no campaign, clock, inventory or service actions. layout.json is
an artist's composition; map it to the current live camp anchors.
Gate art and input together when the camp model marks a site unavailable.
Arrival timing remains #79/#80. Artwork #78; implementation #40.
