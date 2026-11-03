"""Owner request (2026-11-03): make the male's T-pose his real rest/bind pose.

Starts from #210's male master (lowered-arm rest) and never changes it. Each
bone is turned, parent first, by the smallest rotation that points it the
way the same bone points in the rest pose of his own per-body Mixamo
downloads (a T-pose). No roll is added, so limbs don't twist. The body is
baked into that shape and the pose becomes the new rest, so the mesh is
bound in the T-pose with its original skin weights, bone names, hierarchy and
lengths. His Dying Action is rebaked so it deforms the same as before.

Output: build/local-blender-kit-v1/male-tpose-v1/male_base.blend (+ report),
laid out like the original masters folder so build_garments can use it.
"""
import hashlib
import json
from pathlib import Path
import sys

import bpy
from mathutils import Matrix

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
from prepare_masters import digest_rig

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/local-blender-kit-v1'
OUT = BASE / 'male-tpose-v1'
REFERENCE = BASE / 'animation-requests-v1/received-v1/male/locomotion/idle.fbx'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ordered(rig):
    """Bones parent-first."""
    result = []
    def walk(bone):
        result.append(bone.name)
        for child in bone.children:
            walk(child)
    for bone in rig.data.bones:
        if bone.parent is None:
            walk(bone)
    return result


