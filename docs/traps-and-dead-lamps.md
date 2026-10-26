# Trap props and the dead-lamp store

2026-10-25 · #158 / #159 · [Inspection gallery](../art/concepts/traps-lamps-v1/inspector.html)

| Event | Ready | Resolved |
| --- | --- | --- |
| Snare | Broad cord loop, stake and grit | Tightened empty noose and kinked slack cord |
| Dart plate | Proud stone inside a broken rim | Depressed stone and two spent darts |
| Bell wire | Taut wire and one bronze bell | Cut slack ends and fallen bell |
| Dead lamps | Four broken lanterns; three sealed oil flasks above | Same rack with upper shelf emptied |

All four existing events now point to `art/props/traps-lamps-v1`. Both story
builders were updated and run. Event files differ only in their art references:
choices, odds, costs, injuries, damage, ambushes and loot remain unchanged.
The territory package/chance and older tripwire/hollow-floor art are preserved.

## Mounting and states

Snare and plate lie flat, about one metre across their full canvases. The bell
wire is upright perspective art, about 1.6m across its full canvas. Traps sit
slightly toward their cell's nearest cardinal wall: 0.45m for floor sprites,
0.18m for the bell. This improves approaching views without changing the camera.
Full-canvas bounds were checked in all four wall directions.

Dart ports are separate art, 0.48m above the floor and 0.015m in front of the
nearest cardinal rock face, facing inward. The plate remains in its cell.
`dart_mount.gd` supplies trap offsets and ports. Main has a small optional
`mount_in_cell(map, cell, cell_size)` hook before adding a prop; other props
do not implement it. If no wall is found within eight cells, ports stay hidden.

The lamp rack follows old-workings' pixel scale and upright floor-origin
convention. It contains no lights/glows. Glass highlights are reflections.
The optional ceiling smear was not needed for this delivery.

Existing visibility rules still apply: traps appear when spotted or resolved.
Leave keeps ready art; resolution uses `state="empty"`. Existing triggered-cell
save data restores the state. Used drawings mean the encounter was dealt with,
not a separate depiction of every choice outcome. No new collision or hazards.

## Sources and rebuilding

Nine 128×128 RGBA textures: four pairs plus ports. Each pair shares <=32 visible
colours, hard alpha, nearest sampling and full-canvas registration. There is no
per-state crop, fit or grounding. Upright contact derives once from the ready
image; floor sprites retain their centre. Scene offsets do not change by state.
Generated surrounding details are closely matched, not claimed pixel-identical.

[generation.json](../art/source/traps-lamps-v1/generation.json) retains all nine
unaltered built-in ImageGen masters, exact prompts, original paths and reference
roles/hashes. Existing style inputs are unchanged. No CLI/API fallback was used.
Source/review folders have `.gdignore`. Native canvases total **576 KiB RGBA**
before overhead.

Rebuild with `tools/art/build_traps_lamps.py`, import in Godot 4.7.2, and run
`tools/story/build_traps.gd` / `tools/story/build_territories.gd` if rebuilding
event references. The trap builder can rename old sprung-outcome subresource
IDs without changing values; that incidental rewrite is excluded here.

## Checks and limits

- **74 source/export checks:** exact copies/prompts/hashes, native canvas,
  alpha, margins, shared palettes, opaque dart holes and preserved event rules.
- **138 real Main checks:** all wall directions, visibility, Leave, resolution,
  save/rebuild, repeat prevention and no rack light. Private project-local save.
- **24 desktop/landscape-phone captures:** four pairs plus one-cell-away floor
  views. Normal game lighting/held lantern retained. Floor details are faint
  at two cells; near views are the useful recognition check.
- **34 browser checks:** all pairs, native128/64/2×, backing toggles, every
  capture and responsive widths. Physical iPhone review remains open.

The Main fixture exits successfully but reports two CanvasItem RIDs/four
ObjectDB instances at shutdown. Functional assertions pass; this does not fix
Main teardown. The legacy trap harness also passes its assertions, with shutdown
leaks including four resources in use. Both legacy regressions pass: 12 trap
assertions and 11 lamp-territory assertions, with `fails=0`; both report the same
shutdown resource leak. The isolated Underhound fixture exits cleanly.
