# New monster artwork · #141

2026-10-21 · art for #140, following #32/#97 and [the brief](monster-art-brief.md).

All eleven requested monsters have complete art families: **46 native drawings**,
eleven SpriteFrames resources/scenes, twelve new native symbols plus one reused
symbol, a gas burst/haze and a light-drained pop. The four already implemented
EnemyTypes now use their own scenes, with their placeholder tint/scale removed.
Their numbers, tactics, drops, descriptions and encounter tables are unchanged.

[Paused inspector](../art/concepts/monsters-v1/inspector.html) ·
[All eleven at native review size](../art/concepts/monsters-v1/overview.png) ·
[Exact built-in ImageGen prompts and source hashes](../art/source/monsters-v1/generation.json)

## Runtime paths and poses

`res://art/enemies/monsters-v1/<id>/scene.tscn` and `frames.tres` are the common
paths. The [catalogue](../art/enemies/monsters-v1/catalog.json) lists every PNG,
animation, source crop, common scale, native origin, physical size and hash.

| ID | Native canvas | Idle visible height | Drawings / animation names |
|---|---|---|---|
| `cave-bat` | 128 | 0.42 m | idle, swoop, landed, hurt; **attack aliases swoop** |
| `goblin-brute` | 128 | 1.70 m | idle, wind-up, attack, recover, hurt |
| `gas-bloat` | 128 | 0.82 m | idle, swell, attack, hurt, burst-1, burst-2; **burst plays both rupture drawings** |
| `hollow-miner` | 128 | 1.60 m | idle, grab, attack, hurt |
| `rock-beetle` | 128 | 0.48 m | idle, curled, attack, hurt |
| `venom-spider` | 128 | 0.62 m | idle, attack, hurt |
| `broodmother` | **192** | 1.18 m | idle, call, attack, hurt, enraged |
| `goblin-trapper` | 128 | 1.32 m | idle, set-snare, attack, hurt |
| `gate-captain` | 128 | 1.50 m | idle, rally, wind-up, attack, hurt |
| `lamp-eater` | 128 | 0.72 m | idle, drain, hurt; **attack aliases drain** |
| `breach-hound` | 128 | 0.82 m | idle, attack, hurt |

The Broodmother deliberately uses the brief's 192px exception; its origin is
`(96,180)`. Ordinary enemies retain `(64,120)` on transparent 128×128 canvases.
Each complete family shares one raw-pixel scale and one palette of at most
32 visible RGB colours. Bodies are not fitted independently to each pose's
bounding box. Floating gas/moth art leaves a native gap below the tendrils/wings,
and those scenes add 0.18 m hover height. Small beasts retain smaller world sizes.

Every scene has an AnimatedSprite3D named `Sprite`: nearest, shaded, billboarded,
hard alpha, no collider or light. All have `idle`, `attack` and `hurt`. These
are mostly **single-drawing poses**, not long motion cycles. Gas rupture has two
drawings at 8 fps. Attack/hurt/burst do not loop; held state poses do. Nothing
chooses a tactic, applies damage, advances time or consumes supplies.

### Presentation helpers and origin

`pose_bounds.gd` updates `metadata/visual_height` on animation/frame changes
from exported native top bounds. The existing CombatScreen reads that field
for tag placement, so a raised maul/cleaver stays below its nameplate. Bounds
are precomputed; there are no per-frame image reads or new gameplay callbacks.
Keep the exported `pose_tops` table in sync when replacing art.

`bat_mount.gd` extends that helper. With the root at floor level, idle's top
hangs at **2.4 m**, attack/swoop add **0.65 m** altitude, hurt adds **0.35 m**,
and landed uses the floor origin. It follows the requested animation name only;
it does not infer combat state or run timers. `ceiling_height` is adjustable.
When Claude connects landed/airborne states, reapply Main's panel-clearance
calculation after this vertical change; the standalone fixture does that explicitly.

## What is live, and what Claude connects next

The following `.tres` scene references are connected, and
`tools/story/build_monsters.gd` retains those bindings when rebuilt:

- `data/enemies/cave_bat.tres`
- `data/enemies/goblin_brute.tres`
- `data/enemies/gas_bloat.tres`
- `data/enemies/hollow_miner.tres`

The existing combat renderer already plays their ordinary idle/attack/hurt.
**Special states are available but not all selected by current combat code.**
Select the bat's `landed` while grounded; the brute's `wind-up`/`recover`; the
bloat's `swell` and `burst`; and the miner's `grab` while holding someone.
Protect a transient attack/hurt from an idle-state refresh, as the existing
guard/queen art does. The art helpers do not decide when those states apply.

The other seven scenes are ready for #140's future definitions and encounters.
No numbers, tactics, optional-boss placement or rewards were invented for them.
Elites need no additional sprites. Hatchlings retain `small_spider` art and a
dropped pick retains #138's inventory icon, as requested.

## Effects and small symbols

