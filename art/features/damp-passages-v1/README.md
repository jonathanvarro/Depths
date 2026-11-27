# Damp Caves passages and destination exits (#302)

Original Blender-authored geometry and code-native glyphs for brief B1–B4 and N1–N3 for the Damp Caves junction. No new third-party/private model, source pixels, animation or generated bitmap is used. Existing original worked-prop primitives from `tools/mine_props` / `tools/mine_polish` were adapted into registered meshes. Rock material reuses the original albedo already recorded in `art/textures/damp-caves-v1/generation.json`.

## Delivered pieces

| Scene | Presentation | Triangles / visible draws |
| --- | --- | --- |
| `cavern-onward.tscn` | Water-cut shaft, recessed ledges, rope handhold, Cavern marker | 2010 / 2 |
| `cavern-return.tscn` | Wet rope ladder to an upper throat, Damp Caves marker | 2366 / 2 |
| `hollows-onward.tscn` | Low eroded crawl, fungal growth, Hollows marker, full floor apron | 1606 / 2 |
| `hollows-return.tscn` | Fungal-side crawl back toward wet stone, Damp Caves marker | 1273 / 1 |
| `curtain-intact.tscn` | Hanging wet root/fibre tangle; tear/burn art role, not calcite | 1758 / 1 |
| `curtain-opened.tscn` | Torn side/top fragments, real clear central space | 680 / 1 |
| `siltfall-blocked.tscn` | Fractured limestone slab in silt and fallen rubble | 1370 / 1 |
| `siltfall-cleared.tscn` | Registered low edge banks with the central slab removed | 728 / 1 |

`water-cut-shaft.tscn` and `wet-rope-ascent.tscn` are explicit aliases for B3/B4. They reuse the corresponding signed Cavern-route geometry. The `.glb` model files can be instanced separately when adapting a future route. Canonical labels and pairing hints are in `catalog.json`; they are not bound world-area IDs.

All features use metric floor-centre / **−Z forward**, a 2m cell and 2.2m wall envelope. LevelBuilder rotates the whole feature for an east–west corridor. This differs from independent wall decor's +Z out-of-wall mount. The shaft reaches −0.91m; its apron has a real aperture and its opaque black water is below the footholds. The onward crawl supplies a complete tile at floor level. Both return scenes retain the builder's floor; the crawl return has no duplicate apron. The rope ascent's upper cap joins the `ceiling` group for overhead hide/restore.

`appearance.gd` exposes static `set_motion(enabled)` and immediate `set_state(value, animate=false) -> bool`. Curtain states are `intact/opened`; siltfall states are `blocked/cleared`. Valid states can be set before entering the tree. Refusing invalid state strings does not change the current state. No scene assigns collision, travel, water effects, light, RNG, quest state or saved flags. The existing caller selects/open/clears/places the artwork.

`wet-passages.gdshader` reads physical UVs, material family/seed in UV2 and vertex colour. Its static limestone relief is derived from the same mipmapped albedo using height derivatives; no extra normal-map texture is allocated. It uses no alpha writes, emission, clock, screen reads or new reflection passes. Ground aprons clone the caller's ground material, with world-space triplanar sampling for StandardMaterial3D. Do not put a floor plane over the shaft. Keep default way-up/down glow with the game; the art creates no lights.

## Signs and map identity

Raised 3D chalk marks distinguish **Cavern** (cave arch), **Fungal Hollows** (fungal cap) and **Damp Caves** (paired drops). Their shapes match the original SVGs in `art/ui/area-routes-v1`, with area and transition versions. The transition arrow means a change of area, not guaranteed numeric descent. Glyphs render at 16/24/32 pixels. `sign_label` is an art hint; there is no expensive TextMesh lettering or flat billboard on the 3D sign. The caller should display `interaction_label` before commitment so the player knows the full destination name.

## Review and rebuild

- Editable separate-piece Blender masters: `E:/GitHub/Depths/build/local-damp-passages-v1/masters` (local only).
- Native gallery: `E:/GitHub/Depths/build/local-damp-passages-v1/inspector.html`.
- Builder: `tools/damp_caves/build_passages.py` through Blender 5.2 background; then `python tools/damp_caves/prepare_passages.py`.
- Native checks: `tools/damp_caves/passage_check.gd`, through `tools/testing/background_godot.py` on a private desktop.

**274 native Godot 4.7.2 Mobile/D3D12 checks pass** with 65 actual captures. Bounds, budgets, UV/colour data, restore-before-ready, invalid states, central clearance to 1.85m, shaft/apron floor rays, paired marker metadata, canopy hide/restore, exact still poses, both real LevelBuilder corridor orientations, actual open-passage replacement and glyphs at phone scale are covered. Private profiles, no owner save/input affected. Desktop phone-shaped renders do not establish physical iPhone performance. No live graph, map or theme binding has been changed.
