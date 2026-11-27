# Damp Caves landmarks and event appearances (#302 E/F)

Six composed landmarks and five interactive appearance sets, with fourteen solid GLBs, reuse of existing prop libraries and original/retained CC0 provenance. These scenes are ready for integration; they do not add live event definitions, rewards, route/water/collision rules or save flags.

## Landmarks

Origins are floor-level centres. The square rooms require **3×3 cells / 6×6m**, with their far wall at local Z=−3m and roof at 2.2m. Drowned drift requires a straight **1×3-cell / 2×6m** corridor. All mounts/bounds are in final Godot coordinates in `catalog.json`. These layouts must be matched to actual rectangular room walls and access points by the landmark factory. Don't scale arbitrary occupied rooms into them or let props cross real walls. No perimeter geometry grants a new traversable ledge or changes a map cell.

| Scene | Visual composition | Caller anchor / layout |
| --- | --- | --- |
| `landmark-sump` | Still dark water with low silt banks, worn boulders and roof straws | `DryApproach` on near perimeter; `PoolEvent` reserved; keep main-route cells dry |
| `landmark-weeping-wall` | One continuous fluted calcite wall, puddles and optional falling drips | Fits the actual far wall; `SeepEvent` reserved, foreground free |
| `landmark-drowned-drift` | Existing rails run beneath the right water lane and a partially submerged CC0 cart | Left approach remains visually clear; no automatic wading rules |
| `landmark-rimstone-stair` | Four low terraced calcite pools and edge stubs | `PearlsEvent` reserved; side/foreground approach; not a stair transition |
| `landmark-bone-silt` | Verified anonymous CC0 bones/ribs embedded in a washed silt bank | Dead-end scenery; no searchable companion or tutorial-body identity |
| `landmark-wet-royal-cache` | Rotted broken crates/barrel, fallen royal cloth, spilled grain, puddles and roots | `BuriedCache` reserved and central approach free; preserve existing mandatory quest/site placement |

These use 3228–11328 triangles and 5–24 selected mesh draws in native fixtures. Most of the cost comes from retained bone instances and cache pieces. Surrounding walls/floor/ceiling in review images are fixtures, not duplicated geometry inside each landmark. Reuse the existing exploration mist if desired; no new fog/light implementation is included.

## Interactive appearances

| Scene | Explicit states | Mount and resolution |
| --- | --- | --- |
| `sunken-satchel` | fresh / emptied | Half-submerged existing pack, flap/contents resolve within an unchanged pool |
| `cave-pearls` | fresh / gathered | Loose pearls replaced by empty depressions; basin remains |
| `seep` | fresh / used | Fresh mineral water remains; cup and wet use marks change; no promise of permanent exhaustion |
| `slick-ledge` | ready / slipped / passed | Actual 0.55m cut beside a left-hand ledge; slide scrape/fallen gravel differ from safe boot scuffs |
| `blind-fish` | fresh / fished | Four small pale eyeless fish under clear viewing water; fished school disappears, pool remains |

Events are **548–2528 triangles / 1–6 visible draws**, including the retained pack, water and visible effect geometry. All solid bodies are opaque. Only the small blind-fish **water surface** uses standard alpha to show fish beneath; no normal creature/body shader writes ALPHA. No screen refraction, extra lights or particles. Other pool/water surfaces are opaque.

`state` can be assigned before or after ready. `set_state(value, animate=false) -> bool` immediately switches complete registered appearances, rejects invalid names and restores cleanly during repeated/interrupting calls. `closed` aliases fresh/ready. For **two-state** props, `empty` aliases the resolved second state. **The slick ledge rejects `empty`**: the caller must use the actual `slipped` or `passed` result, never assume every resolved trap fired or was disarmed.

Normal props start at floor y=0. The satchel is intentionally partly below the caller's floor/water; preserve its wrapper offsets rather than fitting the entire buried mesh above ground. `Interaction` and `SafeApproach` are Marker3D hints, not click areas or collision. Event texts, costs, odds, loot and repeat rules remain for Claude.

The **seep needs a real wall**. With the root already at the event cell centre, `mount_in_cell(map, cell, cell_size)` finds the nearest cardinal wall and rotates/translates the `Mount` subgroup with local +Z pointing into the room. A missing wall returns false and hides the appearance; a later valid mount restores it. This changes appearance only. The root's event/quest cell never moves. For a custom authored site, the caller can position `Mount` against its verified rock face directly.

The **slick ledge requires a floor cut**. It supplies the complete 2×2m tile, including the safe side, ends and real recessed lining. The ordinary caller floor must be omitted under that tile, as for the passage shaft; otherwise it fills the drop. `metadata/requires_floor_cut=true` is an integration hint, not automatic floor/collision authority. Passability, trap state, interaction range and return behavior remain caller-owned.

## Motion and source contracts

`set_motion(enabled)` defaults off, propagates to child drips, and resets exact rest poses/phase. Only the fresh fish school has a small rigid swimming motion; fished state stops its processing. It uses no skeleton, external clip, timer or RNG. Fish remain above silt and beneath water in both still/swim poses. The seep and weeping wall's drips are optional; still mode stops their processing. Apply the existing visibility/effects preference when activating these scenes.

New GLBs use C/D's physical metre UVs, material-family UV2 and vertex colors. `metadata/physical_surface=true` marks new imported meshes for the shared wet material; it intentionally overrides the importer's default white material. Existing pack/bone/rail wrappers retain their own verified materials. Do not recursively overwrite nested water, old palette-point UV meshes or retained library materials.

Original site geometry uses `tools/damp_caves/build_sites.py` and existing project helpers. The cart is a fitted, aged, decimated derivative of **Kio Kurashi's CC0 Static Minecart**; its selected original GLB, source declaration, hashes and changes are in `art/third-party/kiokurashi-minecart-v1`. Bone instances reuse the already verified KayKit CC0 set and credits in `art/third-party/kaykit-bones-v1`. The existing original project pack, rails and C/D dressing are referenced rather than duplicated. No private source or character animation clip was added. The small reusable-builder refactor preserves all 45 C/D GLB hashes exactly.

Rebuild with background Blender `--python tools/damp_caves/build_sites.py -- --workspace E:/GitHub/Depths`, then `python tools/damp_caves/prepare_sites.py`. Import headlessly, run `tools/damp_caves/sites_check.gd` through the private-desktop launcher, then `python tools/damp_caves/package_sites.py --workspace E:/GitHub/Depths`.

Local native gallery/editable masters: `E:/GitHub/Depths/build/local-damp-sites-v1/inspector.html` and `masters/`. Native validation covers all states, budgets, actual imports, material isolation, metric room bounds, four-wall seep mounts/missing-wall restore, real ledge drop/support, swimming/reset/underwater fit and both landscape phone shapes. Owner visual review, physical iPhone performance, seeded live placement and exported-game integration remain open.
