# Portrait families and paused inspection · #121

Owner noted that Corin and Alwen use different models from the standard portrait kit and that mismatched eyes/mouths become clear when frames are paused. The previous #120 work improved playback/lifecycle, but its full-canvas/neutral-return tests did not prove visual feature alignment. This pass makes that distinction explicit.

## Classification

[Portrait registry](../data/portraits/catalog.json) · [art entry point](../art/portraits/README.md)

- **Reusable NPC/minor-character kit:** `average-covered-adult-v1`, nine face IDs, each with neutral/worried/exhausted resources. The body and jerkin really are shared. Each head owns its eye/mouth drawings and fitted condition/light passes. Gameplay role does not set rig compatibility.
- **Unique heroes:** `unique-mara-v1`, `unique-corin-v1`, `unique-alwen-v1`. Each retains its own anatomy/body/garments and facial regions. Mara's underlayer preview resource belongs to the same unique Mara family.
- Every PortraitSet now records `rig_kind`, `rig_family`, `face_id`. Resource paths, existing texture bindings, neutral portraits, animation timing and gameplay are unchanged. Original exporters retain the metadata on regeneration. No save migration is needed for path-based resources.

## Inspector

[Open the paused inspector](../art/concepts/portrait-rigs-v1/inspector.html) · [Corin mouth comparison](../art/concepts/portrait-rigs-v1/desktop-corin-mouth.png) · [Alwen eyes](../art/concepts/portrait-rigs-v1/desktop-alwen-closed.png)

The inspector starts paused on Corin and separates the two rig categories. Step through exact drawings with Previous/Next, arrows or individual frame buttons. Play is optional. The resting reference remains visible alongside the selected drawing. Enlarged eye and mouth crops use the exact export regions, and a changed-pixel overlay shows the full patch footprint. Switching portrait/family pauses again. Worried/exhausted variants stay static because no matching animation was authored. Embedded PNGs make the comparison work directly from a local file.

## Visual finding and remaining repair

The current broad rectangular patches replace nearby skin and sometimes brow, nose or stubble detail along with the feature. Shared canvas size does not prevent this. In Corin's open mouth, for example, the mouth shape/skin footprint extends beyond a small lip gesture and changes the neighbouring smile/stubble. Alwen's patches likewise drift around the eye/lip anatomy. The paused inspector is intended to expose these problems, not certify them as corrected.

Two new built-in ImageGen atlas candidates were attempted against each exact neutral portrait. They changed face proportions and adjacent skin rather than preserving the target closely enough. They are **rejected and not wired**. Sources, exact prompts, edit-target paths and rejection rationale remain in [portrait-frames-v2](../art/source/portrait-frames-v2/README.md). Original live pixels remain intact.

An owner preference question is pending: **precise pixel edits to the existing layers** (recommended to retain these identities), or a complete coordinated redraw of each unique portrait/animation. The image-editing tool requires explicit instruction before switching to direct pixel editing; no such edits were made while waiting. Do not close #121 or describe the visual mismatch as fixed. After repair, inspect every held frame at native/enlarged scale, confirm lip corners/eye sockets and boundaries, then repeat the actual renderer checks. Do not borrow recruit eye/mouth frames for unique heroes or vice versa.

## Checks

31 browser checks pass at desktop and phone dimensions: paused hold, exact stepping, explicit play, family separation, static expression handling, changed-pixel canvas access and 44px controls; 14 review captures retained. Godot verifies all 30 live resources plus Mara's supporting underlayer resource for metadata, shared-body references and face-owned frame paths. These are structural checks, not visual acceptance of the current drawings. Unrelated in-progress combat/encounter/save work is left untouched.
