# Cavern identity and Rest Area approach — #308

Owner direction: a tall, narrow rift like the title-menu background, warm local
lanterns against cold depth, then an earned sheltered refuge. The playable slope/
elevation prototype is **deferred**. These scenes establish the visual kit and
room compositions; they do not add slopes, collision, traversal or map layers.

## Delivery

22 original physical-UV GLBs, 30 registered scenes, three new unchanged albedo
sources with 512px mipmapped imports, four region surface materials and a
candidate EnvironmentTheme. `catalog.json` records actual export hashes, bounds,
surfaces, states, room footprints and reused-input hashes. Separate editable
Blender pieces remain local in `build/local-cavern-rest-v1/masters`.

The kit includes tall tapered mineral columns, roof pendants, two scales of
fluted cliff face, talus and level rock ledges; goblin clay daubs, litter, totems,
drying racks and bone trophies; fresh/worked iron seam; closed/open hide curtain,
blocked/cleared palisade and four destination-labelled passage throats. Reused
#246 palisades/watch post/walkway and verified CC0 bones form four landmark
compositions: totem field, lookout, collapsed bridge and bone midden.

Rest pieces include an open canvas tent with supported bedroll/groundsheet and
earth beneath the pegs, separate bedroll, paper/map table, supply crate and bench.
The full approach uses these around a retained 3D hearth with a clear central
arrival, shelter walls/roof and lookout edge. Future planning/stash/quartermaster
markers are locations, not new services or invented occupants.

## Runtime contract

Use wrappers, not bare GLBs. `state`, `set_state(value, animate=false)`,
`set_searched`, `set_motion` and `set_canopy_hidden` are presentation APIs.
Two-state legacy `closed`/`empty` select first/second appearances. Direct and
pre-ready restores work; invalid states are rejected. Motion defaults off and
reaches the retained fire/lantern; hidden fire stops processing. Fresh refuge
has one small existing light; used/banked appearance hides it completely.

Metric floor origin, +Z out of a wall; passage roots follow the LevelBuilder
floor-centre/−Z convention. Return throats retain caller floor. Onward descents
provide a full 2m landing because LevelBuilder omits its descent tile. No travel
trigger is embedded; the caller displays the canonical destination label and
owns graph pairing and save state. The curtain is hide, not a new web/burn rule.

`refuge-marker.tscn` fits one cell and is bound in `data/events/refuge_scouts.tres`
through its existing prop API. That is the only live resource change. Existing
rest/cost/loot/route/Overlook/service behavior stays authoritative. The full
`rest-area-approach.tscn` needs a **4x4-cell room plus rock-wall thickness and
5.3m roof clearance**; do not assign it to a random one-cell event. Keep the
owner-approved `art/camp/overlook-v1` screen layout and present-party mapping.

Landmarks use 3x3-cell rooms; edge props leave the centre approach clear. The
collapsed deck is scenery beside a retained dry route, not a repair gate.
Iron seam must have a real wall; its worked art never awards ore. The Cavern
stash can reuse #303's dry mine stash sibling after that kit lands.

`cavern-rift-identity.tscn` is a **visual composition**, 10x16m plan with deep
skirt and tall walls. The foreground path is level y=0; far ledges are unreachable
scenery. It contains no player/controller and is not the postponed playable
prototype. Tall columns/cliff faces and the full refuge require deliberate
room/ceiling reservation. Use smaller ribs/props under current 2.4m ceilings;
do not silently raise every area's roof or put giant pieces through it.

## Materials and sources

New geometry is original, reusing `tools/mine_props/build_models.py` and
`tools/mine_polish/build_models.py`; no new downloaded/private models or motion.
Existing #246 structures and #285 hearth reuse their retained CC0/project source
records. Bones use `art/dressing/bone-decor-v1` with retained KayKit licence and
original hashes. Existing source meshes, palettes and libraries are unchanged.

Physical metre UVs and vertex colours use the worked-prop shaders. Rock siblings
add restrained grain from the new wall albedo. Do not apply these to palette-point
meshes. `cavern-wall-variant.tres` is ShaderMaterial: a static offset blend returns
to base at tile borders, not a second bitmap or animation. No normal body shader
writes ALPHA; only the retained small fire effect does. No extra shadow passes.
Source albedos/prompts/hashes: `art/textures/cavern-v1/generation.json`. Built-in
image generation, copied unchanged. Raw geological texture repetition still
needs owner review; no claim of perfect raw-image periodicity is made.

## Review and rebuild

Native gallery: `build/local-cavern-rest-v1/inspector.html`; raw imported pieces,
all appearances, desktop/1278×590/844×390, first-person art compositions and actual
Main refuge-prop restore. Reports give measured whole-scene draws/triangles.
Physical iPhone performance and full live-floor/exported integration remain.

Build: background Blender `--python tools/cavern_rest/build_models.py --
--workspace E:/GitHub/Depths`, then `python tools/cavern_rest/prepare_scenes.py`.
Import headlessly; texture imports must keep size limit 512 and mipmaps enabled.
Run `tools/cavern_rest/check.gd -- <capture-folder>` using the private-desktop
helper and isolated APPDATA. No owner settings or Main save/game loop is started.
Package with `tools/cavern_rest/package_review.py --workspace E:/GitHub/Depths`.
