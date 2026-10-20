# Paused portrait inspection · #121

Open `inspector.html` directly in a browser. All reference PNGs are embedded, so the changed-pixel view works without a server or cross-origin permissions. It starts **paused** on Corin. Previous/Next or arrow keys hold each exact frame; Play/Space is explicit. Neutral reference and selected frame use the same canvas, eye/mouth crops and pixel scale.

Family selector separates three unique heroes from the nine reusable faces and their static expression resources. All artwork is read from the actual PortraitSets. The tool does not correct, interpolate or conceal misaligned pixels. Static expressions have no borrowed neutral blink/talk frames.

Rebuild with `tools/art/build_portrait_registry.py`. Editable `layout.html` and `inspector.js` sit beside the generated HTML. The live references now use owner-authorized pixel repairs: 51 drawings preserve the exact resting face outside fitted lid/lip masks. 31 browser checks/14 refreshed desktop/phone captures and Godot family/ownership checks supplement native/enlarged visual review. [Handoff](../../../docs/portrait-rig-families.md).
