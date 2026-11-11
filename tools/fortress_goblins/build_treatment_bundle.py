"""Export the treatment-supply pickup and keep an editable Blender master."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import bmesh
import bpy

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/combat_roster"))
from build_roster import PALETTE
from mesh_parts import Mesh, set_uv

ART = ROOT / "art/props/treatment-supplies-v1"


def bundle():
    mesh = Mesh()
    # Main linen roll with shallow uneven layers at the visible ends.
    axis = (1, -.28, .02)
    origin = (-.185, -.035, .084)
    mesh.loft([(0,.060,.061,.003,0),(.024,.071,.072,0,0),
               (.131,.071,.075,-.004,0),(.311,.066,.071,.004,.003),
               (.373,.058,.061,0,.002)], None, "linen", "cream", 9,
              axis, origin, .08)
    for start, end, radius in ((-.008,.013,.045),(-.015,.003,.029),
                               (.368,.387,.042),(.378,.392,.027)):
        mesh.loft([(start,radius*.9,radius,.002,0),(end,radius,radius*.97,0,0)],
                  None, "cream", "linen", 9, axis, origin, .055)
    # Two broad ties interrupt the pale roll at phone-icon scale.
    for start in (.098,.258):
        mesh.loft([(start,.074,.078,0,0),(start+.022,.074,.078,0,0)],
                  None, "maroon", "maroon_light", 9, axis, origin, .06)
    mesh.segment((.06,-.091,.146),(.115,-.133,.128),
                 [(0,.011),(.55,.009),(1,.006)], None, "maroon", "maroon_light", 5)
    mesh.segment((.06,-.091,.146),(.039,-.155,.124),
                 [(0,.009),(1,.005)], None, "maroon", "maroon_light", 5)
    # Closed cloth packet deliberately leaves the eventual contents unspecified.
    mesh.loft([(.007,.092,.049,-.071,.075),(.024,.13,.068,-.070,.080),
               (.065,.129,.064,-.078,.084),(.103,.103,.050,-.089,.093),
               (.121,.057,.036,-.105,.097)], None, "deep_olive", "moss_light", 8, twist=.13)
    mesh.segment((-.20,.103,.066),(-.013,.111,.108),
                 [(0,.009),(.43,.008),(1,.009)], None, "sack", "linen", 6)
    mesh.stone((-.122,.106,.116),(.030,.021,.014),None,"linen","cream",6)
    data = bpy.data.meshes.new("Treatment bundle")
    data.from_pydata(mesh.vertices, [], mesh.faces)
    data.update()
    set_uv(data, PALETTE, mesh.colours)
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new("TreatmentBundle", data)
    bpy.context.collection.objects.link(obj)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--review-output", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    masters = args.review_output / "masters"
    masters.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    data = bundle()
    bpy.ops.wm.save_as_mainfile(filepath=str(masters / "treatment-bundle.blend"))
    target = ART / "bundle.glb"
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
        export_materials="NONE", export_animations=False, export_cameras=False, export_lights=False)
    data.calc_loop_triangles()
    (ART / "catalog.json").write_text(json.dumps({
        "scene": "res://art/props/treatment-supplies-v1/scene.tscn",
        "placement": "floor-centre", "front": "+Z", "triangles": len(data.loop_triangles),
        "surfaces": 1, "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
    }, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
