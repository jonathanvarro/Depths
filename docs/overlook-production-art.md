# Overlook production layers — #190

[Interactive production review](../art/concepts/overlook-v1/inspector.html) ·
[Actual desktop scene](../art/concepts/overlook-v1/provisioned-1280.png) ·
[Phone focus check](../art/concepts/overlook-v1/focused-stash-1278.png).

The owner selected the composition on 2026-10-31 and authorized all five next
steps: clean landscape, separate camp objects, existing-companion activities,
restrained effects/still mode, and phone interaction review. This delivers the
standalone asset set and native scene. Live camp/story/stash/travel integration
remains separate; the current surface camp and gameplay scripts are unchanged.

## Files and registration

Runtime library: `res://art/camp/overlook-v1/scene.tscn`.
`layout.json` contains the shared1600×900 coordinate system, source-independent
layer rectangles, z order, state presence and five target rectangles. Artwork
keeps the approved mine entrance, ledge, two paths and distant fortress layout.
The selected original and its approval hashes are unchanged. This is a matched
production derivative, not a claim that generated cutouts are identical pixels
to the approved painting.

| Layer | Contents |
|---|---|
| `terrain.png` | Opaque1600×900 bare rock, paths, cavern and distant hold; foreground camp furnishings and their firelight pool removed |
| `sites/shelter` | Ragged canopy, crooked poles, bedding and its small barrels/bin |
| `sites/stash` | Two open timber chests with worn ironwork |
| `sites/survey` | Uneven table, parchment, cups, stool and two small boxes |
| `sites/firepit` | Unlit stone ring, charred logs and four sitting stones |
| `sites/supplies` | Small firewood crate and spare planks |
| `sites/lantern` | Modest sooted iron lamp; steady wick is part of its art, external glow separate |
| `fx/flame.png` | Independent flame, with a small shader deformation |
| `companions/` | Five static full-body activities, detailed below |

Each site has an independent PNG and fixed Sprite2D scene. PNGs use twice the
logical footprint with four native pixels of transparent padding. Source alpha
is preserved, including soft edges; invisible RGB is cleared before export to
prevent filter fringes. The exporter records source bounds, scale, canvas and
placement for each. No whole1600×900 transparent texture per prop is needed.

The native foreground Polygon2D samples the exact registered terrain texture
with matching vertex/UV coordinates, putting the ledge rim above occupants.
This adds an independent occlusion layer without a second landscape texture or
another generated redraw. The background retains the existing route ropes and
small mine/path lights as geography. Provisioning adds camp supplies and an
extra sheltered lamp; it does not redraw those routes.

## Companions and activities

| Activity ID | Existing visual identity | Activity / placement dependency |
|---|---|---|
| `mara-warming` | Mara | Seated at left fire stone, palms toward the flame; requires a lit firepit |
| `corin-equipment` | Corin | Seated at the right, checking a travel pack's straps; requires firepit |
| `alwen-reading` | Alwen | Reading a small book on the survey stool; requires survey site |
| `fixer-planning` | Approved Fixer-a recruit design | Leaning toward the survey map, burgundy coat/ochre waistcoat; requires survey site |
| `mara-relaxing` | Mara | Reclining at the bed edge; requires shelter |

These are camp body drawings, not new portrait rigs or story identities. The
generator references were project-generated hero/recruit artwork and the approved
camp/crops. No supplied private/local-only character reference was uploaded.
Named companion portrait tasks, including the newer roster briefs, are separate.
Fixer-a is a visual ID, not a named recruit or guaranteed camp resident.

The image service rejected the sword-sharpening output as violence (request ID
`7ce6892b-2b40-4c49-9d5f-bdb066663afa`). That drawing is not delivered; Corin's
quiet pack-checking activity substitutes for equipment tending. Both exact
requests and the rejection are retained in the source ledger. No combat, wear,
repair upkeep, buffs, recovery or activity-time rules are introduced.

Only provide appearances for the actual current party. The scene starts with no
occupants, rejects more than three, unsupported IDs and duplicate identities
(including both Mara activities together), and leaves the previous selection
intact on invalid input. Unknown/unrepresented appearances remain absent; do
not substitute a different hero or Fixer face. Other recruit body variants can
be authored later. Occupants whose required furniture is absent are hidden.

