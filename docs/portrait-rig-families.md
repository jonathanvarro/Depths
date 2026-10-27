# Portrait families and facial drawings · #121 / #124

**Current refinement (#124):** Claude correctly identified that v3 removed duplicate features but its flat mouths/lids did not match the painted resting faces. The live v4 drawings retain original lip colour, shading and beard texture around smaller openings, short tooth hints and softly contracted lips. Lower lip/detail moves by a few native pixels within the existing matte; the head/jaw silhouette stays registered. Lids have curved tapered lashes, soft creases and native skin texture; half blinks retain the original lower iris. Corin's far lid ends before the side cheek and his tooth gap stays dark. Recruits already declared two talk frames; the neutral “round” in Claude's review sheet was a preview fallback, not a runtime frame. New review sheets leave that column blank and label it honestly.

[V4 Mara comparison](../art/concepts/portrait-drawings-v4/mara-before-after.png) · [native drawings](../art/concepts/portrait-drawings-v4/all-faces.png) · [96px card review](../art/concepts/portrait-drawings-v4/card-size.png) · [actual Godot 192/96px captures](../art/concepts/portrait-drawings-v4/godot/) · [motion](../art/concepts/portrait-drawings-v4/godot/motion.gif)

The owner chose precise edits to the existing pixels and subsequently spotted a real defect in v2: closed lids left an old outer eye/lash visible, and the rounded mouth sat inside the resting lips. The renderer already swaps one eye and one mouth layer. The problem was artwork: resting features were baked into the character plate, and replacement masks covered only their interiors.

## Current structure

[Portrait registry](../data/portraits/catalog.json) · [art entry point](../art/portraits/README.md)

- **Reusable NPC/minor-character kit:** `average-covered-adult-v1`, nine individually fitted faces with shared body/jerkin. Worried/exhausted variants remain static.
- **Unique heroes:** `unique-mara-v1`, `unique-corin-v1`, `unique-alwen-v1`. Each owns its anatomy, garments and face components. Mara's underlayer uses her same face components.
- **Unique Fixer recruit rigs (#163):** three red-coat busts following the owner's supplied concepts. Each owns its garments, tilted face registration and complete components; [Fixer handoff](fixer-portraits.md). Unique is an art classification, not a new gameplay role or story identity.
- Every PortraitSet retains its `rig_kind`, `rig_family`, `face_id` and stable resource path. Sharing a canvas or body never permits sharing another face's animation.

Each animated face now uses a **clean character plate**, with its complete eye openings/lashes and lips removed. Separate neutral components restore the original resting portrait **byte-for-byte**. Half/closed lids and speaking drawings start on that clean surface and replace the complete feature, including outer lashes and lip corners. The rounded mouth retracts the corners; the old resting lip line is absent. Corin's open mouth retains his missing front tooth.

The 87 active runtime PNGs comprise twelve clean plates and twenty-four neutral components in `frames-pixel-v3/`, plus fifty-one refined animation drawings in `frames-pixel-v4/`. Native 192px canvases, original palettes and all v3 component mattes remain exact. Older artwork is retained as history. Body/outfit sharing, conditions/lighting, playback, card filtering and save paths are unchanged. Eighteen static expression resources and flat camp NPC portraits stay unanimated.

## Review

[Paused inspector](../art/concepts/portrait-rigs-v1/inspector.html) · [historical v2 duplicate correction](../art/concepts/portrait-components-v3/mara-before-after.png)

The inspector starts paused on Corin. Previous/Next, arrows and frame buttons hold each drawing beside its resting reference. Enlarged crops and a changed-pixel overlay remain available. **Hide eye and mouth components on the right** exposes the actual clean plate. This control is disabled for static expressions. The title identifies **textured drawings v4**; reload an old browser tab after pulling.

V2 comparisons and masks remain as history. Their “unchanged outside small masks” checks passed but did not prove full feature replacement: those masks missed old corners and lashes. Do not cite that report as proof that duplicates were absent. Rejected ImageGen atlases remain unwired in [portrait-frames-v2](../art/source/portrait-frames-v2/README.md); v3 uses native pixel edits.

## Rebuilding

[Current authoring tool](../tools/art/refine_portrait_drawings.py) · [v4 contours/recipes](../art/source/portrait-drawings-v4/README.md) · [frozen v3 component sources](../art/source/portrait-components-v3/README.md)

Run `refine_portrait_drawings.py --wire`, then `build_portrait_registry.py`. The tool validates immutable original hashes, reads v3 clean/neutral/matte references unchanged, and fits native source lip tissue around a modest opening. Local integer sampling preserves texture; no skin/beard blur, full-head scaling, generated redraw or atlas fitting is used. Half lids retain actual original iris pixels, and curved lids use local skin texture/palette. The v3 builder refuses to overwrite the frozen components while v4 is live.

All four older exporters preserve v3 clean/neutral plus v4 animation bindings, rejecting changed original anatomy until refitted. Static expression exports retain their own drawings. The archived v2 tool refuses to overwrite its references. New faces require their own fitted contours and visual review.

## Verification

`validate_portrait_drawings.py` passes 658 checks for original and v3 source preservation, exact neutral reconstruction, full mattes, original palette, actual simultaneous composition, connected curved lashes, visible original lower iris, distinct declared mouths, Corin's profile/beard/teeth and untouched timing/filter code. The historical v3 validator/report remains preserved; neither report certifies visual style. All twelve faces were inspected held at native, enlarged and 96px card sizes.

All thirty-one resources are compared against `3d1ee08`: only explicit clean-character/neutral/animation texture bindings may differ. Static expressions and all other values remain exact. Godot 4.7.2 passes 450 playback/lifecycle, 118 ownership and 40 native/card-capture checks. The inspector passes 37 browser checks and retains 18 captures. Export preservation is checked for all 31 resources. Engine logs are clean. The 96px nearest review is retained without changing card filtering; physical iPhone review and the owner's judgment remain separate.
