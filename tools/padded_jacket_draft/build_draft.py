"""#220: isolated editable padded-jacket blockouts, never source/master edits.

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
--python build_draft.py -- --workspace E:/GitHub/Depths
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.dont_write_bytecode = True
TOOLS_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(TOOLS_ROOT / 'tools/blender_kit'))
from build_garments import Builder, skin_digest
from prepare_masters import digest_rig
from capture_garments import setup, frame_camera


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def material(name, colour):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*colour, 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*colour, 1)
    shader.inputs['Roughness'].default_value = .95
    return mat


def detail(name, vertices, faces, mat, rig, builder, collection, thickness=.004):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.data.materials.append(mat)
    obj['draft_component'] = True
    for index, point in enumerate(vertices):
        for bone, value in builder.weights_at(Vector(point)).items():
            group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
            group.add([index], value, 'REPLACE')
    solid = obj.modifiers.new('Editable detail thickness', 'SOLIDIFY')
    solid.thickness = thickness
    armature = obj.modifiers.new('Existing source rig', 'ARMATURE')
    armature.object = rig
    return obj


def quilt_and_closures(jacket, rig, builder, collection, seam_mat, leather, wood):
    mesh = jacket.data
    mesh.calc_loop_triangles()
    points = [jacket.matrix_world @ v.co for v in mesh.vertices]
    tree = BVHTree.FromPolygons(points, [tuple(t.vertices) for t in mesh.loop_triangles], all_triangles=True)
    hip, neck = builder.bone('Hips'), builder.bone('Neck')

    def surface(x, z, front=True):
        origin = Vector((x, -2 if front else 2, z))
        hit, normal, _, _ = tree.ray_cast(origin, Vector((0, 1 if front else -1, 0)), 4)
        return hit + normal * .009 if hit is not None else None

    vertices, faces = [], []
    for front in [True, False]:
        for x in [-.36, -.18, .035, .22, .39]:
            previous = None
            for i in range(15):
                z = hip.z - .24 + (neck.z - hip.z + .03) * i / 14
                wiggle = .004 * math.sin(i * .8 + x * 6)
                pair = [surface(x + wiggle + side * .006, z, front) for side in [-1, 1]]
                if any(p is None for p in pair):
                    previous = None
                    continue
                start = len(vertices)
                vertices.extend(pair)
                if previous is not None:
                    faces.append([previous, previous + 1, start + 1, start])
                previous = start
    detail('detail.quilt-channels.' + builder.fit, vertices, faces, seam_mat, rig, builder, collection)
    tabs, tab_faces, toggles, toggle_faces = [], [], [], []
    for number, z in enumerate([hip.z + .28, hip.z + .63, hip.z + .98]):
        for target, target_faces, left, right, height in [
                (tabs, tab_faces, -.13, .16, .035),
                (toggles, toggle_faces, .115, .16, .082)]:
            quad = [surface(x, zz) for x, zz in [(left, z-height), (right, z-height),
                                                     (right, z+height), (left, z+height)]]
            if any(p is None for p in quad):
                continue
            start = len(target)
            target.extend(p + Vector((0, -.013 if target is tabs else -.035, 0)) for p in quad)
            target_faces.append(list(range(start, start + 4)))
    detail('detail.closure-tabs.' + builder.fit, tabs, tab_faces, leather, rig, builder, collection, .012)
    detail('detail.wood-toggles.' + builder.fit, toggles, toggle_faces, wood, rig, builder, collection, .025)
    # A low collar blockout, deliberately editable and separate from the shell.
    collar, collar_faces = [], []
    for z, radius in [(neck.z - .06, 1), (neck.z + .075, 1.03)]:
        for i in range(12):
            a = math.tau * i / 12
            collar.append(Vector((neck.x + .20 * radius * math.cos(a),
                                  neck.y + .17 * radius * math.sin(a), z)))
    for i in range(12):
        collar_faces.append([i, (i+1)%12, (i+1)%12+12, i+12])
    detail('detail.padded-collar.' + builder.fit, collar, collar_faces, jacket.data.materials[0],
           rig, builder, collection, .028)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=Path, default=TOOLS_ROOT)
    opt = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    workspace = opt.workspace.resolve()
    source_root = workspace / 'build/local-blender-kit-v1/assembly-v2/editable-inputs'
    out = workspace / 'build/local-padded-jacket-v1'
    out.mkdir(parents=True, exist_ok=True)
    (out / '.gdignore').touch()
    review = out / 'review'
    review.mkdir(exist_ok=True)
    records, captures, checks = {}, [], 0
    for fit in ['female', 'male']:
        original_record = json.loads((source_root / (fit+'-manifest.json')).read_text(encoding='utf-8'))
        source = source_root / original_record['master']
        before = sha(source)
        assert before == original_record['sha256']
        target = out / (fit + '_padded-jacket_draft.blend')
        if target.exists():
            old = json.loads((out / 'manifest.json').read_text(encoding='utf-8'))['fits'][fit]
            assert sha(target) == old['master_sha256'], 'Preserve manual edits; use another draft version'
        bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
        rig = bpy.data.objects['rig.' + fit + '.v1']
        body = bpy.data.objects['body.' + fit + '.v1']
        rig_before, body_before = digest_rig(rig), skin_digest(body, rig)
        rig.data.pose_position = 'REST'
        bpy.context.scene.frame_set(1)
        builder = Builder(fit)
        collection = bpy.data.collections.new('DRAFT_PADDED_JACKET_' + fit)
        bpy.context.scene.collection.children.link(collection)
        source_tunic = bpy.data.objects['garment.tunic.' + fit + '.v1']
        jacket = source_tunic.copy()
        jacket.data = source_tunic.data.copy()
        jacket.name = 'garment.padded-jacket.' + fit + '.draft1'
        collection.objects.link(jacket)
        source_tunic.hide_render = True
        source_tunic.hide_set(True)
        for obj in bpy.context.scene.objects:
            if obj.get('piece') == 'belt':
                obj.hide_render = True
                obj.hide_set(True)
        jacket['piece'] = 'tunic'  # Existing preview coverage only, not a new gameplay slot.
        jacket['draft_component'] = True
        jacket['status'] = 'Early editable silhouette/detail draft; no final rig/contact acceptance'
        cloth = material('jacket.worn-olive.'+fit, (.16, .167, .115))
        seam = material('jacket.channel-stitch.'+fit, (.073, .079, .048))
        leather = material('jacket.closure-leather.'+fit, (.105, .067, .041))
        wood = material('jacket.toggle-wood.'+fit, (.26, .18, .095))
        patch = material('jacket.elbow-repair.'+fit, (.115, .085, .058))
        jacket.data.materials.clear()
        jacket.data.materials.append(cloth)
        jacket.data.materials.append(patch)
        for vertex in jacket.data.vertices:
            vertex.co += vertex.normal * (.045 + .004 * math.sin(vertex.co.z*7 + vertex.co.x*5))
            arm_weight = sum(g.weight for g in vertex.groups
                             if any(part in jacket.vertex_groups[g.group].name
                                    for part in ['Arm', 'Hand', 'Shoulder']))
            point = jacket.matrix_world @ vertex.co
            hip, neck = builder.bone('Hips'), builder.bone('Neck')
            if arm_weight < .5 and hip.z-.28 < point.z < neck.z-.20:
                # A loose, padded torso rather than the underlying tunic's
                # closely body-following chest/waist surface. Preserve limbs.
                a = math.atan2(point.y-hip.y, point.x-hip.x)
                x = hip.x + .49 * math.cos(a)
                y = hip.y + (.36 if point.y < hip.y else .28) * math.sin(a)
                if abs(x-hip.x) > abs(point.x-hip.x):point.x=x
                if abs(y-hip.y) > abs(point.y-hip.y):point.y=y
                vertex.co = jacket.matrix_world.inverted() @ point
        elbow = builder.bone('LeftForeArm')
        for face in jacket.data.polygons:
            centre = jacket.matrix_world @ face.center
            if (centre-elbow).length < .27 and centre.y > elbow.y:
                face.material_index = 1
        for modifier in jacket.modifiers:
            if modifier.type == 'SOLIDIFY':
                modifier.thickness = .042
        jacket.data.update()
        quilt_and_closures(jacket, rig, builder, collection, seam, leather, wood)
        assert digest_rig(rig) == rig_before and skin_digest(body, rig) == body_before
        checks += 2
        for obj in collection.objects:
            for vertex in obj.data.vertices:
                weights = [g.weight for g in vertex.groups]
                assert weights and abs(sum(weights)-1) < .0001
                assert all(obj.vertex_groups[g.group].name in rig.data.bones for g in vertex.groups)
                checks += 1
        bpy.ops.wm.save_as_mainfile(filepath=str(target), check_existing=False)
        camera = setup()
        original = rig.animation_data.action
        modes = [('rest', None, 1, 'front'), ('rest', None, 1, 'side'), ('rest', None, 1, 'back')]
        for key in ['idle', 'walk', 'sit_down']:
            motion = next(m for m in original_record['motions'] if m['id'] == key)
            frame = motion['frames'][1] if key == 'sit_down' else sum(motion['frames'])/2+.5
            modes.append((key, motion['action'], frame, 'quarter'))
        for key, action, frame, angle in modes:
            rig.data.pose_position = 'POSE' if action else 'REST'
            if action:
                rig.animation_data.action = bpy.data.actions[action]
                rig.animation_data.action_slot = rig.animation_data.action.slots[0]
            bpy.context.scene.frame_set(math.floor(frame), subframe=frame%1)
            bpy.context.view_layer.update()
            frame_camera(camera, angle)
            name = fit + '-' + key + '-' + angle + '.png'
            bpy.context.scene.render.filepath = str(review/name)
            bpy.ops.render.render(write_still=True)
            captures.append({'fit':fit, 'motion':key, 'angle':angle, 'frame':frame, 'file':name})
        assert sha(source) == before
        checks += 1
        records[fit] = {'master':target.name, 'master_sha256':sha(target),
                        'source_master':str(source), 'source_sha256':before,
                        'rig_digest':rig_before, 'body_skin_digest':body_before,
                        'source_motions':original_record['motions'], 'draft_objects':[o.name for o in collection.objects],
                        'fit_status':'Draft only; #218 animation corrections and future T-pose rebind not adopted'}
    result = {'fits':records, 'checks':checks, 'failures':[], 'captures':captures,
              'concept':'concept-v1.png', 'prompt':'concept-prompt.txt',
              'new_animations':False, 'rig_rest_changed':False, 'production_fit_approved':False,
              'source_models_uploaded':False, 'all_assets_local':True}
    (out/'manifest.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('PADDED_JACKET_DRAFT',checks,'checks;',len(captures),'actual Blender captures',flush=True)


if __name__ == '__main__':
    main()
