# Damp Caves: production handoff (#302)

2026-11-26 · Delivery on `codex/damp-caves-surfaces`, PR #303, based on Claude's brief at `aca0d4ce` and the subsequent `docs/area-production-briefs.md`. Current coverage: A surfaces, B/N1–N3 for the Damp Caves junction, C environment dressing, D early flat-prop conversions, E landmarks, F interactive appearances, G layout candidates, H sound and I four approved-concept creature models. Claude retains live hookup and rules. Existing fungal files remain intact for the fungal side region.

## Production status

| Brief | Status | Delivery / next action |
| --- | --- | --- |
| A1–A4 surfaces | Delivered, native-checked; owner/device review remains | `art/textures/damp-caves-v1` |
| G layouts | Four complete design candidates; owner/Claude review before gameplay hookup | `docs/damp-caves-layout.md`, machine-readable `damp-caves-layout-sections.json` |
| B passages + N1–N3 for this junction | Delivered, native-checked; no live hookup | `art/features/damp-passages-v1`, `art/ui/area-routes-v1`; other areas’ exits remain separate work |
| C dressing | Delivered, native-checked; no live hookup | `art/dressing/damp-dressing-v1`; includes still-safe drips and fungal exit-room growth |
| D 2D leftovers | Delivered, native-checked; no live hookup | 29 old-id dispositions and 21 mine counterparts; stash, dead lamps and Three Knocks state sets |
| E landmarks | Six complete art compositions, native-checked; no live hookup | `art/props/damp-sites-v1/landmark-*.tscn`; sump, weeping wall, drowned drift, rimstone stair, bone silt, wet royal cache |
| F event props | Five complete appearance sets, native-checked; event rules/text remain Claude's | Sunken satchel, cave pearls, seep, slick ledge and blind fish |
| H sound | Delivered, technical checks pass; human listening/mix review remains | `audio/damp-caves-v1`: 12 environment sounds + 8 creature reactions |
| I creatures | Four concepts approved for modelling; models/rigs/clips/symbols delivered and native-checked | `art/enemies/damp-creatures-v1`, `art/ui/damp-creatures-v1`; live combat/ambient hookup remains |

## Surface handoff

Four unchanged original albedos and their materials are in `art/textures/damp-caves-v1`; `catalog.json` contains exact paths, mounts/envelopes, draw/triangle costs and numeric wet response. Texture imports cap each at 512px with mipmaps. Material source files are editable; original PNGs, prompts, provenance and hashes are retained. Copies of all editable inputs are local in `build/local-damp-caves-v1/editable-inputs`.

Set a future theme's `wall_face_uv=true`, use the two wall resources and the matching floor/ceiling at 2m cells / 2.2m walls. The wall variant is a **ShaderMaterial**, not StandardMaterial3D: a static opaque two-albedo blend restores the base rock at every tile border and reduces hard adjacent-variant joins. It adds one sample only on variant surfaces; all four textures are already shared. Never add ALPHA to normal cave surfaces. The three other materials are StandardMaterial3D with roughness ≥0.61 and low dielectric specular. No material creates lights, uses TIME, or requires set_motion.

The delivered surfaces use existing LevelBuilder geometry, without new meshes or collision. No normal maps, clearcoat, emission, screen reads or additional reflection passes. Four complete 512px RGBA8 mip chains cost about 5.33 MiB before GPU compression/engine overhead. The wet sheen is restrained; stronger pool reflections belong to explicit later puddle surfaces. Native warm torchlight colors nearby limestone, while neutral/unlit areas carry the cool regional palette. Do not add permanent blue lights merely to force a screenshot palette.

Exact prompts, source output paths, SHA-256 hashes and reference roles: `art/textures/damp-caves-v1/generation.json`. Built-in image generation, original sources, no third-party/private inputs. The source PNGs are unchanged; the tile-border blend is material code, not a claim that the raw textures have perfect geological wrap continuity.

## Layout handoff

`docs/damp-caves-layout.md` supplies shape rules, four ASCII sections, water proposals, named landmark/quest/lair locations, new-creature and ambient placement, a proposed Drowned Mother patrol loop, and a candidate encounter mix. `tools/damp_caves/build_layout_sections.py` regenerates JSON and checks connectivity.

