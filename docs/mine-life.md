# Small mine life (#266)

`scripts/mine_life.gd`, attached by `Ambience.attach`, adds occasional small
bat fly-bys, scurrying mice and falling ceiling grit to floors 1 and 2.
The initial wait is 4–8 seconds; subsequent attempts wait 12–25 seconds.
Half the attempts are dust, a quarter bats and a quarter mice. There is
at most one effect: 2.1 seconds for a bat, 1.7 for a mouse, 3.8 for dust.

Effects require steady or bright light and a neighbouring empty floor cell.
They skip contents, solid objects, encounter zones and passage cells, and
stay within that cell. First person chooses the cell ahead; overhead also
allows either side, restricted to the tactical view's revealed cells.
They clear during combat, the opening, camp, menus, darkness and floor
changes. Turning off Settings' screen flashes/moving effects removes them
immediately. No new setting, sound, light, collision, target, saved state,
encounter roll or resource cost is introduced. Their RNG is independent.

The mouse reuses the CC0-derived rat's existing `run` clip at 26% scale
(`art/enemies/rat-3d-v1`, provenance in `art/third-party/oga-rat-v1`). The bat
reuses the authored cave bat's `idle` flight at 22% scale
(`art/enemies/early-creatures-3d-v1`). Per-instance shaded materials fade in
and out; the bat's membranes render from below as well as above. The source
models, rigs, clips and shared materials are unchanged. Dust uses one
28-instance MultiMesh of small shaded grains, with staggered falling paths.

Validation: `tools/mine_life_check.gd` exercises the live scene, motion,
effect lifetime, blocked/passaged cells, light, menu/combat suppression,
floor changes, overhead visibility and unchanged gameplay RNG/time/oil.
Godot 4.7.2 Mobile/D3D12 captures at 1278×590 are saved locally in
`build/local-mine-life-v1/phone`. Use the #253 private-desktop launcher for
GPU checks; tests must never take focus from the owner's apps. Physical
iPhone performance and visibility still need device review.