[Symbol catalogue](../art/ui/monsters-v1/catalog.json), under
`res://art/ui/monsters-v1/`:

- Intent: `swoop`, `curl`, `swell`, `grab`, `drain-light`, `set-snare`, `rally`,
  `call-brood`; `wind-up` points to the existing backlog96 `intent/heavy.png`.
- Status: `grabbed`, `snared`, `gassed`.
- FX mark: `light-drained`.

All new marks have original native 32px SVG sources in
`art/source/monsters-v1/glyphs`, using the existing cream/gold/red/ink palette
and a muted gas green. The inspector shows each at **32, 24 and 14px**.
The fixture uses the actual PartyCard's marks row to show the three statuses.
These are not yet mapped to new conditions/intents in the live screen.

[Effect catalogue](../art/effects/monsters-v1/catalog.json), under
`res://art/effects/monsters-v1/`:

| Asset | Canvas / resource | Use |
|---|---|---|
| `gas-burst` | four 128×128 frames, 512×128 atlas, `gas-burst.tres` | animation `once`, 8 fps; normal alpha, final frame fully clear |
| `gas-haze` | 256×64 PNG | separate faint lingering haze; controller owns duration |
| `light-drained` | six 40×48 frames, 240×48 atlas, `light-drained.tres` | animation `once`, 10 fps; rising/fading native mark, final frame clear |

The cloud is original native pixel FX, with broad irregular grey-green lobes,
restrained opacity and no bright additive flash. It is not a physical gas
simulation. No FX emits a light or changes oil, damage, nerves, time or status.
Claude chooses the trigger, position, lifetime and existing accessibility/settings
behaviour. Do not let haze mask targets or place large FX over action controls.

## Sources, continuity and reproduction

Created with the **built-in ImageGen tool**, not an API/CLI fallback. Twenty-three
original generated PNGs are preserved byte-exact under `art/source/monsters-v1`:
eleven idle identity studies, eleven complete pose boards and one captain rally
repair. Per-output records and the consolidated manifest preserve full prompts,
reference roles/paths, original output paths and SHA256 hashes.

The captain's first rally board mistakenly left a second horn on his chest while
he blew the first. The generated correction supplies **only the rally cell**;
the other four final poses retain their original board. The rejected rally
remains visible in the historical source board. Compare the final paused pose
when reviewing continuity.

The exporter separates alpha-connected pose components, preserving weapon/wing
tips that cross nominal sheet gutters. It removes only subpixel export specks,
uses one scale for every pose in a family, registers translations on the common
canvas, BOX-reduces, applies binary alpha and maps all poses to a shared palette
without dithering. It does not redraw anatomy or repaint generated features.
Final transparent RGB is zero. A single scale is checked mathematically; head,
gear and gesture continuity was also visually inspected. This is not a claim
that generated anatomy is pixel-identical between different gestures.

Rebuild from the project root with Python/Pillow/numpy and Godot 4.7.2:

```powershell
python tools/art/record_monster_sources.py
python tools/art/build_monster_art.py
python tools/art/build_monster_symbols.py
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/art/raster_monster_symbols.gd
python tools/art/build_monster_effects.py
python tools/art/wire_monster_art.py
python tools/art/validate_monster_art.py
Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/art/check_monster_art.gd
python tools/art/build_monster_inspector.py
node tools/art/check_monster_inspector.cjs
```

The source recorder copies a missing master from its original generated location
when available; checked-in masters are sufficient otherwise. It rejects a
different existing copy. `wire_monster_art.py` retains baseline resource text
and refuses unreviewed nonvisual field changes; update that baseline explicitly
when future gameplay changes make the historical snapshot obsolete. Existing
enemy art and reused symbols are hash-pinned in `preserved-art.json`.
The source/review folders have `.gdignore`; runtime copies import normally.

## Verification and practical limits

- **484** source/export/palette/alpha/padding/common-scale/binding/preservation
  checks pass. All nonvisual fields in the four resources and their builder
  match the pre-art baseline.
- **288** actual Godot scene/frame/tag/mount/symbol/FX checks pass with clean
  final import/render logs. **40** captures use the real BattleStage,
  CombatScreen and PartyCard at 1280×720 and 1278×590, including priority state
  poses, two separate hounds and the gas/status demonstration.
- **105** browser checks pass for all 46 drawings, all 40 capture paths,
  pose/effect pause and stepping, contrast/pivot controls, symbols at small
  sizes and 44px controls/no overflow at 844px and 390px widths.
- The 61 runtime PNG canvases total **3.669 MiB RGBA** before engine overhead;
  original studies/review images are outside that runtime count.

The art fixture never instantiates Main or writes a save. It uses the four live
definitions; the other seven get temporary in-memory basic foes solely to display
their artwork. Selected poses/status icons in captures do not prove their future
mechanics or balance. Existing full combat integration still owns phase selection,
bat clearance after landing, FX/accessibility hooks and the remaining encounters.
Physical iPhone appearance, recognition and frame rate remain untested.
