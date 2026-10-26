# Wall families for the deeper cave · #126

**Live integration, 2026-10-25:** the fungal family now completes the current
second floor. [Fungal Caverns handoff/review](fungal-caverns.md). The five other
families remain unassigned. The original library delivery is recorded below.

Six reusable base wall materials follow the connected-environment proposal in [#125](cave-descent-and-quests.md). They form a new standalone art library; the proposed floor count, final lore and environment assignment are not implemented by this task.

[Native/64px overview](../art/concepts/descent-walls-v1/wall-families.png) · [4×4 repetition](../art/concepts/descent-walls-v1/repeat-4x4.png) · [actual Godot lantern view](../art/concepts/descent-walls-v1/drowned-masonry-lantern.png) · [phone-shaped temple view](../art/concepts/descent-walls-v1/sealed-temple-phone-lantern.png)

| Family | Material identity | Suggested proposal pairing |
| --- | --- | --- |
| Worked cave | Broad fractured shale slabs, muted pick scars, warm charcoal rock | Old Workings / Webbed Chasm |
| Goblin hold | Patched older masonry, rough infill, a few iron staples | Goblin Marches / Queen's Hold |
| Drowned masonry | Cold slate, eroded mortar, pale deposits and sparse algae | Drowned Galleries / Black Reservoir |
| Fungal stone | Old stone visible through subdued olive/teal moss and flat fungal crust | Mosslit Hollows / Garden of Echoes |
| Buried city | Planned limestone ashlar, worn chisel margins, old buff plaster | Buried Threshold / Silent Ward |
| Sealed temple | Large dark basalt faces, recessed joints and restrained architectural courses | Temple / Last Threshold |

Names and pairings are working art labels. Stone colour/construction and surface growth carry identity. Repeatable walls contain no quest symbols, religious emblems, relic depictions, doors or baked luminous effects. Particular seals, inscriptions, water levels, giant roots and landmark props can remain independently placeable. No relic/cultural interpretation is decided here.

## Files and use

[Material library/catalogue](../art/textures/descent-walls-v1/README.md) · [source masters and exact prompts](../art/source/cave-walls-v1/generation.json) · [export tool](../tools/art/build_descent_walls.py)

Each family has one 128×128 opaque PNG with at most 32 colours, and a `StandardMaterial3D` `.tres` using nearest sampling, repeat and full roughness. There are no normal/emission maps, custom shaders or added lighting costs. Six RGBA textures represent 393,216 uncompressed bytes before engine overhead. Original cave/stone/fortress assets and all live themes remain unchanged.

To use a material in a future environment, assign its resource to `EnvironmentTheme.wall_material` and initially the same resource to `wall_variant_material`. This avoids mixing unrelated surfaces. #139 now provides [matching floor/ceiling materials and deeper dressing](descent-surfaces-and-dressing.md), without changing these walls or live themes. Distinct damaged/plain partners and transitions can follow during integration.

## Generation and export

Six masters were generated separately with the **built-in ImageGen tool**, requesting restrained pixel clusters, broad readable forms, neutral diffuse lighting and seamless edge intent. Exact prompts, original generated paths and source SHA256 hashes are retained. Every master was copied byte-for-byte into `art/source/cave-walls-v1/`; the exporter validates those hashes before rebuilding.

The export downsamples to 128px with BOX filtering to suppress high-resolution grain, reconciles a six-pixel wrap apron symmetrically on both axes, then quantizes to 32 colours without dithering. Opposite border pixels are identical. This prevents a colour discontinuity but does not prove every crack or masonry joint continues geometrically. Native, 64px and 4×4 repetition sheets were inspected; the library is a base set rather than every transition/variant needed for final rooms.

Rebuild with `tools/art/build_descent_walls.py`, import in Godot 4.7.2, then run `tools/art/check_descent_walls.gd`. Source and review directories have `.gdignore` files. Runtime PNGs/materials/catalogue are separate.

## Verification and limits

43 Godot checks pass with clean import/render logs and 18 actual captures: each family under shared neutral ambient, warm lantern and 1278×590 phone-shaped lantern conditions. The fixture uses the existing `LevelBuilder` and its ordinary `BoxMesh` walls, plus the existing cave floor/ceiling. It creates no game state, floor assignment, save or fuel rules.

The original #126 captures above use the old cave floor/ceiling for comparison.
#139's inspector has new matched surfaces and fresh actual room views. The
existing box UV layout stretches/crops material regions differently from floor
planes, so physical texel-scale consistency remains a geometry limitation.
Repeated motifs remain visible in large uniform areas; worn variants and
landmarks can break those up later. Physical iPhone appearance remains untested.
