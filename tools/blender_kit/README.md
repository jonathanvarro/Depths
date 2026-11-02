# Local editable Blender kit · #210

Contract and beginner steps: [docs/blender-base-contract.md](../../docs/blender-base-contract.md).
Local review: `build/local-blender-kit-v1/review/inspector.html`.
This is true Blender authoring preparation for both supplied bases, not #206's
Godot clothing shell. No source or derived art is stored in this tool folder.

Use installed Blender5.2.3; no purchase, download, upgrade or external service.
Run from `E:/GitHub/Depths`. The source inputs must already be copied into
ignored `build/local-blender-kit-v1/source`, preserving their original names:
the two Dying FBXs, the supplied female/male Blender references, the small male
mesh FBX, and the34 supplied clips under `source/clips`. Copying is deliberately
separate so the tools never write to the owner's source folders.

```powershell
$blenderKitExe = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$env:BLENDER_USER_RESOURCES = 'E:/GitHub/Depths/build/local-blender-kit-v1/blender-user'
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/audit_sources.py --python-exit-code 1
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/audit_clips.py --python-exit-code 1
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/prepare_masters.py --python-exit-code 1
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/check_and_export.py --python-exit-code 1
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/check_transfer.py --python-exit-code 1
& $blenderKitExe --background --factory-startup --disable-autoexec --python tools/blender_kit/capture_review.py --python-exit-code 1
python tools/blender_kit/prepare_smoke.py
```

Stop if an invoked process returns a failure. `prepare_masters.py` refuses to
overwrite existing masters unless you explicitly append `-- --rebuild`. That
option intentionally recreates them from the FBXs: **do not use it on garment
working copies or use it to erase downstream edits**. Neither preparation nor
validation saves or changes the supplied originals. Embedded source scripts are
disabled. All generated assets remain in ignored build output.

Import the isolated smoke project's two GLBs with Godot4.7.2 `--headless --editor
--import --quit`, then run it with `--script check.gd`. `prepare_smoke.py` copies
the generic check script into that local project; it never loads live Main or
player data. The reports remain local. Finish with:

```powershell
python tools/blender_kit/package_review.py
node tools/blender_kit/check_review.cjs
```

The browser check uses the workspace's installed Playwright/Chrome. Python uses Pillow for the mechanical contact sheet; all other
packaging is standard-library code. Blender scripts use Blender's own bpy.
The screenshots are real CPU renders, without image generation or retouching.

For later garment **working copies**, export without changing the saved file:

```powershell
& $blenderKitExe --background --disable-autoexec 'E:/GitHub/Depths/build/local-blender-kit-v1/female_working.blend' --python tools/blender_kit/export_current.py --python-exit-code 1 -- --name female-working-kit
```

That helper exports the one scene-fit rig and visible meshes carrying the same
`fit_id` and an Armature modifier bound to it. It excludes helpers and writes a
separate local `exports/female-working-kit.glb`. It does not author weights,
retarget, generate coverage, remove hidden body geometry, approve fit or save
the `.blend`. Reimport and inspect it afterward. The strict base regression
checker is for the preserved base masters, not arbitrary finished wardrobes.
Existing named exports are protected unless `--replace` is explicitly supplied.
