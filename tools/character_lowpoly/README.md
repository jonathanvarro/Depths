# Low-poly traveller study · #205

Open **this folder's project.godot** in Godot4.7.2 and press F5. It is independent of the main game. Choose outfit, utility, pose, camera and angle; Idle/blink can be paused. Native controls support mouse/touch and keyboard navigation. The primary review target is a landscape window.

The character is original cross-section/planar geometry, weighted to the #20316-bone rest contract. Native single-surface meshes use a vertex-colour palette. This is one style candidate and one body size, not a finished roster or live integration. The native export includes alternate variants, with caller-controlled visibility. Portable GLBs contain one visible outfit/cape each and fixed standing/seated/reading clips; their palette-material surfaces preserve colour across interchange.

Review: `../../art/concepts/character-lowpoly-v1/inspector.html`.
Findings/limits: `../../docs/lowpoly-character-study.md`.

## Reproduce

Run Godot with this folder as `--path`:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path tools/character_lowpoly --script check.gd -- out=E:/GitHub/Depths/build/lowpoly-headless
```

For actual captures, omit `--headless`, use `--resolution 1440x960`, and set `out=E:/GitHub/Depths/build/lowpoly-review`. A scripted hidden/offscreen launch avoids taking focus; use `Start-Process -WindowStyle Hidden` on Windows. The capture fixture exits automatically. It never starts Main, loads player saves or accesses Depths Settings.

From the repository root, use the installed Python/Pillow and Node/Playwright runtimes:

```
python tools/character_lowpoly/package_review.py
python tools/character_lowpoly/check_sources.py
node tools/character_lowpoly/check_gallery.cjs
Godot_v4.7.2-stable_win64_console.exe --headless --path tools/character_lowpoly --script check_export.gd
```

`check.gd` tests all27 combinations, skin normalization/binding, renderer-baked pose changes, native card sizes, touch-height controls, actual phone window, GLB colour/skin/pose roundtrip and script-free native packing. `check_export.gd` loads that packaged native scene independently. `package_review.py` copies real renders/models by hash and labels a contact sheet; no model painting or generative retouch. `check_sources.py` checks hashes, decoded/nonblank captures, native sizes, rig/animation/skin GLB data and local assets. `check_gallery.cjs` uses the locally installed Chrome/Playwright runtime to exercise gallery choices and narrow layouts.

Physical iPhone performance, arbitrary-animation clipping and final character likeness remain untested. Renderer shader-cache directory and restricted editor-preference warnings are documented in the manifest.
