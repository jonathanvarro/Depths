# Cave formations, roots and fungi · #243

Owner-selected batches built in order, 2026-11-08. Fourteen reusable 3D scenes
are in art/dressing/cave-growth-3d-v1. The local review is
E:/GitHub/Depths/build/local-cave-growth-v1/inspector.html.
START_REVIEW.cmd opens the native light, angle, mount and glow controls.
Editable Blender masters retain individual pieces in the local masters folder.

## Formation set

| Scene | Mount | Triangles |
|---|---|---|
| stalagmite-stub.tscn | Floor | 86 |
| stalagmite-tall.tscn | Floor | 86 |
| stalagmite-broken.tscn | Floor | 68 |
| stalagmite-cluster.tscn | Floor | 258 |
| stalactite-single.tscn | Ceiling | 86 |
| stalactite-cluster.tscn | Ceiling | 258 |
| flowstone-wall.tscn | Wall centre | 178 |
| rubble-cluster.tscn | Floor | 390 |

Stub/tall formations stand approximately 34/95 cm high. The broken form
has a pale exposed mineral cap at about 45 cm. The mixed-height cluster
reaches 68 cm. Their bases are flattened to the floor anchor, with uneven
cross-sections, slight lean and broad mineral facets. Ceiling forms extend
55/65 cm below their anchors. Mount roots are flattened to the ceiling.
The flowstone is a shallow ribbed relief with a tapered, scalloped outline
and wall-return edges. Rubble is a 72 cm wide adaptation of the existing
verified CC0 KayKit model.

## Roots and fungal growth

| Scene | Mount | Triangles |
|---|---|---|
| wall-roots.tscn | Wall centre | 864 |
| hanging-roots.tscn | Ceiling | 864 |
| floor-roots.tscn | Floor | 864 |
| mushroom-clump.tscn | Floor | 366 |
| shelf-fungus.tscn | Wall centre | 168 |
| fungal-mat.tscn | Floor | 526 |

Roots follow irregular curved paths, with different lengths, forks and
tapering radii. Cross-sections are transported along the curves to avoid
roll flips near downward tangents. Wall roots occupy roughly one metre
square. The ceiling fringe extends about 62 cm below its mount. Floor
roots remain low and form a crossed network.

The mushroom clump has three uneven caps and crooked stems. Shelf fungus
has three overlapping, asymmetric brackets with shaded undersides. The low
fungal mat combines subdued growth and small mushrooms. Their olive, pale
mineral and dark underside colours follow the current fungal cave direction.

## Mounts and optional glow

Catalog bounds use Blender X/Y/Z and are checked against Godot’s imported
X/Y/Z after axis conversion. Scene roots are already fitted in metre units.
Floor origins lie at ground level. Ceiling origins sit at the top attachment.
Wall origins mark the centre, with local +Z facing into the room. Some root
cross-sections extend slightly behind the wall so they appear embedded.
Wall envelopes remain shallow. Use real wall normals and roof anchors.

Fungal emission is optional and disabled by default.

```gdscript
piece.glow_enabled = true
piece.set_motion(true)       # optional eight-second cap pulse
piece.set_motion(false)      # fixed emission immediately
piece.glow_enabled = false   # ordinary scene lighting
```

Only fungal caps receive emission. Roots and formations stay static.
Emission adds no Light3D and changes no carried-light bands or supply rules.
Animation stops while the prop is hidden. Disabling motion restores a fixed
value. No scene adds collision, interactions or saved state.

The 26-colour 256 × 128 palette extends the existing mine prop palette.
Opaque geometry uses its shared material and world-space cave grain.
Fungal caps have one additional mesh/material for optional emission.
Other pieces use one surface. Shadows are disabled to follow the existing
mobile decor policy.

## Source and integration handoff

The existing KayKit Dungeon Remastered rubble_half.glb is reused unchanged
as the source for the smaller rubble arrangement. Its licence and original
record are retained under art/third-party/kaykit-dungeon-remastered.
The new catalog records the source SHA-256. CREDITS.md beside the new scenes
records the authored geometry and material changes. Original painted cave,
root and fungal assets remain the visual references.

The remaining forms are authored geometry using the existing mine prop
export helpers. Their command-line behavior is preserved. A fresh run of
the preceding mine builder reproduces its existing models and catalog.
The new exporter can separate cap materials without changing older exports.

Live dressing/theme bindings still use the earlier library. Claude can use
the new mount catalog when connecting these scenes. Preserve sparse seeded
placement, event/passage/stair/arrival exclusions, actual wall anchors and
the current effects setting. Keep thick formations near edges. The room
previews retain a clear central eye-height sightline in a two-metre passage.
Passage roots, movement hazards, floor assignment and gameplay lighting
remain controller-owned.

## Rebuild and review

1. Run tools/cave_growth/build_models.py with Blender --background
   --factory-startup --disable-autoexec --python-exit-code 1, followed by
   -- --workspace E:/GitHub/Depths.
2. Run prepare_review.py --workspace E:/GitHub/Depths with Python/Pillow.
3. Import the isolated project in Godot 4.7.2 and run its check.gd with
   the Mobile renderer. Local masters are excluded from import.
4. Run package_review.py --workspace E:/GitHub/Depths and check_gallery.cjs
   with the workspace argument.

The native review checks actual bounds, UVs, triangle budgets, mounts,
headroom, no added collision/light, glow/still behavior and phone controls.
Its 107 captures cover two lighting modes, three angles, fungal glow states,
three phone/desktop screens and both mounted room compositions. Builder,
helper, source, export and reviewed-catalog hashes are checked during
packaging. Physical iPhone performance and owner visual acceptance remain
review steps.

The 2026-11-08 native review passed 311 checks with clean runtime logs.
Source, tool and export verification passes for all fourteen models.
The browser gallery passed 21 checks, including batch filtering and phone sizes.
