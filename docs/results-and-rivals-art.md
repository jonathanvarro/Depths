# Spoils, expedition results and the first dark elves

Delivered 2026-10-21 for #130 and the **dark elf portion** of #131.

[Pause/step art review](../art/concepts/results-v1/inspector.html) · [actual phone return](../art/concepts/results-v1/return-phone.png) · [held portrait drawings](../art/concepts/dark-elves-v1/held-192.png) · [combat poses](../art/concepts/dark-elves-v1/combat-poses.png)

## Results and spoils: connected

`art/ui/results-v1` contains two 1280×720 cave-mouth backgrounds, a 32px purse,
experience and advancement marks, and light versions of danger/object/down.
Return and wipe show the same place in different light. They depict atmosphere,
not a new camp location or a change to the party-wipe rules.

The purse is a direct reduction of `art/items/refined-v2/old-coin-purse.png`,
retaining the established leather/coin design. Its source is unchanged. Tally
and upward marks extend the native SVG system. The three map outlines are
unchanged apart from their light ink, so the minimap keeps its dark originals.

`scripts/results_screen.gd` selects the proper background for each ending,
including when the same window is reused, and uses the new chip symbols.
Story briefs still hide the background. Text, rewards and expedition rules are
unchanged. A lighter cover lets the right-hand dawn remain visible while the
left stays dark behind the ledger.

`scripts/spoils_screen.gd` uses the purse, XP mark and an advancement arrow with
the existing “Level up at camp” tooltip/accessibility name. This does not grant
levels automatically. Its four arrivals now use native pixel SpriteFrames:

| Resource | Drawing | Contract |
|---|---|---|
| `slash-frames.tres` | diagonal pale blade cut | eight frames, 20fps, one shot |
| `smash-frames.tres` | irregular radiating cracks | same |
| `pierce-frames.tres` | narrow thrust streak | same |
| `fire-frames.tres` | ragged ember/burning band | same |

Each frame is 128×64 on a 512×128 atlas. Empty first/last frames and automatic
cleanup prevent stranded effects. The existing panel motion, smash shake and
burn-cover shader remain. A plain fade still applies when screen flashes are
disabled. The older procedural streak helpers are retained but no longer used
by the four arrivals. No combat reward, timing, turn or save rule was changed.

## Dark elves: ready for story assignment

The pair follows [Claude's concept brief](elves-concept.md): bold upswept brows,
slate-blue skin, swept-back ears, gothic fluted black plate and a heavy ragged
fur mantle. The man has white hair and a narrow chin; the woman has black hair,
a softer face and a spired circlet. Lilac eyes remain the brief's provisional
choice. Edric's approved portrait was inspected as a rendering benchmark.

| Character | PortraitSet | Static fallback |
|---|---|---|
| Man | `data/portraits/dark-elves-v1/dark-elf-man.tres` | `art/portraits/dark-elves-v1/dark-elf-man/resting.png` |
| Woman | `data/portraits/dark-elves-v1/dark-elf-woman.tres` | `art/portraits/dark-elves-v1/dark-elf-woman/resting.png` |

`art/portraits/dark-elves-v1/catalog.json` is the explicit handoff. Both are
**Unique**, each with its own family and face ID. They are not added to the
human recruit templates or assigned names, classes, dialogue or encounter roles.
Claude can use the resources with the existing `PortraitView.show_portrait()`.
The catalogue deliberately remains separate from the human registry/exporters.

Every layer is an untrimmed 192×192 canvas. A clean character plate plus exact
neutral eye/mouth components reconstructs the resting reference byte-for-byte.
Two blink drawings and three speaking drawings replace the **complete** feature
footprint, including outer lashes and old lip corners. They were fitted in
native pixels through the #124 authoring pipeline, rather than generated as
loosely aligned facial atlases. Source contours, full mattes and retained-iris
and mouth-opening masks are preserved. Inspector playback starts paused, with
held frames and a bare-character option for detecting baked duplicate features.

Neutral portraits have no torch-colour pass. Separate black/white light masks
work with `set_illumination("neutral"|"warm"|"dim")`. They are broad authored
upper-left contributions for these outfits, not a physical relighting model or
an automatic fuel hookup. No condition overlays are supplied for this pair.

One male spearman is ready at
`art/enemies/dark-elves-v1/spearman/scene.tscn`. Its `AnimatedSprite3D` named
`Sprite` supplies non-looping single-drawing `idle`, `attack` and `hurt` poses.
These follow the simpler combat style: exact 128×128 canvas, binary alpha,
one shared palette of at most 32 colours and pivot (64,120). All poses use the
same square reduction and horizontal offset; only vertical translations plant
their supporting foot at y=120. Registration metadata records every transform.
The 1.95m art-fixture scale is a proposal. Spear choice is visual only.

No live EnemyType, opponent statistics, hostility, recruitment or story trigger
was added. Normal **elf** portraits and combat art remain the next part of #131;
do not mark that issue complete.

## Sources and checks

Seven built-in ImageGen masters are retained byte-for-byte, with exact prompts,
input references and SHA-256 hashes in:

- `art/source/results-v1/generation.json` (two background masters).
- `art/source/dark-elves-v1/generation.json` (two portraits and three poses).

Native SVGs, original-input hashes, facial contours and helper-version hashes
are alongside them. Source/review directories have `.gdignore` files. Runtime
textures decode to about **11.3 MiB RGBA** combined before engine overhead;
largest image dimension is 1280px. This is not a physical-iPhone measurement.

Rebuild: `build_results_art.py`, then Godot's `raster_results_glyphs.gd`, and
`build_dark_elves.py`. Import using Godot **4.7.2** before checks. The dark-elf
builder refuses changed master or authoring-helper hashes until reviewed.

- `validate_results_rivals.py`: source/input preservation, canvas/alpha/palette,
  complete facial replacement, exact neutral and simultaneous compositions,
  effects and shared combat registration.
- `check_results_art.gd`: real results/spoils screens at desktop and simulated
  phone dimensions, every arrival, reusable ending selection, advancement marks,
  effect cleanup and a real combat victory without duplicate rewards.
- `check_dark_elves.gd`: the unchanged PortraitView's held frames, playback,
  neutral return/hidden cancellation, separate lighting, and all three poses in
  the actual combat view at desktop and phone dimensions.
- `check_results_inspector.cjs`: offline review, pause/step, bare-face switch,
  lighting, effects, visible 44px controls and no horizontal overflow.

Reports and actual captures live beside the inspector and dark-elf review.
Final reports: **180 source/native, 124 results/victory, 51 portrait/combat and
24 browser checks**, all passing. Final import and rendered logs are clean.
Checks use ignored project-local fixture saves and contain no save deletion.
Physical iPhone appearance/performance and the owner's visual judgement remain
separate. Claude's concurrent landmark work and its generated UIDs are untouched.
