# Refined mine props and loot chests (#278 / #279)

Owner request, 2026-11-22: improve mine-model shapes and textures, and provide
common, silver and embellished gold loot chests.

## Mine pass

`art/dressing/mine-refined-v2` supplies eight scene replacements. The existing
placement counts, seeds, mounts and event outcomes remain authoritative.

| Scene | Visible triangles, fresh/closed | Change |
| --- | ---: | --- |
| support | 1,322 | Hewn arrises, bowed timber, bearing pads, shims, nail heads and grain checks |
| support-damaged | 1,561 | Same registered frame, repair plank and crooked iron splint |
| lantern-standing | 748 | CC0 core, beveled frame, protective cage, vents and carrying bail |
| lantern-hanging | 1,410 | CC0 core, cage, vented hood and curved bracket stay |
| miners-shrine | 4,417 | Chipped courses, fixed carving seat, cap/beard/hands, cloth folds, wax and offerings |
| old-workings | 2,456 | Worn pit props, trough boards, fractured rock, crooked pick and mineral seams |
| rails | 1,506 | Worked rail profiles, grain checks, shoes, fishplates and bolts |
| rails-broken | 1,380 | Same rail registration, missing/split sleeper and lifted curved end |

The support keeps the 1.6m-wide / 1.85m-high central passage clear. Lanterns
keep their floor/top-bracket origins; the shrine keeps its wall/floor origin
and fresh/spent registration. Workings remove ore when searched. Lantern and
candle emission remains local surface glow, with no new Light3D. Disabling
motion fixes emission immediately and stops processing. The three small shrine
flames share one mesh/material surface.

`scripts/dressing.gd` now binds the refined supports, lanterns and rails;
`chest_old_workings` and `object_miners_shrine` bind their matching new scenes.
Only art paths changed in those event resources. The original mine and
expedition asset families remain available unchanged.

## Materials

`art/materials/worked-props-v2` separates wood, iron, silver, gold, stone and
cloth. Timber UVs are measured in metres and follow the axis of each beam,
including braces and headers. End faces carry separate end-grain flags. Metal
uses hammering, fine pitting and restrained tarnish; stone uses fine pores;
cloth weave fades at small screen sizes. All detail is static shader code,
without new bitmap paintings or external texture dependencies.

Six read-only material resources are shared through ResourceLoader while props
are alive; there is no static material cache. Mutable glass/emission material
is private to each prop. Exported meshes retain physical UV/UV2 data and linear
vertex colours; do not apply the older palette-point atlas to these meshes.

## Chest types

Canonical scenes are in `art/props/loot-chests-v2`. Each has closed/open/empty
states, a fixed floor root and a real rear hinge. Front is local +Z.

| Type | Closed triangles | Open with decoration | Design |
| --- | ---: | ---: | --- |
| common | 1,544 | 1,944 | Low worn wooden lid, dark iron, repair board and simple lock |
| silver | 2,126 | 2,526 | Higher lid, silver binding, corner guards, central rib and fittings |
| gold | 3,128 | 3,528 | Tall arched lid, gold scrollwork, seal/lozenge, embellished lock and cornerwork |

`art/props/chests-v1/common.tscn`, `silver.tscn` and `gold.tscn` are compatibility
wrappers for the paths already expected by Claude's pending chest-tier
dispatcher. They inherit the same state API and fixed tier metadata. This art
pass does not alter that dispatcher's placement, loot, rewards or save rules.
`loot-chests-v2/library.gd` also offers an explicit scene lookup, returning null
for unknown types rather than choosing a rarity on behalf of the caller.

```gdscript
var chest = preload("res://art/props/loot-chests-v2/library.gd").scene("gold").instantiate()
chest.state = "empty"    # set before adding to restore immediately
chest.set_motion(false) # exact still pose; finishes an interrupted transition
add_child(chest)
```

Runtime lid motion lasts 0.32s and opens to -102 degrees. Reversing a moving
lid starts from its current angle. Empty hides the decorative bundle/coins;
they are not a count or representation of the generated loot.

## Sources, rebuild and review

Retained CC0 KayKit lanterns/candles and chest body/lid provide the starting
geometry. The builder verifies all pinned originals against the existing
provenance records before export. CREDITS.md files beside the new families
record modifications. No character rig, animation clip or private model is
involved. Editable component Blender masters remain local under
`build/local-mine-polish-v2/masters`.

1. In Blender 5.2, run `tools/mine_polish/build_models.py` with `--background
   --factory-startup --disable-autoexec --python-exit-code 1`, then
   `-- --workspace E:/GitHub/Depths`.
2. Run `python tools/mine_polish/prepare_scenes.py`.
3. Import headlessly with Godot **4.7.2**, then run `tools/mine_polish/check.gd`
   through `tools/testing/background_godot.py`. An optional user argument sets
   the screenshot/report folder. `capture.gd` creates the neutral/cave review
   and same-camera older-asset comparisons.

251 native checks pass, covering actual mesh/UV/colour data, triangle/surface budgets,
support clearance, mounts, fresh/spent registration, glow/still behavior,
hinged states and interrupted motion, dispatcher wrappers and live binding
paths. The existing complete `models_3d_check.gd` also passes its nine checks, including real
floor dressing and event states. Desktop and landscape phone captures are
made with the Mobile/D3D12 renderer on the private desktop without foreground
activation. Physical iPhone performance remains a device-review step.

Review gallery: `art/concepts/mine-polish-v2/inspector.html`. Full native output
stays local under `build/local-mine-polish-v2`.
