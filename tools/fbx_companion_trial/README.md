# Local FBX expedition trial · #206

Open this folder's project.godot in Godot4.7.2 and press F5 **after local preparation**. The owner's supplied files and all derived art live under ignored `build/local-fbx-trial`; they are not part of Git. A clone without local assets displays a preparation message instead of loading Main or player data.

The prepared trial has one body/face shape and one fitted outfit, with copper hair and a silver crop/slate-band variant. It preserves the source idle and adds standing, sit-down, seated idle and stand-up clips. Pause and scrub the timeline, inspect portraits, or turn to the back/profile. No live companion assignment or appearance approval is implied.

## Local preparation

From the repository root:

```powershell
./tools/fbx_companion_trial/prepare.ps1 -SourceFbx 'C:/path/to/Idle.fbx' -TexturePng 'C:/path/to/BodyTexture.png'
```

Pass `-Godot` if the4.7.2 console executable lives elsewhere. The helper copies source bytes into ignored output, records original hashes and runs the engine offscreen to import the FBX and bake its rest geometry. It needs a real renderer, not `--headless`. The rest bake reconciles the source's centimetre/Z-up mesh bind matrices with its larger Y-up skeleton. The original file and rig/idle are preserved separately.

This is a **specific adapter for the supplied body/hair and Mixamo-named rig**, not a general automatic clothing tool for arbitrary FBX files. Mesh names, dimensions, garment selection and facial detail placement are sample-specific.

## Review and reproduce

- Open `../../build/local-fbx-trial/review/inspector.html` for actual renders, a66-frame sit/stand GIF, native96/192 portraits and a phone-shaped capture.
- Open this project and use Animation, View, Angle, Pause and the timeline for live review.
- `build/local-fbx-trial/appearance-0.tscn` and `appearance-1.tscn` are script-free native models with full skin, source idle and authored clip library. Their visibility is already selected for each appearance.

Run Godot with `--path tools/fbx_companion_trial --script check.gd` for validation; add `--headless` for the independent CPU skin checks. The renderer version also compares the actual baked garment bounds with independently calculated weighted vertices. Run with `--script capture.gd` without headless to recreate retained views, native portraits and66 motion frames. Use an offscreen `Start-Process -WindowStyle Hidden` launch, as in prepare.ps1, to avoid taking focus.

Then from the repository root, with Python/Pillow and Node/Playwright:

```
python tools/fbx_companion_trial/package_review.py
node tools/fbx_companion_trial/check_gallery.cjs
python tools/fbx_companion_trial/check_review.py
```

The packager crops/resizes/labels real screenshots and GIF-encodes direct renderer frames. It does not generate or retouch character artwork. Browser tests use locally installed Chrome; the Node dependency path follows this workspace's bundled runtime.

## Implementation limits

The body has eight bone influences per vertex; hair has four. The adapter preserves those layouts and remaps skin-private bind IDs to the full65-bone rig. Clothing reuses the body topology/weights as an offset shell, with joined offsets along coincident face edges. Covered source triangles are hidden. Added tunic tails, belt, pouches, field pack and face/headband details have their own rig weights.

Two colour/hair variations share the same face/body, not independent sculpted identities. Fingers retain source articulation but the new seated pose is simple. Sampled root lift keeps boot soles clear; there is no foot IK, cloth simulation or universal collision guarantee. The native models are review assets, not integrated equipment resources. Physical iPhone performance is untested. Restricted shader-cache storage emits a warning while rendering continues.
