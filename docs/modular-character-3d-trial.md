# Modular 3D companion trial · #203

2026-11-01. Owner requested a practical trial of basic shared 3D characters and wardrobes. This delivery is an **isolated technical blockout**, not an approved character style or replacement of the current painted portraits.

[Overview](../art/concepts/character-3d-trial-v1/overview.png) · [Review gallery](../art/concepts/character-3d-trial-v1/inspector.html) · [Runnable project](../tools/character_3d_trial/project.godot) · [Source instructions](../tools/character_3d_trial/README.md)

## What was built

| Component | Trial coverage |
|---|---|
| Identity | Two simple distinct heads: dark hair/silver streak/moustache and cropped grey hair/broader jaw; loosely Rook/Branna-inspired, not approved likenesses |
| Body/rig | One shared body proportion set, identical 16-bone hierarchy and rest transforms |
| Wardrobe | Three complete upper-body outfits: travel cloth, padded medium and heavy plates |
| Utility | Mutually exclusive shield, cape and frame pack, attached to the appropriate bone groups |
| Poses | Standing, seated and reading, applied to either identity without redrawing outfits |
| Presentation | Front/three-quarter/back, full body and portrait cameras; simple blink/talk toggle |
| Card exports | Actual 192px and 96px renderer outputs for both identities in all three outfits |
| Source | Original procedural low-poly meshes/materials; no external models or image-generation masters |

The independent Godot project in `tools/character_3d_trial` assembles and displays the trial. Open its own project.godot, not the main Depths project. Everything is recreatable from source; the review folder also has two standalone static native scene snapshots without scripts. Its `.gdignore` and `tools/` export exclusion protect the live game.

## Findings

**Reuse works:** the same garment/accessory/pose definitions produce both companions and both presentation types. Changing equipment retains the head identity. The two models use one body size in this trial; clothing across different body proportions remains untested.

**Visual quality is not established:** the faces are primitive blockouts and materially simpler than accepted 2D art. This demonstrates assembly, not an adequate final portrait style. Rigid bone-attached parts reveal seams and joint gaps. The cape does not bend, fingers are coarse, and hand/book and pack/bench fits are approximate. These limits should remain visible in owner review, not be presented as production-ready results.

**Performance is not established:** the trial reports approximately 10k triangles and 116 mesh nodes per assembled identity including hidden variants. Many primitive surfaces/objects are an authoring convenience; a production kit needs merged compatible surfaces, material/draw-call budgets and actual iPhone profiling. Desktop phone-shaped captures only demonstrate framing.

**Integration is intentionally absent:** no live portraits, PortraitSet resources, main scene, camp occupants, equipment rules, source reference images, player saves or preferences were changed. No skeleton retargeting across externally authored models, smooth skinning, emotion library, cloth simulation or automatic cast conversion is claimed.

## Checks and review

- The isolated renderer checks all 27 outfit/utility/pose combinations for each of two identities, bone/rest compatibility, finite poses, correct seated pelvis height, exclusive choices, blink/talk reset, touch-height controls and nonblank portrait exports.
- Actual Godot **4.7.2 Mobile / D3D12**, AMD Radeon RX 9070 XT: **1,943 assertions, zero failures**, exit 0. Captures include 1280x800 desktop and 1278x590/1334x750 window shapes, plus native card sizes. Structural checks do not certify absence of all clipping. Headless run: 1,884 assertions, zero failures.
- Reviewed standing, seated, reading, back and portrait renders. Inspection caught an absolute-pose pelvis error, a mouth scale overwrite and a blank separate viewport; corrected and added regression assertions before retaining captures.
- Renderer emits a sandbox shader-cache-directory warning (`user://vulkan`) and continues without cache. This is recorded in the manifest; no claim of an error-free renderer log. The independent project never accesses Depths user data.
- `check_sources.py` passes 104 checks for unchanged capture/export hashes, PNG decode and native card sizes/detail, independent exported scenes, all gallery image states and local links. Headless Chrome passes 34 gallery selection/image-decode/layout checks at 1280/736/360px with no JavaScript errors.

Reproduction commands are in the source README. `package_review.py` copies actual renders byte-for-byte and creates a labelled overview; it does not invent or retouch model imagery. Original capture/model hashes and limits are in `manifest.json`.

## Recommendation for the next decision

Keep the current 2D production pipeline while judging this trial. If the reusable wardrobe is attractive, test **one authored skinned body, one well-shaped face and three fitted outfits** before converting any named companion. The quality comparison should be the face at 96px beside an approved existing portrait; the fit comparison should include seated/reading poses and all utility choices. Body-shape expansion and mobile profiling follow that proof.

No additional production character work is authorized by this report alone. #181 and #197–#201 remain the existing cast/portrait tasks; this technical trial does not close or replace them.