The first world junction is **Abandoned Mines → Damp Caves → Cavern or Fungal Hollows**. Other `>` characters are explicitly section continuations. They do not invent further world destinations. The quartermaster's unlockable surface route targets the **Rest Area beyond Cavern**, as the owner specified. Numeric depth is not an area identity.

All water/encounter weights and named-pack placement are **proposals only**. Default shallow `~` is visual; optional `w` basins have dry bypasses and need a deliberate rule choice. Never silently insert all wet cells into `map.water`: Galleries' authority already changes time/strain/torch behavior. Preserve actual quest footprints, mandatory site placement, current proximity-based quest discovery, existing lair Go in/Back away and the independent routes around optional encounters. Owner approved all four creature concepts for modelling on 2026-11-26; model-style/device review remains.

## Native checks and local review

Local gallery: `E:/GitHub/Depths/build/local-damp-caves-v1/inspector.html`.

- **87 native Mobile/D3D12 checks, zero failures**: opaque PNGs/materials, unchanged source hashes, bounded 512px imports/mipmaps, full-face UVs, fixed 2m/2.2m geometry, numeric wet response, no extra lights, border blending verified against actual rendered base pixels, interior variant still distinct. Ten real captures include neutral/warm torch, desktop and both requested phone shapes, grazing angles, mine comparison and 4×4 repeats.
- **50 layout checks, zero failures**: dimensions/legend, room descriptors ≤5×5, connected cells/features, all exits reachable without deep water, correct two destination names, a closed patrol sequence with start away from stairs, and dry main-route bypass after the side loop is blocked. These are proposal checks, not live generation/combat/quest integration tests.

Re-run the surface fixture through `tools/testing/background_godot.py`, passing `--script res://tools/damp_caves/surface_check.gd -- <capture-folder>`; use isolated APPDATA. Rebuild/validate sections with `python tools/damp_caves/build_layout_sections.py`. Tests ran on private desktops with `test_was_foreground=false` and touched no owner saves. Physical iPhone performance, seeded full-floor placement and owner visual review remain unverified. No live-theme, exported-game or rules claim is made for this art-only delivery.

## Passage and exit delivery

Brief B1–B4 and N1–N3 for the Damp Caves junction are now delivered in `art/features/damp-passages-v1`; six matching code-native SVGs are in `art/ui/area-routes-v1`. Full contracts, source record, budgets and paths are in their catalogues/READMEs. Local review: `build/local-damp-passages-v1/inspector.html`; separate editable Blender pieces: its `masters` folder.

- Cavern onward is a water-cut shaft with actual recessed ledges/rope handhold. Its matching return is a wet rope ascent. The shaft supplies an open apron; the return retains the builder floor and tags its upper cap for ceiling hiding.
- Fungal Hollows onward is a low fungal crawl with a complete ground apron. The matching fungal-side return retains the builder floor. These are visual transition throats, not newly walkable connected levels or a forced crouch mechanic.
- Root/fibre curtain has intact/opened states; it is organic tear/burn-role artwork, not a calcite wall inheriting web fire rules. The siltfall has blocked/cleared states. Cleared states leave a true central opening. Existing gameplay still decides passage outcomes.
- Markers use raised glyph geometry matching the map symbols, plus canonical `interaction_label` metadata for the caller's pre-commit prompt. No TextMesh lettering or billboard cost. `destination_hint`/`paired_asset` are art hints, never automatically bound world-area IDs.
- Features are static and opaque: no processing, light, alpha, emission, collision, RNG or saved rules. The material shares the surface batch's limestone albedo; relief uses height derivatives without another texture. Budget is 680–2366 triangles / 1–2 visible draws per selected scene. An inactive state sibling remains hidden.

**274 native checks pass, 65 captures:** eye-height/three-quarter in neutral/torch light, 1278×590 and 844×390; both actual LevelBuilder orientations; model/visible-state bounds, budgets, paired metadata, restore-before-ready, invalid-state guard, exact still, canopy hiding, open-passage swap, floor/aperture rays and 1.85m central clearance. Glyphs are checked at 16/24/32px. Native logs are clean; physical iPhone and owner visual review remain. Game-owned way-up/down glow is shown only in the caller fixtures and unchanged.

## Environment dressing and remaining early conversions