## Native scene API

```gdscript
const SafeArea = preload("res://scripts/safe_area.gd")
var view = preload("res://art/camp/overlook-v1/scene.tscn").instantiate()
add_child(view)
view.set_safe_area(SafeArea.insets(get_viewport()))
view.set_text_scale(1.3) # Or the caller's current UI preference.
view.refuge_state = "connected" # discovered / provisioned / connected
view.animate_lights = false # Caller supplies still/reduced-effects preference.
view.fire_burning = true
view.set_site_present("stash", true)
view.set_occupants(present_party_activity_ids) # Explicit current-party mapping.
view.target_activated.connect(on_overlook_target)
```

The caller maps `mine`, `onward`, `stash`, `fire`, and `survey` to the existing
travel, stash, dialogue and route/story presentation. Signals only report the
selection. They do not authorize a route, open storage, trigger a conversation,
change inventory, reset an expedition or spend time. Validate actual story
availability, storage access, route unlock/cost and recovery rules in the model.
Underground arrival preserves the expedition; surface-return boundaries stay
as recorded in #172/#189. This delivery adds no shops or treatment service.

Discovered is bare, with only both route targets. Provisioned adds shelter,
stash, firepit and survey table; connected adds the wood supplies and lamp.
These are presentation states supplied by a caller, not automatic unlock rules.
`set_site_present(id, false)` hides that site, its interaction and dependent
occupants/effects. A cold fire keeps its ring and conversation anchor but has
no flame/light pool. Surface-camp service timing remains unchanged.

## Motion, input and phone checks

All effects use an explicit phase uniform; shaders have no implicit `TIME`.
Fire sways slightly, local fire/lamp/path glow varies by a few percent, and a
reused authored fog-bank texture drifts slowly over the distant vista. They
add no particles, shadows, 3D lights or gameplay randomness. Still mode resets
phase to zero and stops processing. Hidden scenes stop processing as well.
Steady flames/lamp art and the painted distant lights remain visible in still
mode. Ordinary companion activities are static poses.

Art fits within the supplied safe rectangle without cropping. Five transparent
targets sit over their real objects/routes; each keeps at least44 UI pixels in
each dimension and never overlaps its neighbours in the checked phone profiles.
Normal view has no permanent floating labels/buttons. Hover or keyboard focus
shows a quiet outline and one short caption; mouse, touch or Enter activates
once. Accessibility names match the objects/routes. `show_targets` is a debug
review mode with short labels, not an additional player menu.

Checks include1280×720 desktop;1278×590 and1334×750 phones;844×390 Larger and
667×375 compact framing, supplied notch/home-bar margins and actual1.3 root UI
scaling. The browser review adds independent presence switches, current-party
presets, original comparison, cold/still mode and native-capture selection.
It is an artwork/interaction preview, not a second implementation of game rules.

## Provenance, rebuild and limits

- Thirteen built-in ImageGen outputs, exact prompts/reference roles, immutable
  source hashes and registration: `art/source/overlook-v1/generation.json`.
  Earlier concept/approval and generated originals remain intact.
- `python -B tools/art/build_overlook.py`: mechanical export/registration;
  39 source/export checks pass. Runtime textures total11.42MiB decoded RGBA
  before engine overhead, excluding reused fog/font resources.
- Godot4.7.2 `--headless --path . --quit-after 2400 --script tools/art/check_overlook.gd`:
  160 checks pass, including state dependencies and native mouse/touch/keyboard.
- The same fixture, hidden/off-screen with Mobile renderer:183 checks pass,
  19 real captures, exactly stable still pixels, changed moving-effect pixels
  and hidden-scene processing checks. It never loads Main, player settings or
  saves. Restricted editor import refreshed resources with an editor-preference
  safe-save warning; the isolated resource/render fixtures have clean logs.
- `python -B tools/art/build_overlook_review.py`, then
  `node tools/art/check_overlook_review.cjs`:145 gallery/input/framing checks pass.

Owner review of the assembled production scene remains open. Physical iPhone
touch/performance, live story/party/stash/travel hookup and further recruit body
coverage remain separate work; no live camp or rules were replaced by this art
delivery. The selected composition and all five requested production activities
are represented, with the disclosed equipment-tending substitution above.
