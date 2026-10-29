# Wounded keeper art — #166

The keeper now has a separate Unique dark elf portrait family: slate-blue skin,
long black hair, pale eyes, upswept brows, battered fluted black plate, black fur,
faded violet cloth and one hand against a covered wound. No crown or proper name.
The expressions are restrained: watchful neutral, exhausted/pained and defiant.
This follows `docs/elves-concept.md`; existing elves and recruit catalogs are untouched.

## Assets and hookup

| Drawing | PortraitSet | Static fallback |
|---|---|---|
| Neutral | `data/portraits/wounded-keeper-v1/neutral.tres` | `art/portraits/wounded-keeper-v1/neutral/resting.png` |
| Pained | `data/portraits/wounded-keeper-v1/pained.tres` | `art/portraits/wounded-keeper-v1/pained/resting.png` |
| Defiant | `data/portraits/wounded-keeper-v1/defiant.tres` | `art/portraits/wounded-keeper-v1/defiant/resting.png` |
| Reading the map | `data/portraits/wounded-keeper-v1/map-reading.tres` | `art/portraits/wounded-keeper-v1/map-reading/resting.png` |

All paths are project-relative (`res://`). Catalogue:
`art/portraits/wounded-keeper-v1/catalog.json`. This family stays outside the
human/recruit exporters. All four resources have face identity `wounded-keeper`.

The three expressions own separate complete clean plates, resting eye/mouth
components, half/closed lids, small/open speech drawings and lighting masks.
Use `PortraitView.show_portrait()` with the chosen expression, then `blink()` /
`talk(seconds)`. Switching resources cancels previous callbacks. Never combine
the full `resting.png` with animation components: its existing features would
remain behind them. Eyebrows belong to each expression's clean plate.

Map-reading is a separate static pose, with no facial animation. Use its complete
head image and its own light masks; do not borrow neutral blink or mouth frames.
Separate warm/dim lighting is an explicit caller choice. Broad modeled shading
remains in the drawings; masks provide directional illumination, not a relightable
3D face. Speech is gestural, not phoneme synchronized.

**Live hookup remains for Claude.** `quest_keeper.tres` currently uses an opening
body prop and has no portrait field; `ConversationScreen` currently accepts static
NPC textures. The fallback images can work with that renderer, while animated
dialogue would need a PortraitView integration. No event, conversation, quest,
NPC placement, recruitment, stats or proper-name assignment changed here. These
portraits do not replace the in-world wounded-body prop.

## Sources and export

Four unaltered 1254px built-in ImageGen masters and exact prompts are retained in
`art/source/wounded-keeper-v1/` (`prompts.json`). `generation.json` records source
hashes, registration and output hashes. Four OpenRaster files retain components;
per-expression contours and feature masks are retained alongside them.

`tools/art/build_wounded_keeper.py` exports native192 RGBA, binary alpha, a shared
64-colour visible palette and nearest-neighbour pixels. All masters share an
184px drawing inset by four pixels. Expression source edits contribute only
registered brow/ocular/lip patches: hair, ears, armour, hand, wound and silhouette
are byte-identical across the three animated expressions. Clean plate plus
resting components exactly reconstructs each expression. Animation replaces the
entire feature footprints rather than covering parts of existing features.

There are 33 runtime PNGs; source masters and review images are excluded from
Godot import by their local `.gdignore` files. These are not sprite atlases.

## Review and checks

Open `art/concepts/wounded-keeper-v1/inspector.html`: paused stepping, enlarged
feature crops, bare clean plates, 96px comparisons, light presets and static-pose
controls. `layout.html` is its editable source; the exporter embeds PNGs for
offline inspection. Owner approval of this keeper design is still pending.

Recorded checks:

- `validate_wounded_keeper.py`: 186 source/registration/resource checks pass.
- `check_wounded_keeper.gd`: 38 isolated headless resource/animation checks pass.
- The same fixture in a hidden off-screen Mobile D3D12 process: 52 checks pass,
  including 14 captures at 1280×720 and 1278×590. `godot-*.png` records held
  rest/half/closed/small/open and warm/dim, at 192px and 96px. Clean logs and exit.
- `check_wounded_keeper.cjs`: 46 headless Chrome checks pass; paused/played states,
  distinct held drawings, static controls, lighting selectors and responsive
  review layout at 1280/844/390px. `browser-review.png` retains the review page.

Reports sit beside the inspector. No Main, player saves, preferences or audio
are loaded by the isolated fixture. Physical iPhone and the eventual live
encounter/conversation presentation remain untested.
