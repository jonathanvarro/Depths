# Paused portrait inspection · #121

Open `inspector.html` directly in a browser. All reference PNGs are embedded, so the changed-pixel view works without a server or cross-origin permissions. It starts **paused** on Corin. Previous/Next or arrow keys hold each exact frame; Play/Space is explicit. Neutral reference and selected frame use the same canvas, eye/mouth crops and pixel scale.

Family selector separates three unique heroes from the nine reusable faces and their static expression resources. All artwork is read from the actual PortraitSets. The tool does not correct, interpolate or conceal misaligned pixels. Static expressions have no borrowed neutral blink/talk frames.

The title identifies **textured drawings v4** (#124). **Hide eye and mouth components on the right** shows the unchanged v3 clean character plate; neutral components restore the original exactly. Refined native lip tissue and curved lids replace the flat v3 animation drawings. The control is disabled for static expressions. Recruits show only their two authored talking shapes, with no neutral fallback labelled round. Reload an already-open tab after an update.

Rebuild with `tools/art/build_portrait_registry.py`. Editable `layout.html` and `inspector.js` sit beside the generated HTML. 37 browser checks/18 desktop/phone captures and Godot family/ownership checks supplement native/enlarged visual review. [Handoff](../../../docs/portrait-rig-families.md).
