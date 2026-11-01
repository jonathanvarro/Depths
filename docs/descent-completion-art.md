# Descent library completion — #166 / #167 / #168 / #178 / #190

[Interactive review](../art/concepts/descent-completion-v1/inspector.html).
The selected Overlook now has a [separated production library and native interaction review](overlook-production-art.md).
This is a standalone artwork delivery, ready for selection and Claude's hookup.
The Overlook composition was selected by the owner on 2026-10-31; its production
layers are delivered in the linked follow-up. Named companion portraits (#181) are excluded from this batch.
No live scene, item, theme, quest, save, flood or knowledge rules are changed.

## Black Reservoir

`art/textures/reservoir-v1` supplies matched wall, floor and ceiling PNGs and
StandardMaterial3D resources. All are opaque native128, nearest sampled, with one
shared 32-colour slate palette, roughness 1 and no emission/normal maps. The wall
has an irregular waterline; repeat it horizontally, retaining its vertical
orientation. Floor and ceiling repeat on both axes. Four-pixel edge registration
at export makes opposing edges identical; the gallery includes 3×3 tile checks.
Use full-face wall UVs rather than the default BoxMesh atlas. Add them to a new
theme when the floor is connected; existing theme assets remain intact.

`art/props/reservoir-finish-v1` contains two fixed, shaded Sprite3D scenes:

| Scene | Canvas / registration | Intended use |
|---|---|---|
| `water-edge.tscn` | Opaque256×128; 2m wide, 1m high, centre y=0.5 | Wall inset showing a worn lip over distant black water |
| `stairs.tscn` | Native192, hard exterior alpha, full canvas 2m; opaque bounds grounded at y=0 | Wet black stairs and an opaque dark aperture |

Both face local +Z and require a real wall anchor and caller rotation. The stairs'
sprite position compensates only for its transparent bottom margin. Keep that
transform intact. The water inset is static and opaque; it does not create a
walkable void, reflection pass or collision surface. Existing water surfaces
and their still-compatible shader are in `docs/drowned-water-and-sluice.md`.
Preserve dry ledges, flood/diversion flags, drained restoration and the current
stair/ending transition. Showing these stairs does not unlock floor 7. The
existing flow gate and ancient stonework deliveries remain separate resources.

## Story illustrations

All are RGB PNGs in `art/illustrations/descent-v1`:

| File | Pixels | Hook / composition |
|---|---|---|
| `vision.png` | 1280×720 | `Conversation.vision`; geological folds suggest a sleeping scale without showing a whole being |
| `reservoir-ending.png` | 640×360 | Slice-2 ending, reservoir low and an immense curve far below |
| `lower-gate-card.png` | 640×360 | `results.show_brief(..., illustration)` at first sight of the lower gate |
| `galleries-drained-card.png` | 640×360 | Same API after the galleries drain; exposed black steps and old sluices |
| `by-the-fire.png` | 640×360 | `Conversation.backdrop`; low fire to the right and quiet lower-left portrait space |

The cards match the existing fortress illustration contract. The gallery includes
an actual `vision_filter.gd` capture at strength 1 / shimmer 0. Let the existing
conversation presentation own tint, timing, text and effects preferences. These
paintings do not establish an additional creature identity or lore.

## Unknown brews

`art/items/brews-v1` contains six independent native64 glass shapes (squat, tall,
flask, vial, gourd, cracked jar), six cavity masks and `catalog.json`. Glass uses
12 visible colours, hard alpha and at least four pixels of transparent padding.
The compositor supplies six muted liquid colours and six wax/cork marks: eye,
tooth, spiral, hand, moon and geometric cross. Shape and mark provide independent
non-colour cues; the review includes 64/32px, parchment and greyscale modes.

```gdscript
const BrewArt = preload("res://art/items/brews-v1/compose.gd")
var image: Image = BrewArt.compose("flask", 2, "tooth")
var known: Image = BrewArt.compose("flask", 2, "tooth", "restorative")
var icon := ImageTexture.create_from_image(known)
```

This presentation helper loads imported Texture2D resources (export-compatible),
tints the glass cavity, applies the registered stopper stamp, then optionally
adds an identified paper label. All 216 unknown appearances are distinct and
stay within 32 visible colours. The atlas in the review is produced by this
Godot compositor. Labels are independent symbols for restorative, caustic,
slumber, frenzy and revealing; only pass a kind after identification. The game
controller owns expedition mapping, random seed, saved identity, discovery and
actual use. Cache composed textures per appearance in the eventual UI; avoid
recomposing them every frame. Appearance has no built-in effect mapping.

`art/ui/expedition-v1/splash/frames.tres` is a six-frame, non-looping `shatter`
animation at 12fps (0.5 seconds), native64 and tintable. Keep it a short UI/combat
effect; with effects disabled, omit it or hold frame 2. It adds no attack logic.

## Journal, mastery, combat and map symbols

`art/ui/expedition-v1/catalog.json` lists 28 native32 SVG/PNG symbols; the gallery
checks them at 32 and 20 pixels:

- Eight journal marks: fire, Flare, reach, thrown torch, brace, poison, immune
  and weak-to. The latter two are overlay frames; reduce the inner mark to
  about 14px inside a 20px frame. Use an ink modulation on parchment and pale
  neutral modulation on dark UI. Preserve text/accessibility descriptions.
- Three mastery stages (one notch, two notches, full) plus the smith improvement
  glyph. Place mastery in an icon corner with a small dark backing, preserving
  the item silhouette and existing quality border; do not bake rolled stats or
  quality tiers into it.
- Long-lunge and birthing intentions, off-balance status and tastes-blood tag.
  Let existing combat state control when they appear, alongside elite marks.
- A three-wave deep-water map glyph. Recolour to the existing parchment ink;
  use only for discovered water cells, retaining explored/unknown rules.
- Six stopper marks and five identification labels described above.

`journal-frame.svg` is a separate transparent768×432 page guide, used over
the unchanged `art/ui/map-v1/parchment.png`. It gives a title line, thumbnail
window, observation lines and lower notes. The 26 native64 PNG silhouettes in
`thumbnails/` are derived from actual current EnemyType idle artwork. Their
catalogue records each source scene and texture; it intentionally includes
tutorial/variant entries sharing an enemy silhouette. The controller chooses
which entries are listed, keeps unencountered entries dark, and replaces or
reveals detail only after meeting a monster. Do not invent weaknesses or expose
undiscovered facts from the illustration catalogue.

## Overlook — selected composition, 2026-10-31

`art/concepts/descent-completion-v1/overlook-concept.png` is a 1600×900 bird's-eye
study of a continuous sheltered ledge above a distant goblin hold. Fire,
supply/stash, survey table and both paths belong to the same terrain. The
gallery can outline proposed targets; `overlook-layout.json` records normalized
anchors, future layers and discovered/provisioned/connected state intentions.

The owner confirmed that this composition "perfectly captures what I was thinking".
It is the selected reference for a small, earned refuge after beating a major
theme area: time to absorb the victory, take in story, access the stash and
glimpse the next zone. Present companions should inhabit the area through quiet
activities: sharpening swords, warming by the fire, reading a book, strategizing
or relaxing. Keep figures subordinate to the intimate camp and enormous vista;
only current party members should appear. These are characterization activities,
not new item wear/repair, stat bonuses, time costs or automatic recovery rules.

`overlook-approval.json` pins the unchanged source and selected export hashes.
The current painting depicts the provisioned composition. It is not separated
terrain/site artwork and cannot yet hide individual sites. Preserve this selected
layout while authoring a clean landscape, independent site/occupant/foreground
layers and optional local glow, registered together. Keep the refuge coherent
without people, supplies or services. No NPC roster, shop, free treatment,
travel costs or deeper camp count is assigned. Underground arrival preserves
expedition levels; surface-return rules remain separate (#172/#189).

## Sources, rebuild and review limits

Seventeen built-in ImageGen masters, exact prompts, original output locations,
source/export hashes and registrations are retained in
`art/source/descent-completion-v1/generation.json`. There were no supplied
character/reference uploads for this batch. Rough stone, uneven glass and
modest worn construction follow the owner's handworked direction. Native
symbols/frame are editable SVG. Original project artwork is unchanged.

1. `python -B tools/art/build_descent_completion.py` mechanically exports the
   masters, registers repeating edges, reduces palettes and writes native SVG.
2. Import assets with Godot 4.7.2, then run
   `--headless --path . --script tools/art/check_descent_completion.gd`.
   This also rasterizes glyphs, composes the brew atlas and derives silhouettes.
3. Run that fixture with the Mobile renderer for six actual desktop/phone world
   views and the still vision-filter view. It is an isolated SceneTree and
   never opens Main or reads player saves/settings. Run hidden/off-screen.
4. `python -B tools/art/build_descent_review.py` builds the local gallery;
   `node tools/art/check_descent_review.cjs` checks its controls and framing.

Validation records accompany the gallery. Source exports pass 69 checks;
Godot passes 810 headless checks and 817 checks including seven real captures.
Browser review passes 155 checks across desktop and landscape-phone widths; physical iPhone
review and live gameplay integration remain separate.

The optional deep smith material and dedicated floor-4 gate-stair variant were
not drawn. #167's audio work remains outstanding. #190's composition is selected;
production separation is delivered separately in `docs/overlook-production-art.md`, with live hookup outstanding;
the other libraries await owner review and live hookup. #181 named companion
portraits remain deferred for the owner's research.
