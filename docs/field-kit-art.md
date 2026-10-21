# Field-kit inventory and boon/bane art

Completed for #138, in the owner's requested order: eight inventory items,
then eleven effect symbols. All nineteen resource bindings are connected.
The item and boon builders retain the new bindings on regeneration. No item
names, descriptions, prices, capacity values, effect values, durations or
other rules were changed.

Open `art/concepts/field-kit-v1/inspector.html` for native/display-size views,
greyscale and parchment checks, and ten actual Godot Pack/PartyCard captures.
`inventory-overview.png` and `symbol-overview.png` provide contact sheets.

## Inventory

Runtime art is in `art/items/field-kit-v1`. The 128×128 RGBA icons match the
current refined-v2 format: eight-pixel minimum padding, hard alpha and at most
64 colours per icon. Direct-source 64×64 exports in `compact64/` use a four-pixel
margin and at most 32 colours. Those are available for compact future UI;
current resources use the 128px versions. Neither export is enlarged from
another small icon.

| Resource | Illustration / distinct visual cue |
| --- | --- |
| `data/items/pick.tres` | Short miner's pick; pointed/chisel iron crossbar |
| `data/items/spade.tres` | Folding spade; broad nicked blade, hinge and D grip |
| `data/items/holy_water.tres` | Narrow cool glass phial, linen and blue binding |
| `data/items/antidote.tres` | Flat wax-paper packet, visible salts and sage thread |
| `data/gear/satchel.tres` | Low leather flap bag, broad strap and crude repair |
| `data/gear/frame_pack.tres` | Tall canvas bag on exposed timber rails |
| `data/gear/oilcloth_cloak.tres` | Long narrow hooded cloak, waxed dark folds |
| `data/gear/wool_cape.tres` | Broad shorter hoodless wool, thick rounded edges |

Neutral material shading and ordinary worn construction match the starter
library. Transparent areas remain clear, including the spade grip and satchel
strap. Holy water is distinct from the existing round red draught and leather
oil flask; antidote remains paper-wrapped salts, not another potion. No
unapproved religion/faction emblem was added to the bottle.

The catalogue records source bounds, direct scale, offsets, hashes, resource
paths and a hash of every nonvisual resource field before binding. The source
masters are immutable; exports only crop, reduce, quantize and set binary
alpha. Invisible RGB is zeroed in runtime exports.

## Eleven status symbols

The original native SVG drawings live in `art/source/field-kit-v1/glyphs`;
their 32×32 lossless PNGs are in `art/ui/boons-v2`. Existing generic
`boons-v1` marks remain available for effects without bespoke art. These
symbols are assigned through `Boon.icon`; PartyCard's existing code displays
them at 14px with nearest filtering and the current name/duration/effect
tooltip. No new HUD controller is needed.

| Resource / icon stem | Main shape |
| --- | --- |
| `miners_luck` / `miners-luck` | Pick and lucky strike |
| `quiet_heart` / `quiet-heart` | Heart with a level calm stroke |
| `lamp_blessing` / `lamp-blessing` | Sheltered lantern |
| `deep_eyes` / `deep-eyes` | Wide watchful eye |
| `blessed` | Upright blade with rays |
| `hearty` | Restoring bowl and fresh leaves |
| `blood_of_the_deep` / `blood-of-the-deep` | Red blood drop divided by a sharp cut |
| `withering` | Bent stem and dead leaves |
| `marked` | Eye inside four hunting points |
| `sickness` | Bent face with sick breath |
| `shaking_hands` / `shaking-hands` | Raised hand with tremor strokes |

A small round corner mark indicates the current boon category; a downward
triangle indicates a bane. The silhouette carries each effect's identity;
colour is secondary. Blood of the deep retains its mixed bargain identity
and the game's existing `bane=false` category. These are status symbols,
not new item or magic-system lore. The actual tooltip still explains the
benefit and cost. Greyscale 14px previews are provided; physical readability
and player recognition remain human review tasks.

## Sources and rebuilding

Eight original illustrations were created with the built-in ImageGen tool,
using the existing knife/jerkin as style references. Byte-exact copies,
original paths, reference roles, full prompts and SHA-256 hashes are retained
in `art/source/field-kit-v1/generation.json`. No fallback image API was used.
Source and review folders have `.gdignore`; the existing Windows export preset
already excludes `art/source/` and `tools/`.

```text
python tools/art/build_field_kit_art.py --wire
Godot --headless --path . --script res://tools/art/raster_field_glyphs.gd
```

Import through Godot 4.7.2 before running the UI review. The glyph rasterizer
uses Godot's SVG renderer at native 32px. No bitmap editing replaces the
generated illustrations. Resource wiring deliberately places the `icon`
property after the `script` property, so the exported field exists when
Godot reads it.

```text
python tools/art/validate_field_kit_art.py
Godot --path . --script res://tools/art/check_field_kit_art.gd
python tools/art/build_field_kit_review.py
node tools/art/check_field_kit_review.cjs
```

The two existing story builders were updated with art paths only:
`tools/story/build_back_gear.gd` and `tools/story/build_shrines.gd`. Do not run
older whole-library refined-v2 exporters to rebuild this batch; they have
historical resource-count/baseline assumptions. The field-kit catalogue is a
versioned sibling, leaving existing items and generic status art intact.

## Verification and handoff

- 183 independent checks pass for original/source hashes and prompts,
  128px/64px sizes, palettes, padding, alpha, non-duplicate compact symbol
  shapes, all resource bindings and unchanged nonvisual fields.
- 89 Godot checks pass in the real Pack and PartyCard components: each item
  texture is present; every specific status texture is used at 14px with
  nearest filtering and its named tooltip. Ten actual captures cover desktop
  1280×720 and phone-shaped 1278×590 views.
- 25 browser checks pass for the eight/eleven assets, tabs, greyscale and
  parchment modes, loaded game captures, and no horizontal overflow at
  1280×720 and 844×390. Final import/render logs are clean.
- Texture canvases total 700,416 bytes (about 0.67 MiB RGBA before overhead),
  including compact exports. No animation or new rendering effect is added.

The fixture instantiates existing controls without Main, events or saves.
Captures record the active worktree UI, including Claude's concurrent item
quality treatment; this art commit does not own that interface work. Phone
dimensions are simulated on Windows, not a physical iPhone usability test.
No new boon/bane rules, item interactions, trinket art or event props belong
to this batch.
