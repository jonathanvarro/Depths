# Recruit faces · nine-character roster

**Current extension (#163):** the combined catalog now has twelve faces.
[Three concept-faithful Fixer rigs](fixer-portraits.md) have their own red-coat
busts and fitted animation. This page and its fixed review retain the original
nine shared-body faces and their verification history.

Artwork for [#82](https://github.com/jonathanvarro/Depths/issues/82), extending
the [shared portrait kit](recruit-portrait-kit.md). Three faces per role,
with seven new heads and the original Warden/Scout preserved.

| Role | Visual ID | Appearance |
| --- | --- | --- |
| Warden | warden-a | Older woman, short greying hair, watchful face (existing) |
| Warden | warden-b | Older brown-skinned man, salt-and-pepper curls and short beard |
| Warden | warden-c | Young pale woman, freckles and cropped auburn hair |
| Scout | scout-a | Young man, short dark curls, angular face (existing) |
| Scout | scout-b | Young brown-skinned woman, short twists and high cheekbones |
| Scout | scout-c | Older brown-skinned man, balding head and grey stubble |
| Brawler | brawler-a | Weathered woman, black undercut, crooked nose and old cheek scar |
| Brawler | brawler-b | Young olive-skinned man, shaved head, stubble and blunt jaw |
| Brawler | brawler-c | Older bronze-skinned man, cropped grey hair, moustache and old scar |

These are visual IDs, not names, traits, injuries or starting equipment.
The Brawlers look battered but wear the same basic padded garment as the
others. Character appearance does not change recruitment or combat rules.

## Integration for Claude

The combined [catalog](../art/portraits/recruit-roster-v1/catalog.json)
is the entry point for **all nine**, including the two original faces.
`by_role` lists three stable IDs per role. Every portrait entry contains
`portrait` (flat fallback), `portrait_set` (animated neutral resource),
`expressions`, `shadow` and `highlight` paths.

Choose once when making a candidate and retain that choice with the hero.
Assign `hero.portrait` and `hero.portrait_set` from that entry; the existing
PortraitView/party card understands these resources. No renderer change
is needed for blinking, talking or conditions. This art delivery does
not replace the silhouettes in `scripts/recruits.gd`.

Old Warden/Scout resources stay in `data/portraits/recruits-v1`; seven new
ones live in `data/portraits/recruit-roster-v1`. Use catalog paths rather
than constructing them from an ID. Append `-worried` or `-exhausted` before
`.tres` for the paired static expression. These have empty blink/talk arrays
so a calm animation cannot overwrite worried/exhausted brows.

For separate authored lighting, the optional existing adapter accepts
`configure(id, emotion, catalog_entry)`, then
`set_illumination("neutral" | "warm" | "dim")`. Its original two-argument
form still supports the starter kit. Pass the entry for new IDs.
Use `set_condition(name, shown)` and optionally `set_outfit(false)`.

## Fixed layer contract

All runtime PNGs remain **192 × 192 RGBA, origin (0,0)**. Stack entire
canvases at one scale; never trim or independently fit individual layers.
All nine heads and 27 expression resources reference the exact existing
`recruit-kit-v1/shared/body.png` and `shared/jerkin.png` textures.

This expands the validated `average-covered-adult-v1` clothed bust/socket.
It does not deliver all six proposed body families, long hair or hoods.
Faces have distinct palettes (at most 48 RGB colours each) to preserve
different skin/hair tones. Shared body/outfit pixels are unchanged.

New eye/brow patches occupy (73,51)–(142,82); mouth patches occupy
(82,89)–(132,112), allowing beards and moustaches around speaking mouths.
Each neutral set has half/closed lids and small/open speaking mouths.
Only these regions swap; head, shoulders and outfit remain still.
The original two faces retain their original smaller patch regions.

Each set includes named `blood`, `dirt`, `bandage`, `pallor` overlays.
Pallor uses partial alpha over skin, retaining the underlying complexion;
the small dressing sits above the brows. Old scars belong to the base
head, not a removable injury state. Conditions do not introduce rules.

Neutral art retains local form shading without an orange incident glow.
Separate monochrome shadow/highlight coverage is authored for upper
image-left light, composited above conditions with controlled strength.
Warm/dim are presentation presets, not arbitrary physical relighting or
automatic torch/fuel integration. Different outfits require new mask checks.
Mara's separate-light migration remains [#36](https://github.com/jonathanvarro/Depths/issues/36).

## Review and sources

Open `art/portraits/recruit-roster-v1/preview.tscn` and press F6. It compares
all nine at 128px and 96px with Light, Emotion, Condition, Outfit, Blink
and Talk controls; the runtime assets themselves remain 192px.
The scene is an isolated art review, not campaign UI.

[Native roster](../art/concepts/recruit-roster-v1/roster.png),
[96px cards](../art/concepts/recruit-roster-v1/cards-96.png) and
[animation review](../art/concepts/recruit-roster-v1/animation-preview.gif)
give quick visual checks. Runtime animation timing comes from PortraitView.

`art/source/recruit-roster-v1` preserves 28 unmodified built-in
**image_gen.imagegen** outputs (seven heads and 21 atlases), exact prompts,
14 registration reference boards and seven editable 19-layer OpenRaster
stacks. Each stack includes shared body/outfit, neutral face and hidden
expression, condition and lighting layers; enable only one eyes/mouth state.
The two original editable stacks remain with the starter kit.

Rebuild with `tools/art/build_recruit_roster.py` and Pillow. It registers
each full source cell using the common 184px resize plus (4,4) inset,
fits generated animation heads to the unchanged hair/ear silhouette with
a uniform scale and translation, then refines on nose/ear/chin anchors.
This corrects head enlargement in four generated atlases before extracting
fixed feature patches. It clips overlays and normalizes palette/coverage. No new
facial drawing is procedurally substituted for the generated art.

[Asset validation](../art/concepts/recruit-roster-v1/asset-validation.json)
records measured registration, palette counts, bounds and SHA-256 hashes.
[Godot validation](../art/concepts/recruit-roster-v1/godot-validation.json)
records **2,413 passing checks and 24 captures** in Godot 4.7.2 Mobile/D3D12.
The shared viewer also passed the original kit's **424 checks / 24 captures**
again, with regression renders kept in ignored `build/art-review/kit-regression`.
`tools/art/check_recruit_roster.gd`
checks all nine resources, shared texture identity, canvas/alpha, real
blink/talk playback and expression interruption, condition/light order,
and portrait/button bounds at 1280 × 720 and 1278 × 590. Physical iPhone
and live candidate/card assignment remain integration checks.
