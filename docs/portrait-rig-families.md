# Portrait families and complete facial components · #121

The owner chose precise edits to the existing pixels and subsequently spotted a real defect in v2: closed lids left an old outer eye/lash visible, and the rounded mouth sat inside the resting lips. The renderer already swaps one eye and one mouth layer. The problem was artwork: resting features were baked into the character plate, and replacement masks covered only their interiors.

## Current structure

[Portrait registry](../data/portraits/catalog.json) · [art entry point](../art/portraits/README.md)

- **Reusable NPC/minor-character kit:** `average-covered-adult-v1`, nine individually fitted faces with shared body/jerkin. Worried/exhausted variants remain static.
- **Unique heroes:** `unique-mara-v1`, `unique-corin-v1`, `unique-alwen-v1`. Each owns its anatomy, garments and face components. Mara's underlayer uses her same face components.
- Every PortraitSet retains its `rig_kind`, `rig_family`, `face_id` and stable resource path. Sharing a canvas or body never permits sharing another face's animation.

Each animated face now uses a **clean character plate**, with its complete eye openings/lashes and lips removed. Separate neutral components restore the original resting portrait **byte-for-byte**. Half/closed lids and speaking drawings start on that clean surface and replace the complete feature, including outer lashes and lip corners. The rounded mouth retracts the corners; the old resting lip line is absent. Corin's open mouth retains his missing front tooth.

There are 87 runtime PNGs in the twelve `frames-pixel-v3/` folders: twelve clean character plates, twenty-four neutral components and fifty-one animation drawings. All retain the native 192px transparent canvas and original palette. Original character PNGs, v1/v2 frames, rejected generated candidates, shared body/outfit, condition/light passes and playback timing remain intact. No gameplay or save migration is involved. Eighteen static expression resources and flat camp NPC portraits are unchanged.

## Review

[Paused inspector](../art/concepts/portrait-rigs-v1/inspector.html) · [Mara defect/correction](../art/concepts/portrait-components-v3/mara-before-after.png) · [all held drawings](../art/concepts/portrait-components-v3/all-faces.png) · [Godot motion](../art/concepts/portrait-components-v3/godot/motion.gif)

The inspector starts paused on Corin. Previous/Next, arrows and frame buttons hold each drawing beside its resting reference. Enlarged crops and a changed-pixel overlay remain available. **Hide eye and mouth components on the right** exposes the actual clean plate. This control is disabled for static expressions. The title identifies **complete components v3**; reload an old browser tab after pulling.

V2 comparisons and masks remain as history. Their “unchanged outside small masks” checks passed but did not prove full feature replacement: those masks missed old corners and lashes. Do not cite that report as proof that duplicates were absent. Rejected ImageGen atlases remain unwired in [portrait-frames-v2](../art/source/portrait-frames-v2/README.md); v3 uses native pixel edits.

## Rebuilding

[Authoring tool](../tools/art/build_portrait_components.py) · [source footprints/recipes](../art/source/portrait-components-v3/README.md)

Run `build_portrait_components.py --wire`, then `build_portrait_registry.py`. The builder validates immutable original source hashes. Full feature footprints and contours are explicit for each face. Skin fills use unmasked boundaries and the same face's cheek texture, snapped to its existing palette. Masks are clipped to the original silhouette. There is no scaling, atlas fitting, head movement or borrowed facial anatomy.

All four older exporters retain complete v3 character/neutral/animation bindings, rejecting changed original anatomy until components are rebuilt. Static expression exports retain their own drawings. The superseded v2 tool refuses to overwrite v3 bindings. New faces require their own fitted contours and visual review.

## Verification

`validate_portrait_components.py` checks exact resting reconstruction, actual clean underlayers, full feature mattes, original hashes/palette, every simultaneous blink/talk combination, and independent original iris/lip-corner regression points. Each closed eye forms one connected drawing. Native and enlarged held frames were also visually inspected.

All thirty-one resources are compared against `3d1ee08`: only explicit clean-character/neutral/animation texture bindings may differ. Static expressions and all other values remain exact. Godot 4.7.2 passes 450 playback/lifecycle checks and 118 family/ownership checks. The inspector passes 37 desktop/phone-browser checks and retains 18 captures, including the bare face and rounded mouth. Export preservation is checked for all 31 resources. Engine logs are clean. These checks do not replace physical iPhone review or the owner's judgment of the drawings.
