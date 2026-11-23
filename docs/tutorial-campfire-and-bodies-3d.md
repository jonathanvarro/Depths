# Tutorial hearth and fallen travellers (#285)

The opening now uses solid 3D art: a dying stone-ringed hearth and two anonymous,
fully clothed adults. Brown leather lies supine, slate cloth lies prone. Heads,
boots, hands and relaxed limbs have individually authored floor contacts; these
are static props, not stopped dying animations. No named likeness is assigned.

Runtime scenes:

- `art/features/campfire-3d-v1/scene.tscn`: 2,184 triangles, four surfaces, one
  local light. Uneven cracked stones, ash, split blackened logs, thirteen coals,
  four low mesh flame tongues. No billboards, particles, camera-facing scripts,
  collisions or new audio. Ash sits about 4 mm into the floor.
- `art/props/opening-bodies-3d-v1/fallen-a.tscn`: 1,524 triangles, two surfaces.
- `art/props/opening-bodies-3d-v1/fallen-b.tscn`: 1,496 triangles, two surfaces.

Both travellers fit within their 2 m cell, centred horizontally, with a maximum
height of 0.389 m. Their floor envelope is about 0.90 × 1.75 m. Vertex colours,
rough cloth/skin and the mine's shared worked-prop materials keep their colours
muted. No exposed wounds or gore. The former painted props remain untouched.

## Sources and editable masters

All geometry is original public Depths work, derived from `party.py` / `Mesh`
in `tools/combat_roster` and the authored mine geometry helpers. The torso/head
retain the public generic recruit's proportions; the pack, bedroll, club and
standing limbs are removed. New resting limbs are authored explicitly. Neither
private body models, Mixamo files nor named companion meshes are read. This
batch downloads no third-party files and adds no third-party licence obligation.
Both catalogues record public source references, triangle counts, Blender XYZ
bounds and SHA-256 hashes for exported GLBs and builder dependencies.

Rebuild with Blender 5.2.3:

```text
blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/tutorial_art/build_models.py -- --workspace E:/GitHub/Depths
```

Four editable, separate-piece Blender masters stay local in
`build/local-tutorial-3d-v1/masters`. Runtime GLBs are static; there is no runtime
skeleton, Action, new death transition or wardrobe contract.

## Hookup and still mode

Main's existing `body_scenes` and `fire_scene_path` defaults point to the new
scenes. Cell placement, search events, evidence/loot, recovery, tutorial prompts,
save data and the 1.0-energy room fill are unchanged. Because `body_scenes` was
already shared, anonymous lost-companion recovery props also use these bodies;
identity remains in CampState. Story packages explicitly referencing the earlier
sprite scenes retain them.

`fire.set_motion(false)` resets shader phase to zero, light energy to 0.85 and
stops motion exactly. Main enables `follow_settings`, so changing the existing
effects/"flashes" preference also updates a currently visible fire. Materials
with changing phase are per instance. Its only local light preserves the old
colour, location, 3.5 m range, 1.5 attenuation and 0.82–0.94 warmth range. There
are no visibility, torch, fuel, damage or traversal changes.

## Validation and local review

Godot 4.7.2 Mobile, isolated desktop only:

- `tools/tutorial_art/check.gd`: 22 checks, zero failures. Cell envelopes,
  floor placement, static geometry, light budget, camera invariance, independent
  materials, exact rendered still image, live effects toggling and real Main
  tutorial placement at 1278 × 590 with simulated safe areas.
- `tools/opening_playthrough.gd`: zero failures; both searches, supplies,
  equipping, fire collision, three fights, escape, commander and camp.
- `tools/lost_bodies_check.gd`: zero assertion failures; its existing unfreed
  Main test fixture reports ObjectDB/resource-in-use warnings at shutdown.
- `tools/tutorial_art/capture.gd`: four angles per body, cave/neutral light,
  hearth details and a paired view. Images and test logs are local under
  `build/local-tutorial-3d-v1`. No physical iPhone run claimed.

Run GPU checks through `tools/testing/background_godot.py`; do not launch them
on the owner's active desktop. The local `inspector.html` links all native
captures and the validation report.

## Worn wall torch (#287)

`art/dressing/wall-torch-3d-v1` contains a 1,200-triangle solid torch/sconce:
split haft, charred wrapping, iron bindings, bent cradle, riveted wall plate.
Local +Z projects into the room; the plate back is about 4 mm from its anchor.
`Dressing.MODELS` replaces `burnt-sconce` and `goblin-torch-lit` without changing
their heights, yaw, seeded selection, metadata or floor ranges. Landmark callers
using `Dressing._put` also receive the model. The old sprites remain intact.

The burnt version emits no light; the lit sibling reuses the new mesh flames,
with the previous mood-only 0.4-energy / 1.5 m / 1.7-attenuation local light.
Its warmth stays within the earlier 0.37–0.46 range. Still mode fixes phase to
zero and light to 0.4; live preferences update it. No supply, fuel, held-torch,
item icon or traversal changes. `build_wall_torch.py` rebuilds its local editable
master beside the tutorial props. No third-party download or private mesh.

`tools/tutorial_art/torch_check.gd`: 35 checks, zero failures across all four
wall orientations, retained mounts/light state, envelopes and live still mode.
`capture.gd` includes unlit/lit angled wall-contact renders.
