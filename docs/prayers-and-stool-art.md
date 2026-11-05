# Prayers and a camp stool

The #216 batch supplies three distinct prayer tomes, an unlit votive candle,
four prayer marks and a separate Bound status mark. The fixed wooden stool
provides #218's requested physical seat reference for the current chair clips.

## Prayer assets

The four items in art/items/prayers-v1 have native 128 × 128 and compact
64 × 64 exports. Each has hard alpha, at most 64 visible colours and a
consistent 7/8-canvas footprint. Original generated masters and their exact
prompts/provenance are in art/source/prayers-v1. Rebuild the exports with
tools/art/export_prayer_icons.py.

| Existing item resource | Item filename |
|---|---|
| data/items/tome_light.tres | tome_light.png |
| data/items/tome_bind.tres | tome_bind.png |
| data/items/tome_watch.tres | tome_watch.png |
| data/items/votive_candle.tres | votive_candle.png |

The compact siblings add -64 before .png. The sun, iron chain and pale eye
distinguish the books at phone size. The candle is a spent-looking tallow
stub in a battered iron holder.

The original 32 px SVG marks in art/ui/prayers-v1 map spell IDs mend, light,
bind and watch to mend.svg, holy-light.svg, bind.svg and watchful-eye.svg.
bound.svg is the paired-cuffs status mark for a foe held by Bind. These use
the existing warm parchment UI colour and strong silhouettes for 16–32 px
display. Claude's combat/Pack hookup can use these paths directly.

The item IDs, effects, text, casts, numbers and existing spell library are
caller-owned. This batch is the four-prayer brief in #216. Discern was added
later and can receive its own tome and mark in a follow-up art request.

## Wooden stool

art/dressing/camp-stool-v1/stool.tscn instances a 142-triangle, single-material
adaptation of Kenney's CC0 stoolBarSquare model. It measures 0.40 m wide,
0.32 m deep and 0.43 m high. The floor-centred origin makes it reusable in
camp scenes. Source, licence and edits are recorded alongside the unchanged
OBJ/MTL in art/third-party/kenney-furniture-v1.

tools/stool_review/prepare_review.py --workspace E:/GitHub/Depths creates the
private local-stool-review-v1 project from the checked padded-jacket-v2
snapshot. START_REVIEW.cmd opens both bodies with a stool during the aligned
chair sequence. The stool's horizontal anchor is chosen once from the seated
hips, and the same fixed 43 cm height is used for both bodies. Its position,
scale and floor reference stay fixed throughout sit-down, hold and stand-up.
The current garment and source animation determine the visible contact.

The fixed seat reveals clothing/seat overlap through parts of the sequence.
#218 retains the final contact and animation acceptance work. The stool makes
that review possible and supplies a reusable prop. Source and derived
character models and the captures stay in ignored local build output.

## Review and checks

The combined local gallery is build/prayer-stool-review-v1/inspector.html.
It contains native item and symbol captures, small-size exports, and actual
stool-reference views. The character preview is generated locally from
existing private model files.

The prayer check loads every native/compact item and rasterized SVG in Godot's
Mobile renderer. The stool check verifies two same-size floor-mounted seats,
fixed transforms during the sequence and visibility outside the chair review.
The gallery checks cover local image loads and phone-width overflow. Renderer
logs and reports are copied into the gallery.