def reference_directions():
    """World head->tail direction of every bone in the downloads' rest pose."""
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=str(REFERENCE), use_image_search=False,
                             automatic_bone_orientation=False)
    added = set(bpy.context.scene.objects) - before
    source = next(o for o in added if o.type == 'ARMATURE')
    w = source.matrix_world
    directions = {b.name: ((w @ b.tail_local) - (w @ b.head_local)).normalized()
                  for b in source.data.bones}
    for obj in added:
        bpy.data.objects.remove(obj, do_unlink=True)
    return directions


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    master = OUT / 'male_base.blend'
    if master.exists() and '--rebuild' not in sys.argv:
        raise RuntimeError('T-pose master exists; pass -- --rebuild to replace it intentionally.')
    source_path = BASE / 'male_base.blend'
    source_hash = sha(source_path)
    bpy.ops.wm.open_mainfile(filepath=str(source_path), load_ui=False, use_scripts=False)
    scene = bpy.context.scene
    rig, body = bpy.data.objects['rig.male.v1'], bpy.data.objects['body.male.v1']
    old_digest = digest_rig(rig)
    dying = rig.animation_data.action
    slot = rig.animation_data.action_slot
    names = ordered(rig)
    old_rest = {n: rig.data.bones[n].matrix_local.copy() for n in names}
    directions = reference_directions()
    assert set(directions) == set(names), 'Downloads must share his exact skeleton'
    # An untouched copy of the skeleton keeps the old rest for rebaking Dying.
    temp = rig.copy()
    temp.data = rig.data.copy()
    scene.collection.objects.link(temp)

    # 1. Pose him into the T-pose with minimal per-bone turns.
    rig.animation_data.action = None
    rig.data.pose_position = 'POSE'
    for pb in rig.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.location, pb.scale = (0, 0, 0), (1, 1, 1)
        pb.rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()
    w = rig.matrix_world
    inverse = w.inverted()
    turned = {}
    for name in names:
        pb = rig.pose.bones[name]
        world = w @ pb.matrix
        head = world.translation
        current = (w @ pb.tail - w @ pb.head).normalized()
        turn = current.rotation_difference(directions[name])
        turned[name] = turn.angle
        rotate = Matrix.Translation(head) @ turn.to_matrix().to_4x4() @ Matrix.Translation(-head)
        pb.matrix = inverse @ (rotate @ world)
        bpy.context.view_layer.update()
    residual = max((((w @ rig.pose.bones[n].tail) - (w @ rig.pose.bones[n].head)).normalized()
                    - directions[n]).length for n in names)

    # 2. Bake the posed body into the mesh (all masks off so every vertex counts).
    masks = [m for m in body.modifiers if m.type == 'MASK']
    for m in masks:
        m.show_viewport = False
    deps = bpy.context.evaluated_depsgraph_get()
    evaluated = body.evaluated_get(deps).to_mesh()
    assert len(evaluated.vertices) == len(body.data.vertices)
    posed = [v.co.copy() for v in evaluated.vertices]
    body.evaluated_get(deps).to_mesh_clear()
    for v, co in zip(body.data.vertices, posed):
        v.co = co
    body.data.update()
    for m in masks:
        m.show_viewport = True

    # 3. The pose becomes the rest pose; the mesh now sits still at rest.
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    bpy.ops.object.mode_set(mode='POSE')
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    new_rest = {n: rig.data.bones[n].matrix_local.copy() for n in names}

    # 4. Rebake Dying so each frame deforms the body as before. The body was
    #    moved into the T-pose by exactly the rest change, so each bone keeps
    #    its old posed matrix (armature space); only its channels change.
    assert all(max(abs(a - b) for r1, r2 in zip(temp.data.bones[n].matrix_local, old_rest[n])
                   for a, b in zip(r1, r2)) < 1e-6 for n in names), 'Copy must keep the old rest'
    temp.animation_data.action = dying
    temp.animation_data.action_slot = slot
    temp.data.pose_position = 'POSE'
    rebaked = bpy.data.actions.new(dying.name + '.tpose')
    rebaked.use_fake_user = True
    new_slot = rebaked.slots.new('OBJECT', rig.name)
    rig.animation_data.action = rebaked
    rig.animation_data.action_slot = new_slot
    first, last = map(round, dying.frame_range)
    previous = {}
    for frame in range(first, last + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        wanted = {n: temp.pose.bones[n].matrix.copy() for n in names}
        for name in names:
            pb = rig.pose.bones[name]
            pb.matrix = wanted[name]
            bpy.context.view_layer.update()
            q = pb.rotation_quaternion.copy()
            if name in previous and q.dot(previous[name]) < 0:
                q.negate()
                pb.rotation_quaternion = q
            previous[name] = q
            for prop in ('location', 'rotation_quaternion', 'scale'):
                pb.keyframe_insert(prop, frame=frame, group=name)
    for layer in rebaked.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for point in curve.keyframe_points:
                        point.interpolation = 'LINEAR'
    bpy.data.objects.remove(temp, do_unlink=True)
    rebaked['clip_id'] = 'source.male.dying'
    rebaked['source_file'] = dying.get('source_file', '')
    rebaked['rebaked_for'] = 'male T-pose rest (owner request 2026-11-03)'
    dying.use_fake_user = True
    rig.data.pose_position = 'REST'
    scene.frame_set(first)
    scene['rest_pose'] = 'T-pose from his per-body Mixamo downloads (owner request 2026-11-03)'
    rig['rest_pose'] = 'T-pose'
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    assert sha(source_path) == source_hash
    report = {'source_master': source_path.name, 'source_master_sha256': source_hash,
              'master': master.name, 'master_sha256': sha(master),
              'reference_rest': str(REFERENCE.relative_to(BASE)),
              'old_rig_digest': old_digest, 'new_rig_digest': digest_rig(rig),
              'max_turn_degrees': max(turned.values()) * 57.29578,
              'turned_over_5_degrees': sorted(n.replace('mixamorig:', '') for n, a in turned.items() if a * 57.29578 > 5),
              'max_direction_residual': residual,
              'dying_action': rebaked.name, 'dying_slot': new_slot.identifier, 'dying_frames': [first, last],
              'original_dying_kept': dying.name}
    (OUT / 'male-tpose-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('MALE_TPOSE', json.dumps({k: report[k] for k in ('max_turn_degrees', 'turned_over_5_degrees', 'max_direction_residual')}), flush=True)


if __name__ == '__main__':
    main()
