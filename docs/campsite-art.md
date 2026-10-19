# Cave campsite artwork · v1

Owner feedback 2026-10-18 led to the [connected-camp composition study (#108)](camp-composition-v2.md), followed by the [layered live camp](layered-camp.md): independent terrain/sites, story-presence hooks and animated local light. That implementation supersedes these original coordinates in the live screen while preserving service IDs and rules. The v1 assets remain available for reference and original NPC portraits.

Artwork task [#78](https://github.com/jonathanvarro/Depths/issues/78),
for Claude's [#40 campsite](https://github.com/jonathanvarro/Depths/issues/40).
Ten new native textures cover the empty clearing, six destination layers
and three starter NPC portraits. The fire reuses the existing #63 flame
resource. The live campsite and service rules are separate implementation work.

## Story and visual direction

The owner established that the king is sending forces to deal with the
monsters and goblins, but something went wrong: arrivals are scattered and
disorganized. This explains shortages and the apprentice's makeshift tool
supply. The cause of the disruption, military leadership, kingdom name and
the smith's exact means of acquiring tools remain open.

Patched campaign canvas, civilian boxes, mismatched poles and a sparse tool
rack suggest a force still trying to assemble. Faded blue cloth with a
simple ochre crown is a **proposed visual shorthand**, not finalized royal
heraldry. A single treatment cot and repeatedly mended linen make scarcity
visible while the nurse keeps her working area orderly.

The merchant's stall is modest but more organized than the rest of camp.
His approved identity remains: markedly obese starter build, crooked
dark-red cap/coin pin, forked moustache, calculating smile and gold tooth.
There are no starter necklaces or finger rings. Later location-by-location
growth and wealth remain in docs/merchant-design.md; this delivers only
the first-site portrait.

The apprentice and nurse appearances are first proposals: a tired young
adult village apprentice with patched leather apron and hammer, and a
practical middle-aged nurse with headcloth, washed apron and dressing.
No character names, new backstory outcomes or gameplay advantages are set.

## Files Claude can use

Runtime directory: `res://art/camp/cave-camp-v1/`.

| Stable destination ID | Layer / scene | Portrait | Visual cue |
| --- | --- | --- | --- |
| supplies | supplies.png / supplies.tscn | merchant.png | Patched red awning, counter and provisions |
| treatment | treatment.png / treatment.tscn | nurse.png | Pale tent, cot, basin and linen |
| cave | cave.png / cave.tscn | — | Opaque dark rock entrance and trail post |
| rest | rest.png / rest.tscn | — | Low personal tent, chest and bedroll |
| smith | smith.png / smith.tscn | apprentice.png | Canvas lean-to, small anvil, few tools and cold portable brazier |
| fire | fire.png / fire.tscn | — | Stone hearth, two sitting logs and kettle; separate live flames |

The clearing texture is `clearing.png`. NPCs are separate from every site,
so an unstaffed site or a service portrait can be selected independently.
The village apprentice remains a beginner: the drawn tools/stock are visual
clues, not new inventory grants, crafting or durability mechanics.

Each site scene is a Node2D with a nearest-filtered Base Sprite2D. Root is
the ground contact; Base is at (-128,-184), with centered=false. Instance
under a Control/Node2D art layer, position the root, and scale the complete
scene uniformly. This is fixed-view 2D refuge art, not a first-person cave
billboard. The cave mouth's black interior is opaque.

## Six-site composition and availability

[layout.json](../art/camp/cave-camp-v1/layout.json) provides an artist's
640 × 360 composition with the six existing stable IDs, explicit independent
target rectangles, scale and portrait mapping. Merchant/nurse/cave are
behind; tent/smith/fire sit in front. This recomposes the old five-area
study to make room for the smith.

The independent layers let #79/#80 show or hide sites as arrivals happen.
**The art review shows all six for inspection; it does not set their opening
days, arrival order, stock improvement or secured-route rules.** Follow the
live camp model's availability. If a site is absent, disable/hide its input
target as well as its drawing; do not let an invisible button open it.

Claude's current six camp anchors and safe-area handling take precedence
during #40 integration. These rectangles are supplied for review and may
be mapped to those anchors without repainting the background or NPCs.
Do not replace camp.gd/Main, rewire services, or copy preview state into
campaign data merely to display these assets.

The newer **Decided 2026-10-17 (#40)** block in DESIGN.md is authoritative
over older cost/recovery proposals in docs/campsite-design.md. Art adds no
rest costs, treatment duration, stock, recruitment availability or cave
regeneration rules.

## Isolated interactive art review

Open `art/camp/cave-camp-v1/preview.tscn` in Godot and press F6.
Hover/focus highlights each persistent area label; click, Enter or a
single touch opens the site/portrait review. Back/Escape closes it and
restores focus. The activity view displays art only, with no service
actions, inventory, prices, clock or party simulation.

This is an isolated art review, not the live camp screen. Its simulated
phone margins are for inspection; integration should use the real SafeArea
helper and existing camp input rules. Labels and headings remain live text,
using the existing Source Sans 3 and Cinzel SemiBold fonts with their
original OFL notices. Text is not baked into artwork.

## Native size, lighting and animation

- Six site bases: **256 × 192 RGBA**, binary alpha, at most **40 colours
  each**, common floor contact **(128,184)**.
- NPCs: **192 × 192 RGBA**, binary alpha, at most **48 colours each**,
  complete static portraits inset into the full canvas, bottom contact
  **(96,188)**. They are not blink/talk/component masters or replacements
  for the existing companion PortraitSet resources.
- Clearing: **640 × 360**, opaque, at most **48 colours**.
- All new imports: lossless, no mipmaps, nearest display. Ten new textures
  total **2,543,616 uncompressed RGBA bytes (about 2.43 MiB)** before
  renderer overhead; the existing flame texture is shared.

Character art was generated under neutral diffuse fill, with local form
and clothing occlusion rather than a specific orange lantern or rim.
The first-site portraits are static neutral character plates; no authored
directional shadow/highlight masks or expression layers are included.
Keep future incident illumination separate under
[the portrait-lighting contract](portrait-lighting.md). A global tint alone
is not a full directional relighting system.

Only fire.tscn adds animation. Its FlameAnchor is at (0,-22) relative to
the ground root, scale 0.48; it reuses
`art/features/campfire-v1/frames.tres` without a new flame atlas.
All six source flame roots remain (64,102). The static base never moves.
The loop runs at 8 fps, pauses while hidden, and resumes when shown.
Set `animate_flames=false` for a static frame. No light or particles are
added; any camp light treatment belongs in a separate presentation layer.

## Sources, rebuild and verification

Built-in **image_gen.imagegen** produced the ten original masters.
[Exact prompts, source roles and original paths](../art/source/campsite-v1/generation-manifest.json)
are preserved with all masters. Merchant v2 and the campfire master are
references, unchanged. Source/review folders are ignored by Godot import;
the existing Windows export excludes art/source and tools.

Run `tools/art/build_campsite_art.py` with Pillow to reproduce the native
exports, [site board](../art/concepts/campsite-v1/sites.png) and
[NPC board](../art/concepts/campsite-v1/npcs.png). It performs alpha-bound
fitting, nearest resizing, binary alpha at threshold 96 and visible-pixel
palette reduction without dithering. It does not paint replacement art.
[asset-validation.json](../art/concepts/campsite-v1/asset-validation.json)
records canvases, bounds, registration, palettes and SHA-256 hashes.

Godot 4.7.2 Mobile/D3D12 imported all ten textures without warnings/errors.
`tools/art/check_campsite_art.gd -- --capture` checks resource sizes/pivots,
flame reuse/playback/visibility/motion control, target size/separation/safe
bounds, real mouse/touch/keyboard opening, Escape and focus restoration.
The [report](../art/concepts/campsite-v1/godot-validation.json) records
**217 passing checks and 15 captures**, including clearing, focus and each
NPC service art view at **1280 × 720, 1278 × 590 and 1334 × 750**.

These are simulated landscape-phone views on Windows. Physical iPhone
testing and live camp integration remain with #40 and the related service
tasks; this artwork does not close them.
