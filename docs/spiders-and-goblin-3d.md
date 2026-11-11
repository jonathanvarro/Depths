# 3D spider family and goblin base (#255 / #251)

Open [the local gallery](E:/GitHub/Depths/build/local-spiders-goblin-v1/inspector.html) to step through rendered poses, compare the spiders at the same scale, and inspect the current combat board at phone sizes. `START_REVIEW.cmd` beside it opens the native inspector with playback, lighting and equipment controls. Editable Blender masters are in the `masters` folder beside the gallery.

| Asset | Design | Mesh budget |
|---|---|---:|
| Spider | Brown carapace, eight tapered legs and six small eyes | 270 triangles |
| Web-spinner | Fuller, paler abdomen on the shared spider rig | 270 triangles |
| Venom spider | Narrower abdomen with an ochre band and dark rear shell | 270 triangles |
| Goblin | Crouched 1.25 m figure with a ragged tunic, crude knife and wooden buckler | 2,359 triangles |

The spiders use a 45-bone rig and one mesh surface each. They share idle, walk, bite (`attack`), hurt, fall, web and venom poses. Idle, walk, attack, fall, web and venom run for 16 frames at 24 fps. Hurt runs for 10 frames. The goblin uses the original 57-bone hierarchy and three surfaces. It has a 48-frame idle, 18-frame slash, 12-frame hurt and 25-frame fall. The frame counts describe intervals from frame zero. The goblin's knife and buckler bind to `hand_R` and `hand_L` respectively. Keep those bone names and the base scale when fitting later equipment. The constrained fitting master is `goblin-controls.blend`. `goblin.blend` holds the baked version used to export the game model.

The four scenes live under `art/enemies/field-creatures-3d-v1`. They share a 32-colour palette and the mine props' cave grain. Each has a fixed metric floor origin and faces local +Z. The source goblin fall was shortened, brought inside its 2 m tile and adjusted for floor clearance with the knife and buckler attached.

Call `play(pose)`, `sample(pose, seconds)` or `set_motion(enabled)` on the scene root. The sample call holds a paused frame. Still mode selects a fixed pose, and fall stays down. `set_equipment("Knife", enabled)` and `set_equipment("Buckler", enabled)` toggle the goblin's two accessories independently. The web and venom clips provide body gestures for the existing effects.

Live integration remains pending. CombatScreen currently dispatches to `AnimatedSprite3D`, so binding these scenes needs model-aware pose, fall, fade and facing dispatch. Use the model's visual height for labels and preserve its floor origin when framing first-person encounters. The fixtures insert the models into existing fights in memory. The current light bands, shroud and visibility drive those views.

The native review passed 2,884 checks and produced 250 captures. It compares six bone anchors and evaluated skin bounds across five samples per clip, checks animation seams, clearance, tile fit, still mode and equipment toggles, and renders at 1278×590, 852×393 and 667×375. The current game fixture passed 156 checks with 62 captures at dark, steady and bright light and in first person. Both runs used the private Windows desktop launcher from #253 and reported unchanged foreground focus. The game fixture still reports the existing shutdown warning in #249. Physical iPhone review remains pending.

The source meshes are [br-n518's Spider](https://opengameart.org/content/spider-2) and [CDmir and TinyWorlds' Goblin](https://opengameart.org/content/goblin-1). Both source pages declare CC0. Original bytes, declaration pages and SHA256 records are under `art/third-party/oga-creatures-v1`. The two CREDITS files describe the adaptations.

## Rebuild

1. Run `build_spiders.py`, then `build_goblin.py`, then `reference_poses.py` from `tools/creatures_3d` through Blender 5.2 in background mode with `--factory-startup --disable-autoexec --python-exit-code 1`. Pass `-- --workspace E:/GitHub/Depths` to each script.
2. Run `prepare_review.py --workspace E:/GitHub/Depths` with Python and Pillow. It copies the rat comparison from the local #252 checkout.
3. Import the local review and feature checkout headlessly. Run `res://check.gd` in the review project and `res://tools/creatures_3d/live_check.gd -- E:/GitHub/Depths/build/local-spiders-goblin-v1/live` in the checkout via #253's `background_godot.py`. Use `native-check` and `live-check` under the review folder for the launcher outputs. Run these fixtures in sequence.
4. Run `package_review.py --workspace E:/GitHub/Depths` and `check_gallery.cjs` with Playwright on `NODE_PATH`.

The delivery branch is `codex/spiders-goblin-3d`.
