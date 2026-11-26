# Damp Caves dressing and early 3D conversions (#302 C/D)

Original project-authored metric geometry, reusing the original worked-prop helpers and the A batch's limestone albedo. No downloaded or private models, third-party source pixels or new animation clips. Existing mine props, formations, bones and exploration mist remain available; see `catalog.json` for their disposition.

45 GLBs cover five wall pieces, three ceiling pieces, four edge pieces, five floor surfaces, the remaining early dressing/landmark conversions, mushroom/mold exit-room cues and three two-state event props. 21 mine counterparts share those meshes with a warmer, drier material; they do not reskin the older palette-point-UV libraries. Every selected GLB is 32–3064 triangles, one opaque shared-material draw, zero bones/lights/collision. Both event meshes remain loaded; only the selected state draws. Shallow water is opaque, not a refraction/reflection or transparent-body pass.

## Mounts and inputs

- Wall: origin at the centre of the existing rock face; local **+Z** points into the room. Back faces are unmodelled or embedded. The calcite/stain/moss outline is irregular, rather than a square sprite substrate.
- Ceiling: origin at the roof. Root/moss fringe is about 0.45m deep, leaving at least 1.75m under a 2.2m roof. Soda straws and the individual stalactite need perimeter placement. Ceiling children join the existing `ceiling` group. Do not put roof pieces at sprite-centre offsets.
- Floor/edge: origin y=0. Floor relief is millimetres high; some edge stone is embedded by a few millimetres. Scale using the catalogue's **final Godot-space** bounds, not legacy sprite pixel sizes. Normal 2m cells require sparse perimeter placement, not all library pieces at once.
- `exit-mushrooms`, `exit-floor-mold`, `exit-wall-mold`: dress the **room holding the Fungal Hollows exit**, not just the transition frame. The main Damp Caves remains wet bare rock. Keep the original fungal library for the side region. Do not turn mood glow into free fuel or poison mechanics.

`set_state(value, animate=false) -> bool` swaps the entire registered geometry immediately. Invalid names are rejected. `state` is directly assignable before/after ready, matching the current container API; `closed` aliases `fresh`, and `empty` aliases `used` when relevant. `set_searched(bool)` is also supported.

| Scene | States | Resolved appearance |
| --- | --- | --- |
| `goblin-stash.tscn` | fresh / empty | Open pouch with supplies and stolen knife removed; stones/binding stay |
| `lamp-store.tscn` | fresh / used | Dead, glassless lamps remain; most sealed oil flasks gone |
| `three-knocks.tscn` | fresh / used | Excavated rubble lowered around the retained frame/brace; no traversable exit implied |

Three Knocks retains the written clue's abandoned cup. Its generic resolved artwork must be chosen from actual quest results; it does not claim the miner was rescued after a refusal, crew mark or other non-rescue outcome. Existing event/quest controllers retain state authority.

## Motion and materials

Everything defaults still. Normal pieces have no idle processing. `set_motion(enabled)` propagates to a child drip hook if present. Only `moss-curtain-lit` and `fungus-pulse` opt into a weak eight-second material pulse; they have fixed emission when still and never create a Light3D. Their material copies cannot change another instance's glow. Regular root/moss/fungus wrappers remain unlit.

`drip.tscn` uses a tiny opaque bead plus an opaque expanding ripple. Default roof origin y=2.2 with `fall_distance=2.16` lands at y=0.01. For other ceilings, set the real distance. `drip-stalactite-effect.tscn` supplies the tip offset and distance for that model. `set_motion(false)` restores phase zero, hides the ripple and stops processing; no shader TIME, particles, timers, RNG or gameplay light. The effect allocates 2 small mesh draws; their visibility does not overlap in the cycle. `phase_offset` can be supplied by the caller's presentation placement if desired. Do not use global gameplay RNG to desynchronise it.

Old `AnimatedSprite3D` drip/fungus effect calls need a model-aware caller adapter. Avoid applying both the old overlay and the new effect. The static drip sample is a droplet under the roof; a still-mode ripple does not need to remain permanently drawn.

## Delivery and review

`catalog.json` records every GLB hash, native envelope, mount, states, budget, old-id replacement and material counterpart. No existing live URI or scene assignment is changed. Hook the assets up through the owning theme/dresser/event factory, preserving wall anchors, saved outcomes, placement/RNG and visibility preferences. Later floor 3–4 daubs/litter/trophies, full E landmark compositions, F event state kits, H sound and I approved creatures remain separate production.

Rebuild with background Blender `--python tools/damp_caves/build_dressing.py -- --workspace E:/GitHub/Depths`, then `python tools/damp_caves/prepare_dressing.py`. Editable separate-piece `.blend` masters stay local in `build/local-damp-dressing-v1/masters`; none enters Git. Run `tools/damp_caves/dressing_check.gd` through the private-desktop helper after a headless import; package with `python tools/damp_caves/package_dressing.py --workspace E:/GitHub/Depths`.

Review: `E:/GitHub/Depths/build/local-damp-dressing-v1/inspector.html`. Native reports and real desktop/1278×590/844×390 captures are in its `native` folder. Owner visual review, live seeded placement, exported-game integration and physical iPhone performance remain unverified.
