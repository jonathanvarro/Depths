"""Local review-copy repairs found by #214's new per-body motion matrix.

Source bodies, rig/rest data, original garment masters and Actions stay intact.
"""
import math

import bpy
from mathutils import Vector

from build_garments import Builder, clamp


def replace_weights(obj, index, weights):
    groups = list(obj.vertex_groups)
    for group in groups:
        group.remove([index])
    total = sum(weights.values())
    for name, weight in weights.items():
        if weight <= 1e-8:
            continue
        group = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
        group.add([index], weight / total, 'REPLACE')


def refine_male(record):
    builder = Builder('male')
    tunic = bpy.data.objects['garment.tunic.male.v1']
    old_mesh = tunic.data
    vertices = [tunic.matrix_world @ v.co for v in old_mesh.vertices]
    faces = [list(face.vertices) for face in old_mesh.polygons]
    weights = [{tunic.vertex_groups[g.group].name: g.weight for g in v.groups}
               for v in old_mesh.vertices]
    # Sparse transferred sleeve surfaces exposed the source forearm in bent
    # poses. Add editable, radial forearm sleeves with deliberate clearance.
    # Their open ends overlap existing cloth; body/coverage faces stay intact.
    for prefix in ['Left', 'Right']:
        elbow, wrist = builder.bone(prefix + 'ForeArm'), builder.bone(prefix + 'Hand')
        axis = (wrist - elbow).normalized()
        u = Vector((0, 0, 1)).cross(axis).normalized()
        v = axis.cross(u).normalized()
        start = len(vertices)
        segments = 12
        for t in [-.07, .18, .65, .97]:
            centre = elbow.lerp(wrist, t)
            for i in range(segments):
                radial = u * math.cos(i * math.tau / segments) + v * math.sin(i * math.tau / segments)
                hit, _, _, _ = builder.bvh.ray_cast(centre + radial * .28, -radial, .28)
                radius = (hit - centre).dot(radial) if hit is not None else .115
                radius = max(.075, min(.23, radius)) + .05
                vertices.append(centre + radial * radius)
                upper = clamp((.18 - t) / .25) * .20
                hand = clamp((t - .82) / .18) * .10
                weights.append({'mixamorig:' + prefix + 'Arm': upper,
                                'mixamorig:' + prefix + 'ForeArm': 1 - upper - hand,
                                'mixamorig:' + prefix + 'Hand': hand})
        for row in range(3):
            for i in range(segments):
                a = start + row * segments + i
                b = start + row * segments + (i + 1) % segments
                faces.append([a, b, b + segments, a + segments])
    mesh = bpy.data.meshes.new('Reviewed forearm sleeve mesh')
    inverse = tunic.matrix_world.inverted()
    mesh.from_pydata([inverse @ p for p in vertices], [], faces)
    for material in old_mesh.materials:
        mesh.materials.append(material)
    mesh.update()
    tunic.data = mesh
    for index, values in enumerate(weights):
        replace_weights(tunic, index, values)
    if old_mesh.users == 0:
        bpy.data.meshes.remove(old_mesh)
    tunic['review_fit_repair'] = 'Editable radial forearm sleeves with source-fitted clearance and explicit elbow/wrist weights.'
    for side in ['left', 'right']:
        prefix = side.title()
        ankle, knee = builder.bone(prefix + 'Foot'), builder.bone(prefix + 'Leg')
        leg_name = 'mixamorig:' + prefix + 'Leg'
        cuff = record['parameters']['boot.' + side]['cuff']
        for name in ['garment.boot.' + side + '.male.v1', 'detail.cuff.' + side + '.male.v1']:
            obj = bpy.data.objects[name]
            for vertex in obj.data.vertices:
                point = obj.matrix_world @ vertex.co
                amount = clamp((point.z - ankle.z - .03) / .15)
                weights = {obj.vertex_groups[g.group].name: g.weight for g in vertex.groups}
                weights = {n: w * (1 - amount) for n, w in weights.items()}
                weights[leg_name] = weights.get(leg_name, 0) + amount
                replace_weights(obj, vertex.index, weights)
                centre = ankle + (knee - ankle) * ((point.z - ankle.z) / (knee.z - ankle.z))
                point.x = centre.x + (point.x - centre.x) * (1 + .18 * amount)
                point.y = centre.y + (point.y - centre.y) * (1 + .18 * amount)
                vertex.co = obj.matrix_world.inverted() @ point
            obj['review_fit_repair'] = 'Calf shaft follows lower leg with a gradual ankle blend and explicit cloth clearance.'
        trousers = bpy.data.objects['garment.trousers.male.v1']
        for vertex in trousers.data.vertices:
            point = trousers.matrix_world @ vertex.co
            if (point.x > 0) != (side == 'left'):
                continue
            amount = clamp((cuff + .18 - point.z) / .12) * clamp((point.z - ankle.z - .03) / .15)
            weights = {trousers.vertex_groups[g.group].name: g.weight for g in vertex.groups}
            weights = {n: w * (1 - amount) for n, w in weights.items()}
            weights[leg_name] = weights.get(leg_name, 0) + amount
            replace_weights(trousers, vertex.index, weights)
    for entry in record['garments']:
        obj = bpy.data.objects[entry['name']]
        obj.data.calc_loop_triangles()
        entry['base_vertices'] = len(obj.data.vertices)
        entry['base_triangles'] = len(obj.data.loop_triangles)
    record['review_fit_refinements'] = [
        'Male radial forearm sleeves add source-fitted clearance with explicit elbow/wrist weighting.',
        'Male boot shafts/cuffs have lower-leg weights, gradual ankle blending and 18% radial cloth clearance.',
        'Tucked male trouser region shares lower-leg weighting with the calf shaft; source body weights unchanged.'
    ]
