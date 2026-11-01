# Local FBX companion expansion trial · #206

2026-11-01. The owner selected a practical expansion of the supplied rigged FBX: **one expedition outfit, two appearances and a seated animation**. This is an isolated local review; it changes no live character, story, equipment, camp, save or settings resource.

Open `build/local-fbx-trial/review/inspector.html` on the owner's PC. The runnable independent Godot4.7.2 project is `tools/fbx_companion_trial/project.godot`. Local preparation/reproduction: [source instructions](../tools/fbx_companion_trial/README.md).

## Delivered

- Supplied body, hair,65-bone skeleton and16.6167-second idle imported using Godot's FBXDocument. Original FBX/PNG bytes are copied separately into ignored local output and recorded by SHA256.
- One fitted expedition outfit: muted green tunic/sleeves, dark trousers, brown boots, split tunic tails, belt/clasp, field pouches and a small frame pack.
- Two appearance variations: copper hair/warm skin, and a shortened silver crop/cooler skin with a slate headband. Simple eye/brow/mouth geometry is added. These share the source face and body proportions; they are **not independently sculpted identities or approved named companions**.
- New standing,1.6-second sit-down,2-second seated idle and1.6-second stand-up clips on the source rig. The original idle remains available. Sampled root lift keeps soles clear at transition samples; no foot IK or full motion-production quality is claimed.
- Actual rendered front/three-quarter/back/profile, portraits, seated/mid-transition/source-idle views,66 direct animation frames/GIF, native192/96 cards and a1278×590 window capture. Native controls provide pause and timeline scrubbing; bust framing follows the animated head.
- Two script-free local native scene exports include selected appearance, full skin, original idle and the authored animation library. They load without authoring scripts or links to intermediate scene/assets.

The copper setup has2,600 visible triangles across four mesh surfaces; silver/headband has2,624 across five. These are geometry counts, not measured GPU draw calls or a physical-iPhone performance result.

## Fit and technical findings

The FBX body uses **eight** bone influences per vertex, while hair uses four. Source skin tables refer to private bind indices rather than direct skeleton indices. Mesh vertices also have a different scale/up-axis convention from the skeleton. The adapter first uses actual renderer skinning to bake the source rest geometry, remaps influences to a full inverse-rest skin and normalizes transformed normals. It leaves the source rig, hierarchy and idle separate and unchanged.

Clothing uses the body topology and true source weights as an offset shell. Shared position offsets are joined across flat-normal seams, and covered skin triangles are hidden rather than showing through. New split tails use separate thigh weights. This produces a useful fit proof at low cost; it is not a general automatic garment modeller. Added kit and facial placements are fitted specifically to this sample.

Initial inspection caught incorrect four-influence assumptions and flat-normal seam gaps; both were corrected. A timeline range-change signal could overwrite a selected time; the UI blocks that signal during animation changes and checks the regression. Flattening the imported scene-instance marker before native export removed duplicate intermediate-node/resource leaks; native models now have no external resource/script dependency and export checks exit cleanly. Restricted shader-cache creation at `user://vulkan` still emits its environment warning while rendering continues without caching.

## Validation

- Godot4.7.2 Mobile/D3D12 on AMD Radeon RX9070XT:313 checks, zero failures, exit0. Headless:311 checks, zero failures, clean exit.
- Source bind/layout preservation, normalized weights/bone IDs, shared rest contract and identical reused outfit, covered/exposed triangle partition, source idle/added clips, finite deformation and bounded geometry are checked on both looks.
- Transition checks include between-key samples, all authored clip phases, full-source-idle samples, sole clearance tolerance and independent CPU skin calculations. Actual renderer-baked garment bounds match the CPU calculation.
- Both packed native models reload without authoring/intermediate dependencies and play their seated animation. Native touch controls remain44px high with a usable landscape-phone viewport.
- Local source/capture/model/link validation:194 checks. Chrome gallery selection, motion decoding, narrow layout and links:18 checks, zero failures/JavaScript errors. Actual portrait/native image sizes, nonblank output,66 motion frames and unchanged copied source hashes pass.

The retained source/capture records and check reports are local beside the gallery. The GIF contains resized/encoded actual renderer frames, without synthesized frames or retouched model imagery.

## Scope and privacy

Supplied source files, derived models, baked meshes, texture copies, captures and GIF **remain local in git-ignored `build/local-fbx-trial`**. Only reusable authoring/check scripts, the gallery template and this written handoff are committed. The earlier high-detail GLB is excluded from the trial and untouched.

The code is an adapter for this supplied sample's body/hair names, proportions and Mixamo rig, not an arbitrary-FBX production pipeline. Wider body coverage, independently shaped heads, facial animation, cloth/collision simulation, more equipment, polished hand/seat contact, locomotion, live bindings and physical-device testing remain separate. Owner review should judge this source model's style and the reuse approach before expanding the roster. Existing #181/#197–#201 portrait work is unaffected.
