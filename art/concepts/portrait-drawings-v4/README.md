# Portrait drawing refinement · #124

[Mara v3/v4 comparison](mara-before-after.png) · [native held drawings](all-faces.png) · [96px card sheet](card-size.png) · [enlarged features](features-enlarged.png) · [actual Godot 192](godot/native192-group0.png) · [Godot 96](godot/native96-group0.png) · [runtime motion](godot/motion.gif) · [paused inspector](../portrait-rigs-v1/inspector.html)

Claude's review correctly distinguished successful v3 component separation from flat, overly graphic animation. V4 preserves painted lip tissue around smaller shaded openings, faint teeth and softly contracted lips; local lower-lip detail drops a few pixels. Lids use curved tapered lashes and soft skin shading; half blinks retain original lower iris pixels. Corin's profile, beard texture and missing tooth are checked independently.

**Recruit correction:** live recruit sets already had exactly two talk frames. The neutral “round” in the earlier review was a fallback in the sheet. These sheets leave the unauthored column blank and label it; no duplicate neutral frame is played. Main heroes retain three distinct shapes.

`components.json` records all 51 new drawings and unchanged v3 clean/neutral references. `pixel-validation.json` passes 658 source/rig/composition/iris/mouth/profile regressions. Actual Godot capture/playback reports, eight 192/96px held sheets, four older-format registration sheets and a motion GIF are retained. Individual motion PNGs are ignored intermediates. Canvas, mattes, resting reconstruction, timing and card filtering stay unchanged. The comparison/technical checks support visual review, not automatic aesthetic approval.

Rebuild with `refine_portrait_drawings.py --wire`, then `build_portrait_registry.py`. Run `validate_portrait_drawings.py`, `check_portrait_export_bindings.py`, `validate_portrait_registry.py`; import in Godot 4.7.2 and run `capture_portrait_drawings.gd`, `check_portrait_coherence.gd -- res://art/concepts/portrait-drawings-v4/godot`, then package its motion with `build_portrait_motion_review.py`. [Full handoff](../../../docs/portrait-rig-families.md).