`art/dressing/damp-dressing-v1` delivers C/D: **45 solid GLBs**, 21 warmer/drier mine counterparts, 29 explicit old-id dispositions, a still-safe 3D drip/ripple and opt-in fungal/moss pulse. `catalog.json` contains each model's engine-space bounds/hash/mount, states, budgets and native replacement paths; its README has the full API and source contract. Reuses the original worn-prop helpers and shared limestone albedo. No new private/downloaded sources or character clips. Existing mine supports/rails/lanterns, cave formations, bone decor and exploration mist remain available rather than being recreated.

The core kit provides fluted wet flowstone, mineral seep/crack, damp moss, embedded pearl niche, open soda-straw mouths, a dripping stalactite/hook, hanging roots, rimstone terraces, a slick boulder/stub, drowned plank/bucket/lamp debris, shallow opaque puddles, silt ripples, old bootprints and wet gravel. The conversion set covers chalk, cracks, fine silk, nest, drag marks, scorched floor, root curtains/tangles, broken crates/barrel, fallen royal cloth, rubble/planks and spilled grain. Regular models are **32–3064 triangles / one visible draw**, no bones, light or collision. State siblings are hidden, not drawn together. Dedicated floor relief is millimetres high; don't reuse old sprite-centre placement or pixel scaling.

Three Knocks, goblin stash and dead lamp store have registered fresh/resolved geometry. Direct `state="closed"/"empty"` assignments still work; explicit `set_state` and `set_searched` are also available. No tween or half-open restoration problem. Three Knocks keeps the written clue's cup and a blocked recess: the used scene does not invent a new travel exit or an NPC. Choose resolved artwork from the actual quest outcome rather than equating every cleared event with rescue.

Mushroom clusters and wall/floor mold are separate **room-scale cues for the Fungal Hollows exit**, per #304. Normal Damp Caves stays mostly wet rock/silt. Only the explicitly lit wrappers glow; emission is mood-only, no party light or poison/strain rule. New effects default still, propagate `set_motion`, reset phase exactly and stop processing. The tiny opaque bead/ripple uses no particles or transparent body; both roof and stalactite offsets land at the actual floor. The caller should apply its existing effects/visibility preference and stop hidden effects. Existing mist is reused, not replaced.

**947 native Mobile/D3D12 checks, 106 captures** cover imported hashes/bounds, actual triangle/draw accounting, wall/ceiling/floor registration, pre-ready/direct/invalid/interrupted states, every conversion path, shared mine/wet materials, nested effect material isolation, real floor landing, motion/still reset and complete phone framing. Includes neutral/key-light and torch inspections, metric room examples at desktop/1278×590/844×390, fresh/used event variants and paused falling/impact samples. Local review and separate-piece editable masters: `E:/GitHub/Depths/build/local-damp-dressing-v1/inspector.html` and its `masters` folder. Native logs are clean; no visible desktop or owner save was touched. Owner style review, physical iPhone performance, live seeded placement and exported-game hookup remain unverified.

Rebuild: background Blender `--python tools/damp_caves/build_dressing.py -- --workspace E:/GitHub/Depths`, then `python tools/damp_caves/prepare_dressing.py`. Import headlessly, run `tools/damp_caves/dressing_check.gd` through `tools/testing/background_godot.py`, and package the local gallery with `python tools/damp_caves/package_dressing.py --workspace E:/GitHub/Depths`. Shared shaders remain opaque and use physical metre UVs/vertex colors; do not apply them to older palette-point exports.

## Remaining decisions and integration

The requested A–I art/design deliverables are present. G's water rules, encounter weights and branch return/rejoin details still need owner/Claude review. The distinct exits/signs/glyphs delivered here cover the two Damp Caves links; shared-network N1–N3 for other areas remain future production. Claude retains all live graph/theme/dresser/quest/combat hookup. Owner visual/listening review and physical iPhone testing remain; this is not a complete playable-floor claim.

**N4 arrival painting remains a proposal.** Its possible purpose is first-discovery orientation and mood, not travel or a new camp service. The referenced results/arrival document concerns combat-panel entrances, not an existing area-introduction flow. A still vista/name that can be dismissed immediately, with a small name notice on revisits, is a candidate only. No forced wait, repeated restore interruption, input-swallowing transition, hidden encounter reveal or live feature is approved. No arrival painting was produced in this batch.

## Landmark and interactive-appearance delivery

