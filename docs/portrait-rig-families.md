# Portrait families and paused inspection · #121

Owner noted that Corin and Alwen use different models from the standard portrait kit and that mismatched eyes/mouths become clear when frames are paused. The previous #120 work improved playback/lifecycle, but its full-canvas/neutral-return tests did not prove visual feature alignment. Rig separation and paused inspection were delivered first. The owner then explicitly chose **precise edits to the existing pixels**, preserving the established faces; those repaired drawings are now live.

## Classification

[Portrait registry](../data/portraits/catalog.json) · [art entry point](../art/portraits/README.md)

- **Reusable NPC/minor-character kit:** `average-covered-adult-v1`, nine face IDs, each with neutral/worried/exhausted resources. The body and jerkin really are shared. Each head owns its eye/mouth drawings and fitted condition/light passes. Gameplay role does not set rig compatibility.
- **Unique heroes:** `unique-mara-v1`, `unique-corin-v1`, `unique-alwen-v1`. Each retains its own anatomy/body/garments and facial regions. Mara's underlayer preview resource belongs to the same unique Mara family.
- Every PortraitSet records `rig_kind`, `rig_family`, `face_id`. Resource paths, resting character layers, conditions, lighting, animation timing and gameplay remain unchanged. Only the existing blink/talk texture references point to repaired siblings. Original exporters retain the metadata and corrected bindings on regeneration. No save migration is needed for path-based resources.

## Inspector

[Open the paused inspector](../art/concepts/portrait-rigs-v1/inspector.html) · [Corin mouth comparison](../art/concepts/portrait-rigs-v1/desktop-corin-mouth.png) · [Alwen eyes](../art/concepts/portrait-rigs-v1/desktop-alwen-closed.png)

The inspector starts paused on Corin and separates the two rig categories. Step through exact drawings with Previous/Next, arrows or individual frame buttons. Play is optional. The resting reference remains visible alongside the selected drawing. Enlarged eye and mouth crops use the exact export regions, and a changed-pixel overlay shows the full patch footprint. Switching portrait/family pauses again. Worried/exhausted variants stay static because no matching animation was authored. Embedded PNGs make the comparison work directly from a local file.

## Visual finding and pixel repair

The former broad rectangular patches replaced nearby skin and sometimes brow, nose or stubble detail along with the feature. Shared canvas size did not prevent this. In Corin's former open mouth, the shape/skin footprint changed the neighbouring smile/stubble. Alwen's patches likewise drifted around the eye/lip anatomy. The new drawings begin with the exact resting pixels, so the patch borders and all surrounding anatomy now composite identically.

Two built-in ImageGen atlas candidates were attempted against each exact neutral portrait. They changed face proportions and adjacent skin rather than preserving the target closely enough. They remain **rejected and not wired** in [portrait-frames-v2](../art/source/portrait-frames-v2/README.md). No generated redraw is used by the repair.

There are **51 repaired full192px drawings for twelve faces**: two eyelid and two speaking drawings per reusable face; the three unique heroes also retain their third rounded mouth drawing. The owner-authorized [native pixel source](../tools/art/repair_portrait_pixels.py) records individual ocular centres/socket shapes and lip seam anchors. Lid shading clones native texture from that same face, snapped to its existing palette; lip openings follow the resting seam and preserve the corners. Corin retains his missing front tooth. No head scaling, atlas fitting, gaze shift or borrowed facial parts occurs.

Each runtime sibling lives in its face's `frames-pixel-v2/` folder. Original v1 frames remain preserved. [Resting references, edit masks and per-face recipes](../art/source/portrait-pixel-repair-v1/README.md) stay separate from the runtime textures. Eighteen static worried/exhausted resources and flat NPC portraits remain unchanged and unanimated. Mara's supporting underlayer resource uses the same repaired facial drawings.

[Old/new hero comparison](../art/concepts/portrait-pixel-repair-v1/heroes-before-after.png) · [all exact drawings](../art/concepts/portrait-pixel-repair-v1/all-frames-native.png) · [actual Godot animation](../art/concepts/portrait-pixel-repair-v1/godot/motion.gif)

The older portrait exporters now preserve these bindings and reject a changed resting source until its pixel animation is fitted again. Run `repair_portrait_pixels.py --wire`, then `build_portrait_registry.py` to rebuild the repaired set/inspector. A new face requires its own fitted landmarks; sharing a body never makes facial drawings interchangeable.

## Checks

417 independent pixel checks verify all 51 frames: **25–137 changed pixels per drawing, zero changed outside the fitted lid/lip masks**, full192px transparent canvases, unchanged native palette, and every resting input byte-identical to commit `3d1ee08`. All 31 resources differ only in approved animation texture paths; resting/condition/light bindings and all other fields are unchanged.

450 actual-renderer checks pass for blink/speech/neutral return, hidden/fallen/replaced portraits and the full thirty-set catalogue. Four native registration sheets and a runtime GIF are retained. 118 Godot family/ownership checks and 31 browser checks/14 refreshed desktop/phone captures also pass with clean engine logs. Exporter compatibility was checked against all 31 resources. Native and enlarged held drawings were visually reviewed as well as structurally checked. These checks do not replace the owner's visual review or a physical iPhone test. Unrelated combat/encounter/save work remains untouched.
