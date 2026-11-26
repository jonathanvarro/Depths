# Damp Caves: production handoff (#302)

2026-11-26 · First delivery on `codex/damp-caves-surfaces`, based on Claude's brief at `aca0d4ce`. Claude subsequently added `docs/area-production-briefs.md` (now incorporated); the Damp Caves two-exit/sign/glyph kit is now delivered; the three-knocks prop remains pending P1 work. The owner asked to start the larger list; the current delivery covers surfaces, passage/exit art and layout candidates, not the whole floor. Claude retains live hookup and rules. Existing fungal files remain intact for the fungal side region.

## Production status

| Brief | Status | Delivery / next action |
| --- | --- | --- |
| A1–A4 surfaces | Delivered, native-checked; owner/device review remains | `art/textures/damp-caves-v1` |
| G layouts | Four complete design candidates; owner/Claude review before gameplay hookup | `docs/damp-caves-layout.md`, machine-readable `damp-caves-layout-sections.json` |
| B passages + N1–N3 for this junction | Delivered, native-checked; no live hookup | `art/features/damp-passages-v1`, `art/ui/area-routes-v1`; other areas’ exits remain separate work |
| C dressing | Not produced | Damp wall/ceiling/edge/floor pieces, still-safe drip effect |
| D 2D leftovers | Not produced | Floor 1–2 dressing/landmark/event replacements, including three-knocks; keep each region's style |
| E landmarks | Layout placement notes only; art kits not produced | Sump, weeping wall, drowned drift, rimstone stair, bone silt, wet lost cache |
| F event props | Not produced | Satchel, pearls, seep, ledge and fish state sets |
| H sound | Not produced | Ambience, wet steps, bump, passage and drip sounds |
| I creatures | Placement/encounter proposals only; concepts/models not produced | Concept approval precedes models per brief; no creature rules changed |

## Surface handoff

Four unchanged original albedos and their materials are in `art/textures/damp-caves-v1`; `catalog.json` contains exact paths, mounts/envelopes, draw/triangle costs and numeric wet response. Texture imports cap each at 512px with mipmaps. Material source files are editable; original PNGs, prompts, provenance and hashes are retained. Copies of all editable inputs are local in `build/local-damp-caves-v1/editable-inputs`.

Set a future theme's `wall_face_uv=true`, use the two wall resources and the matching floor/ceiling at 2m cells / 2.2m walls. The wall variant is a **ShaderMaterial**, not StandardMaterial3D: a static opaque two-albedo blend restores the base rock at every tile border and reduces hard adjacent-variant joins. It adds one sample only on variant surfaces; all four textures are already shared. Never add ALPHA to normal cave surfaces. The three other materials are StandardMaterial3D with roughness ≥0.61 and low dielectric specular. No material creates lights, uses TIME, or requires set_motion.

The delivered surfaces use existing LevelBuilder geometry, without new meshes or collision. No normal maps, clearcoat, emission, screen reads or additional reflection passes. Four complete 512px RGBA8 mip chains cost about 5.33 MiB before GPU compression/engine overhead. The wet sheen is restrained; stronger pool reflections belong to explicit later puddle surfaces. Native warm torchlight colors nearby limestone, while neutral/unlit areas carry the cool regional palette. Do not add permanent blue lights merely to force a screenshot palette.

Exact prompts, source output paths, SHA-256 hashes and reference roles: `art/textures/damp-caves-v1/generation.json`. Built-in image generation, original sources, no third-party/private inputs. The source PNGs are unchanged; the tile-border blend is material code, not a claim that the raw textures have perfect geological wrap continuity.

## Layout handoff

`docs/damp-caves-layout.md` supplies shape rules, four ASCII sections, water proposals, named landmark/quest/lair locations, new-creature and ambient placement, a proposed Drowned Mother patrol loop, and a candidate encounter mix. `tools/damp_caves/build_layout_sections.py` regenerates JSON and checks connectivity.

The first world junction is **Abandoned Mines → Damp Caves → Cavern or Fungal Hollows**. Other `>` characters are explicitly section continuations. They do not invent further world destinations. The quartermaster's unlockable surface route targets the **Rest Area beyond Cavern**, as the owner specified. Numeric depth is not an area identity.

All water/encounter weights and named-pack placement are **proposals only**. Default shallow `~` is visual; optional `w` basins have dry bypasses and need a deliberate rule choice. Never silently insert all wet cells into `map.water`: Galleries' authority already changes time/strain/torch behavior. Preserve actual quest footprints, mandatory site placement, current proximity-based quest discovery, existing lair Go in/Back away and the independent routes around optional encounters. New creature models still require approval of their own concept sheets.

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

## Next production batch

C/D: the wall/ceiling/edge/floor dressing, still-safe drips, remaining flat mine/Damp Caves props and three-knocks prop. Then E/F art kits for landmarks/events, H sound and I concept approval/model work. G's water rules, encounter weights and branch return/rejoin details still need owner/Claude review. The distinct exits/signs/glyphs delivered here cover these two Damp Caves links; shared-network N1–N3 for other areas remain future production. Claude retains all live graph/theme/quest/combat hookup.
