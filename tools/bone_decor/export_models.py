"""Export CC0 loose pieces and static poses, retaining the supplied masters.

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
--python tools/bone_decor/export_models.py
"""
import hashlib
import json
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/third-party/kaykit-bones-v1"
OUTPUT = ROOT / "art/dressing/bone-decor-v1"

def points(objects):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    result = []
    for obj in objects:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        result.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        evaluated.to_mesh_clear()
    return result

def export(objects, name, scale, family, pose=None):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    copies = []
    for obj in objects:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
        for vertex in mesh.vertices:
            vertex.co = (obj.matrix_world @ vertex.co) * scale
        mesh.materials.clear()
        for face in mesh.polygons:
            face.material_index = 0
        copy = bpy.data.objects.new("Static." + obj.name, mesh)
        bpy.context.scene.collection.objects.link(copy)
        copies.append(copy)
    cloud = [vertex.co for obj in copies for vertex in obj.data.vertices]
    low = Vector(tuple(min(point[i] for point in cloud) for i in range(3)))
    high = Vector(tuple(max(point[i] for point in cloud) for i in range(3)))
    offset = Vector(((low.x + high.x)/2, (low.y + high.y)/2, low.z))
    for obj in copies:
        for vertex in obj.data.vertices:
            vertex.co -= offset
    bpy.ops.object.select_all(action="DESELECT")
    for obj in copies:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
    if len(copies) > 1:
        bpy.ops.object.join()
    combined = bpy.context.object
    combined.name = name
    combined.data.calc_loop_triangles()
    target = OUTPUT / (name + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                              export_animations=False, export_cameras=False, export_lights=False,
                              export_materials="NONE", export_texcoords=True)
    record = {"name": name, "pose": pose, "family": family,
              "triangles": len(combined.data.loop_triangles),
              "dimensions": list(high-low), "source_scale": scale,
              "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
    bpy.data.objects.remove(combined, do_unlink=True)
    return record

records = []
for name, target_width in [("bone_A", .34), ("bone_B", .25), ("skull", .20), ("ribcage", .34)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path = SOURCE / "halloween" / (name + ".gltf")
    source = json.loads(path.read_text(encoding="utf-8"))
    for entry in source.get("buffers", []) + source.get("images", []):
        uri = entry.get("uri", "")
        assert "/" not in uri and "\\" not in uri and ":" not in uri, "Local pack dependencies only"
    bpy.ops.import_scene.gltf(filepath=str(path), import_pack_images=True)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    cloud = points(meshes)
    width = max(p.x for p in cloud)-min(p.x for p in cloud)
    records.append(export(meshes, name, target_width/width, "halloween"))

for name, pose in [("skeleton-fallen", "Death_A_Pose"),
                   ("skeleton-seated", "Sit_Floor_Pose")]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / "skeletons/Skeleton_Minion.glb"), import_pack_images=True)
    rig = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
    meshes = [obj for obj in bpy.context.scene.objects
              if obj.type == "MESH" and any(mod.type == "ARMATURE" for mod in obj.modifiers)
              and not obj.name.endswith("_Eyes")]
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    cloud = points(meshes)
    scale = 1.65/(max(p.z for p in cloud)-min(p.z for p in cloud))
    rig.data.pose_position = "POSE"
    action = bpy.data.actions[pose]
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    bpy.context.scene.frame_set(int(action.frame_range[0]))
    bpy.context.view_layer.update()
    records.append(export(meshes, name, scale, "skeletons", pose))

source_hashes = json.loads((OUTPUT / "source-hashes.json").read_text(encoding="utf-8"))
for relative, expected in source_hashes.items():
    assert hashlib.sha256((SOURCE / relative).read_bytes()).hexdigest() == expected
(OUTPUT / "catalog.json").write_text(json.dumps({"assets": records, "source_preserved": True,
    "skeleton_changes": ["Sampled named source poses as static scenery", "Removed separate eye mesh",
                         "Combined static pieces and uniformly scaled the rest height to 1.65m"]}, indent=2)+"\n", encoding="utf-8")
print("BONE_EXPORTS", [(r["name"], r["triangles"]) for r in records], flush=True)
