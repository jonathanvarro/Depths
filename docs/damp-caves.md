# Damp Caves: production handoff (#302)

2026-11-26 · First delivery on `codex/damp-caves-surfaces`, based on Claude's brief at `aca0d4ce`. The owner asked to start the larger list; this delivery completes a bounded first batch, not the whole floor. Claude retains live hookup and rules. Existing fungal files remain intact for the fungal side region.

## Production status

| Brief | Status | Delivery / next action |
| --- | --- | --- |
| A1–A4 surfaces | Delivered, native-checked; owner/device review remains | `art/textures/damp-caves-v1` |
| G layouts | Four complete design candidates; owner/Claude review before gameplay hookup | `docs/damp-caves-layout.md`, machine-readable `damp-caves-layout-sections.json` |
| B passages | Not produced; next production batch | Wet fibrous curtain, obstruction, shaft and ascent |
| C dressing | Not produced | Damp wall/ceiling/edge/floor pieces, still-safe drip effect |
| D 2D leftovers | Not produced | Floor 1–2 dressing/landmark/event replacements; keep each region's style |
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

## Next production batch

Proceed with B's four feature sets using the existing floor-center/−Z convention. Favor a visibly **fibrous wet root/slime curtain** for B1 so the existing burn/tear role makes sense; calcite stone should not inherit web-burning behavior. B2 needs real blocked/cleared art, B3 a recessed water-cut descent with a ledge, and B4 a wet rope ascent. Keep existing passage/traversal and way-up/down glow caller-owned, with no art-side collision or RNG. Then build C's shared dressing pieces and use them to complete D/E/F. Creature concepts can be prepared for review while props progress; models follow explicit concept approval.
