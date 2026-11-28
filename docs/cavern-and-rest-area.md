# Cavern identity and Rest Area approach (#308)

Owner request, 2026-11-26: proceed with the Damp Caves hookup (Claude action is
acceptable), build the Cavern's identity and finish the Rest Area approach.
The small playable Cavern/elevation prototype comes **afterwards**.

Follow-up #311 now supplies that isolated walking study; see
`docs/cavern-elevation-prototype.md`. The art composition described here remains
visual scenery, separate from the new playable scene and campaign integration.

Live follow-up #313 now binds the full reserved Rest Area and height-aware
Cavern via `docs/cavern-live-elevation.md`; the original art delivery below
describes its earlier, deliberately limited integration scope.

Delivery: branch `codex/cavern-rest-area-art`, isolated from Claude's active
core exploration/city work. Full contracts: `art/props/cavern-rest-v1/README.md`
and catalogue. Local native review: `build/local-cavern-rest-v1/inspector.html`.

## Cavern direction and art

The title-menu reference defines a **tall narrow rift**, dark vertical depth,
large hanging formations and warm local lanterns. This supersedes the older
brief's broad/open cavern wording. The new kit supplies 22 original solid GLBs,
30 registered scenes, three original generated albedos, four surface materials
and a candidate EnvironmentTheme. Source PNGs stay unchanged; GPU imports are
capped at 512px with mipmaps. Exact built-in prompts, source paths, dimensions
and hashes are in `art/textures/cavern-v1/generation.json`.

Pieces cover tapered columns/roof pendants, small ribs and tall fractured cliff
faces, talus and level stone ledges, goblin daubs/litter/totems/drying racks/bone
trophies, fresh/worked iron seam, closed/open hide curtain, blocked/cleared
palisade and labelled passage throats to Damp Caves, Rest Area and fortress.
Four 3x3-cell landmark compositions reuse the verified retained structures and
bones: totem field, lookout, collapsed bridge and bone midden. Dry goblin stash
art can reuse #303's mine sibling once that kit lands.

The rift context is a native visual composition with a **level y=0 foreground
ledge**, deep skirt and unreachable distant tiers. It has no controller, map,
collision or traversal, and does not implement the postponed elevation
prototype. New tall-room scenery requires deliberate void/roof reservation.
The current game's 2.4m roof must not slice through the 5.8m columns or 14m cliff
panels. Smaller ribs and props can serve ordinary low rooms in the meantime.

## Rest Area approach and live marker

The full 4x4-cell approach has an earth-pegged open tent and supported bedding,
separate bedroll, paper/map table, supply crate, bench, warm bankable hearth,
rock shelter and lookout edge. Its arrival path stays clear. Planning, stash
and quartermaster Marker3Ds reserve locations without inventing occupants or
new service access. The full scene needs a reserved room, wall thickness and
5.3m roof clearance; do not attach it to an arbitrary one-cell event.

The **compact one-cell 3D refuge marker is bound** in
`data/events/refuge_scouts.tres` through its existing `prop` field. That one URI
is the only live resource change. It supports fresh/used and closed/empty
restore, remains floor-registered in the actual Main prop adapter, and banks
its fire when the saved used state is restored. Existing rest cost, loot,
route unlocks, safety, Overlook screen layout, actual present-party activities,
quartermaster/service authority and choices remain untouched.

## Ownership and sources

Claude owns the Damp Caves live integration; the concrete file/contract/check
handoff is `docs/damp-caves-hookup-for-claude.md`, using art PR #303. Claude has
already implemented its water/creature/route/challenge rules and currently owns
changes to Areas/Main. Do not overwrite that work from an older art checkout.

New geometry is original on the existing mine/worked-prop helpers. Retained
palisades/watch post/walkway, lantern/hearth and verified CC0 bones are reused;
their original files and source/licence records stay unchanged. No new private
character source or external motion. Separate editable Blender masters stay
local under `build/local-cavern-rest-v1/masters`. No character clips were added.

Physical UVs/vertex colours use scoped materials so retained palette assets
keep their own shaders. Rock grain and the wall variant are opaque. The variant
returns to base at tile borders with a static offset blend. Only the retained
small fire effect uses alpha. No extra mesh shadow passes; fresh refuge uses
one retained small mood light, banked appearance none. Motion defaults still
and reaches nested fire/lantern; hidden effects stop. Imports/materials do not
assign gameplay light or affect torch costs.

## Validation and limits

**864 native checks and 132 captures pass**, with zero failures and clean logs.

Native Godot 4.7.2 Mobile/D3D12 review checks actual export hashes/bounds/
triangle/draw counts, physical UV/colour assignment, registered states and
legacy/invalid/pre-ready restores, central passage clearance, full descent
landings and no duplicate return floors, no coplanar rift floor fighting,
exact fire still/banked behavior, original retained inputs, 512px mipmapped
albedos, complete desktop/1278x590/844x390 framing and the actual Main refuge
factory/restored-used adapter. Reports/captures and private-desktop record live
beside the local gallery. No owner save/settings or foreground window was used;
the Main save/game loop was not started.

Measured scene budgets: landmarks 3139–4200 triangles / 3–15 draws; compact
refuge 2520 fresh / 2344 used, 6/5 draws; full approach 14466 fresh / 14290 used,
30/29 draws. Rift composition about 20k triangles / 38 draws. Native report is
authoritative if later art changes these counts. Physical iPhone performance,
owner style review and complete live seeded-floor/exported integration remain.

Rebuild: background Blender with `tools/cavern_rest/build_models.py --
--workspace E:/GitHub/Depths`, then `prepare_scenes.py`, headless import, native
`tools/cavern_rest/check.gd -- <capture-folder>` through the private-desktop
helper, and `package_review.py --workspace E:/GitHub/Depths`. Retain texture size
limit 512 and mipmaps; no raw PNG crop/recompression or engine upgrade.