`art/props/damp-sites-v1` completes the E/F **art delivery**: six composed landmarks, five event appearances and fourteen new solid exports. Existing rails, original pack, C/D dressing and verified CC0 bones are referenced. The drowned cart derives from Kio Kurashi's [CC0 Static Minecart](https://kiokurashi.itch.io/3d-static-minecart); its unchanged selected GLB, licence declaration, hashes and changes are retained in `art/third-party/kiokurashi-minecart-v1`. Other new geometry is original project work. Editable masters remain local. The small reusable C/D-builder change preserves all 45 earlier GLB hashes exactly.

The sump, continuous weeping wall, rimstone stair, bone-silt bank and wet royal cache use a **3×3-cell / 6×6m** rectangular room, floor-centre origin and a real far wall at Z=−3m. Drowned drift uses a **1×3-cell / 2×6m** straight corridor with a partially submerged cart beside the retained rails. Independent Marker3D approach/event anchors and catalogue footprint/layout notes support placement. Fit actual walls and preserve actual dry paths and mandatory quest footprints; the scenes do not assign `map.water`, room identity, passability, search targets or rewards. The royal cache retains a reserved buried-cache anchor; bones are anonymous scenery. Landmark budgets: **3228–11328 triangles / 5–24 visible draws**, measured natively, including retained instances.

| Interactive appearance | States | Important hookup contract |
| --- | --- | --- |
| Sunken satchel | fresh / emptied | Existing pack half under unchanged water; retain intentional burial offsets |
| Cave pearls | fresh / gathered | Pearls disappear into empty depressions; pool remains |
| Seep | fresh / used | Cup/use marks change; natural water remains; mount on a verified real wall |
| Slick ledge | ready / slipped / passed | True 0.55m cut in supplied 2m tile; omit caller floor; choose actual trap outcome explicitly |
| Blind fish | fresh / fished | Small opaque pale school under a local clear-water surface; fished school disappears |

These event appearances are **548–2528 triangles / 1–6 visible draws**. Direct `state` assignment and `set_state(value, animate=false)` restore before/after ready and reject invalid values. `closed` aliases fresh/ready; `empty` aliases the second state only for two-state props. **Ledge rejects generic empty**, so a safe pass cannot silently become a slipped/disarmed trap. `mount_in_cell` fits the seep to a real cardinal wall without moving its event root/cell; a missing wall hides it and returns false, a later valid mount restores it. All event choices, cost/odds, loot, cooldown and outcome/state selection stay with Claude.

Motion defaults off. `set_motion` resets exact fish/drip poses and stops processing; fished state stops swimming. The fish move rigidly with no skeleton, external animation clip or RNG. Only the small fish-viewing water surface uses standard alpha; fish, stone, ledge and all normal bodies remain opaque. No screen refraction or extra light. Parent material application is explicitly scoped to new physical-UV meshes, preserving nested water and retained palette-UV pack/bone/rail resources. Apply the caller's effects/visibility preference.

**455 native Godot 4.7.2 Mobile/D3D12 checks / 65 captures, zero failures and clean logs:** fourteen actual imported bounds/hashes/counts, whole-scene budgets and material assignment, all explicit/legacy/direct/early/interrupted states, clear-water isolation, exact still/swim reset, submerged fish clearance, actual ledge support/drop rays, all four seep wall anchors and missing-wall recovery, all landmark footprints/roof limits, phone framing, desktop/1278×590/844×390 room views and neutral layout overviews. Private desktop, isolated profile, no owner save/foreground changes. Owner style/device review, live seeded placement and exported-game hookup remain.

Local review: `E:/GitHub/Depths/build/local-damp-sites-v1/inspector.html`; its `masters/` contains separate-piece `.blend` files. Full API/layout/source contracts: asset README/catalogue. Rebuild with background Blender `--python tools/damp_caves/build_sites.py -- --workspace E:/GitHub/Depths`, then `python tools/damp_caves/prepare_sites.py`; import headlessly, run `tools/damp_caves/sites_check.gd` through the private-desktop helper and package with `python tools/damp_caves/package_sites.py --workspace E:/GitHub/Depths`.

## Approved creatures and sound delivery

