# First story slice: art handoff

2026-10-20 · #127, refs #96 and #123. The first story slice's commissioned
art is wired into the existing conversations, events and equipment resources.

## Delivered

- Commander Edric Vael: grey temples, watchful face, scrubbed plain armour.
- Hask: gaunt dusty miner, receding hair, wool blanket, tired resting face.
- A cave-mouth backdrop with three waiting soldiers, used only by
  `commander_first`. Other conversations show the existing game behind them.
- Three Knocks: diagonal cracked beam, breathing gap, tin cup, plus a
  dealt-with state with shifted stones and three chalk strokes.
- Iron seam: broad rust-red veins in dark hematite, plus a chipped grey cavity
  and loose spoil after sampling.
- Lower water gate: barred iron grate, old carved jambs and a black-water
  channel. It remains closed after looking through it.
- Distinct short sword, light flanged mace and camp-forged blade icons, with
  descriptions matching their materials. Their names, stats and prices stay
  the same. The blade remains 4–6 damage, light, 45 gold.
- Iron ore icon, ready for future presentation. The sample is currently a
  quest flag, so no new inventory item or reward was introduced.
- Journal control and camp-news glyphs in the existing native SVG style.
  Tooltips and accessibility names explain the icon-only journal button.

## Asset contract

`art/portraits/story-slice-v1`: two **static neutral 192×192 portraits**, plus
the opaque 960×540 backdrop. These are whole-face story portraits, kept
separate from the reusable recruit rigs and unique animated hero rigs. They
have no blink/talk components. Never put another character's eye or mouth
layers on top of them. Existing #124 portrait repairs remain unchanged.

`art/items/story-slice-v1`: four transparent 128×128, 64-colour icons, with
at least 8px padding, matching the current refined-v2 canvas and apparent size.

`art/props/story-slice-v1`: 192×192, 64-colour transparent sprites and three
floor-origin scenes. Pivot is (96,180). The two state pairs share the exact
source registration transform. Scenes use world lighting, nearest filtering
and Y billboarding, with no colliders or emission. They use the existing
`container.gd` visual-state contract, controlled by Main.

The rubble's used art means the site has been dealt with. It deliberately
does **not** show a cleared walk-through tunnel: marking it for a crew and
immediately rescuing Hask share the existing resolved-event state. The blocked
passage, rescue timing and all quest flags stay under the existing story code.

Both story resource builders retain these bindings when rerun. Exporting art
does not change other items, the live 3D held lights, floor themes or saves.

## Sources and reproduction

All twelve masters were made with **built-in ImageGen**. Byte-exact originals,
exact prompts, reference-image paths and SHA-256 hashes are in
`art/source/story-slice-v1/generation.json`. Source masters have a `.gdignore`.

Run `tools/art/build_story_slice_art.py` to reduce/quantize the masters and
rebuild the overview/catalogue; `--wire` restores the owned resource bindings
and descriptions. It performs mechanical exports only, without repainting or
upscaling. Paired states use one union crop and one scale/offset.

## Verification and review

`art/concepts/story-slice-v1/overview.png` shows native exports and 96px
portraits/40px items. That folder also contains actual Godot desktop and
1278×590 phone-shaped captures: landmarks before/after, both conversations,
camp news and pack items. These are review fixtures, not new starting grants.

- `validate_story_slice_art.py`: twelve source copies/hashes and exports,
  padding/palette/alpha/paired transforms, and ten resources compared with
  `cce02b2`. All nonvisual rules, dialogue, choices and rewards match.
- `check_story_slice_art.gd`: actual Main prop integration, world lighting,
  used states, optional backdrop cleanup, news availability and journal action.
- Existing `tools/story_check.gd`: all 40 story/save checks pass in the real
  Mobile renderer with clean logs. Its old literal `(!)` assertion now checks
  the news glyph and accessibility name. A headless run passes the rules too
  but reports audio resources during shutdown; the full rendered run is clean.

Physical iPhone review remains. The new #128 dressing and #129 ambient briefs
are a separate asset batch; elf/dark-elf concepts and later-layer surfaces are
not silently assigned to current floors by this change.
