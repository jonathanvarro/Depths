"""Adapt Kenney's CC0 square bar stool into a low wooden camp stool."""
import hashlib
import json
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/third-party/kenney-furniture-v1/stoolBarSquare.obj"
OUTPUT = ROOT / "art/dressing/camp-stool-v1"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=str(SOURCE))
objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
bpy.context.view_layer.objects.active = objects[0]
for obj in objects:
    obj.select_set(True)
if len(objects) > 1:
    bpy.ops.object.join()
stool = bpy.context.object
stool.name = "WoodenCampStool"
points = [stool.matrix_world @ vertex.co for vertex in stool.data.vertices]
low = [min(point[axis] for point in points) for axis in range(3)]
high = [max(point[axis] for point in points) for axis in range(3)]
target = (0.40, 0.32, 0.43)
for vertex, point in zip(stool.data.vertices, points):
    vertex.co = tuple((point[axis] - low[axis]) / (high[axis] - low[axis]) * target[axis]
                      - (target[axis] / 2 if axis < 2 else 0) for axis in range(3))
stool.matrix_world.identity()
wood = bpy.data.materials.new("Worn dark timber")
wood.use_nodes = True
shader = wood.node_tree.nodes.get("Principled BSDF")
shader.inputs["Base Color"].default_value = (0.18, 0.10, 0.045, 1)
shader.inputs["Roughness"].default_value = 0.96
stool.data.materials.clear()
stool.data.materials.append(wood)
for face in stool.data.polygons:
    face.material_index = 0
    face.use_smooth = False
stool.data.update()
stool.data.calc_loop_triangles()
path = OUTPUT / "stool.glb"
bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                          export_animations=False, export_cameras=False, export_lights=False)
record = {
    "source": "https://kenney.nl/assets/furniture-kit",
    "download": "https://opengameart.org/sites/default/files/kenney_furniturePack.zip",
    "licence": "CC0-1.0",
    "author": "Kenney",
    "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    "export_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    "triangles": len(stool.data.loop_triangles),
    "dimensions_metres": {"width": 0.40, "depth": 0.32, "seat_height": 0.43},
    "changes": ["Reduced to camp-seat proportions", "Recoloured upholstery and frame as matte dark wood",
                "Joined into one mesh and material", "Centred at floor level"]
}
(OUTPUT / "provenance.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
print("CAMP_STOOL", record["triangles"], "triangles", flush=True)