Owner approved **Pale Newt, Blind Crawler, Leech Swarm and Drowned Mother**
concepts for modelling on 2026-11-26. Unchanged turnarounds, exact generation
prompts/reference roles/source hashes and that approval are retained in
`art/concepts/damp-creatures-v1`. Four rigged scenes now live in
`art/enemies/damp-creatures-v1`, with eight original matching map/bestiary SVGs
in `art/ui/damp-creatures-v1` and eight hurt/death sounds in the audio library.
Existing live creatures, resources and all combat rules remain unchanged.

The models reuse original project mesh/rig/floor-fit helpers. No private base,
downloaded anatomy or external motion is used. An examined CC0 crayfish scan
was unavailable (403) and was not downloaded/used. Editable separate Blender
masters stay in `build/local-damp-creatures-v1/masters`. Pale Newt is 2064
triangles / 24 bones / 3 skin draws; crawler 1726 / 24 / 2; swarm 1800 / 25 / 2;
Mother 2362 / 24 / 3. Each adds a two-triangle contact plane. No lights or
collision; normal opaque skin, pigment, gills/shell/detail materials and explicit
cached fade siblings preserve #297's true opaque depth behavior.

All are +Z front, fixed metric floor origin, within a two-metre cell. Common
clips at 24fps: idle, attack, hurt, fall, walk, run. Newt/Mother add rear,
submerge/emerge; crawler grab/hold/release; swarm spread/regroup/burn. The Mother
shares newt rig/clip roles with heavier proportions, curl/scar and attached
flank leeches. Read the README/catalogue for exact timings and immediate still
poses. `sample` uses seconds. Grab finishes into hold; fall/submerge hold their
last frame. `framing_bounds` unions registered clips for cross-fade safety.
Submerge flattens under caller-supplied pool water; the caller owns visibility,
targeting, map glow, patrol, encounter composition, loot and all numbers.

**3966 native checks / 85 captures pass, with clean logs.** Validation checks imported skin/joint continuity, loop seams, floor
registration and animated envelopes, exact still, opaque/fade restoration,
state transitions, source hashes/budgets and complete desktop/1278×590/844×390/
667×375 framing. These are native asset fixtures, **not live combat tests**.
Local model gallery: `E:/GitHub/Depths/build/local-damp-creatures-v1/inspector.html`.
Its `native/validation.json` records the final counts and all captures; owner
model-style acceptance, physical iPhone performance and live/exported hookup
remain.

`audio/damp-caves-v1` supplies **20 sounds**: a 48s loop, four wet steps, splash,
wet bump, root-curtain/siltfall sounds, three drips and eight creature reactions.
All mono 44.1k PCM16, Effects bus, explicit loop flags and no import gain/trim/
compression. Preserve existing ambience-player −10dB once; don't apply twice.
Kenney impact/RPG, rubberduck water/slime, Bashar3A wind and qubodup balloon
friction are retained verified CC0 inputs, with exact archive members, evidence,
hashes and recipes in CREDITS/catalogue. Original shaped noise adds low material
recoil; no actor voice or purported animal recording. Existing **117** audio
files, including music, remain byte-identical. No runtime synthesis/new music.

**326 PCM/source/rebuild checks and 165 native decoder/playback checks pass**:
hashes, finite PCM, headroom/DC/endpoints, explicit loop wrapping and one-shot
finish/stop, independent Effects/Music controls and 5,784,156 bytes of decoded
PCM. Licence evidence comparison permits only raw identity or exact text
line-ending equivalence (the retained water HTML is CRLF, checkout LF).
Playback ran with Master muted on an isolated desktop/profile; no owner
settings, foreground changes or Main lifecycle. Human/headphone/physical-phone
listening and final live mix remain. Local no-autoplay sound desk:
`E:/GitHub/Depths/build/local-damp-audio-v1/inspector.html`; separate `audition.wav`
is only a review reel.

Rebuild creatures with background Blender and `tools/damp_caves/build_creatures.py`,
then `prepare_creatures.py`; audio with `tools/audio/build_damp_audio.py` using
the bundled Python 3.12, NumPy/soundfile and `--deps build/audio-deps`. Both take
`--workspace E:/GitHub/Depths`. Import headlessly, configure audio imports with
`validate_damp_audio.py --configure-imports` and reimport. Run creature/audio
fixtures through the private-desktop helper, then package both galleries with
`tools/damp_caves/package_creatures_audio.py --workspace E:/GitHub/Depths`.
