# One finished-direction low-poly character study · #205

2026-11-01. Follow-up to #203, after the owner selected a deliberately low-poly direction. This is an **actual reusable 3D style study**, not a concept painting or an approved named likeness. The male silver-streaked traveller is loosely Rook-inspired. Existing approved Fixer portraits are not replaced or used as model textures.

[Overview](../art/concepts/character-lowpoly-v1/overview.png) · [Review gallery](../art/concepts/character-lowpoly-v1/inspector.html) · [Independent project](../tools/character_lowpoly/project.godot) · [Portable traveller](../art/concepts/character-lowpoly-v1/traveller-0.glb)

## Visual direction

An angular, narrow-eyed face, swept dark hair with a silver streak, asymmetric brows, small moustache/goatee and a cheek scar. Burgundy split coat, ochre waistcoat, slate neckerchief, small belt pouches and tall worn-leather boots. The medium outfit is muted green quilted cloth; heavy equipment adds a faceted breastplate, shoulder plates and forearm guards. Identity colours and face remain consistent when the outfit changes.

Geometry is original and reproducible from authored cross sections, individually shaped face/hair planes and a vertex-colour palette in `tools/character_lowpoly/character.gd`. No supplied reference image, outside model, image-generation master or commercial kit was used. Flat normals are intentional. This pass establishes a style candidate; it does not equal the detail of painted portraits.

## Reuse and deliverables

| Element | Coverage |
|---|---|
| Body | One adult body shape, same 16 bone names and rest transforms as #203 |
| Joints | Four-slot skin arrays, two active influences across cloth elbows, shoulders, waist and knees; 3,612 genuinely mixed-weight vertices across all variants |
| Geometry | Default traveller/cape/standing: 2,642 visible triangles, five single-surface mesh instances; all hidden variants together: 4,523 triangles, eleven instances |
| Wardrobe | Three outfits, each one mesh/surface in the native project |
| Utility | Shield, segmented cape, frame pack; one selected at a time |
| Poses | Standing, seated and reading; native AnimationPlayer pose clips plus review-state switching |
| Face | One shaped head and replacement open/closed eye meshes; idle head motion/blink, no lip sync or broad emotion set |
| Review | Front, three-quarter, profile and back; bust/full figure; actual 192px and 96px cards; 1278×590 window capture |
| Native export | Script-free `traveller.tscn`, complete rig, all hidden wardrobe/utility/prop variants, and three pose clips |
| Portable export | Three independent GLBs, one visible outfit/cape each, skin and three pose clips; no hidden prop/eye/wardrobe variants |

Bone compatibility was preserved rather than changing the original rest contract. Surface counts are geometry organization counts, **not measured GPU draw calls or an iPhone benchmark**. Physical iPhone testing remains outstanding. The review uses one body size; broader, shorter and differently proportioned bodies need separate garment fitting.

## Quality and portability checks

Godot **4.7.2 / Mobile / D3D12**, AMD Radeon RX 9070 XT: **719 checks, zero failures**, exit 0. All 27 outfit/utility/pose combinations are exercised. Checks include exclusive variants, finite transforms, normalized weights, actual baked-mesh deformation when seated, true phone window dimensions, native card captures and portable reimported rig/pose/palette state. Source hashes and the exact report accompany the gallery.

Visual inspection covered face/figure, seated plate, reading hands/book, cape profile, frame-pack back, native96 face, phone framing and the reimported portable model. The coat is split over each thigh to bend across the lap. Rigid armour bridges cloth joints; fingers are fixed. The reading pose moves the hands inward to the ledger. This is a selected-pose fit review, not collision-free certification for arbitrary animation or equipment.

Portable export revealed a concrete issue: Godot's runtime GLB reimport retained `COLOR_0` but disabled its material vertex-colour use, making the first reimport white. The portable siblings now use palette-colour material surfaces, verified after reimport and in the retained capture. They have more surfaces than the native model and are editing/interchange assets, not the optimized runtime representation. Colour conversion follows the native sRGB palette. The export pipeline uses Godot's [documented GLTFDocument API](https://docs.godotengine.org/en/4.7/classes/class_gltfdocument.html).

The native scene can load independently of the authoring scripts, with explicit skin/skeleton paths and functioning seated pose. Headless validation passes 688 checks; packaged source/capture checks pass 104, and Chrome gallery checks pass 33 with no failures or JavaScript errors. The portable pose clips contain fixed poses, not locomotion, pose transitions or automatic prop visibility. In either export, callers must map outfit, utility, eye and book visibility; only the isolated project's controller does this automatically.

The restricted editor could not save its preferences, and the renderer could not create `user://vulkan` shader-cache storage. Rendering continued without that cache, exit 0. These environment warnings are retained in the manifest; renderer logs are not claimed error-free. No player saves or main-game preferences were loaded.

## Remaining decisions

Review the face, proportions, faceting and colours before multiplying this kit across the cast. This style is intentionally simplified; hair/face silhouette and outfit colour carry identity at camp scale, while the existing illustrations can continue serving story moments. There is no automatic conversion of painted artwork to fitted models.

Still absent: broad expressions, flexible fingers, walking/combat animation, UV textures, cloth/collision simulation, equipment-ID binding, body-shape coverage, live camp/portrait integration and physical-device profiling. No named biography, class mechanics, equipment rules or existing portrait resources changed. #181 and #197–#201 remain separate.
