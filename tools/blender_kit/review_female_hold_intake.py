"""Audit the owner's female chair-hold candidates (#218) against her transitions.

Inputs are the two Drive uploads copied into ignored female-hold-intake-v1
(Sitting.fbx, Sitting Idle.fbx). Compares each hold with the end of Stand To
Sit and the start of Sit To Stand from female-chair-intake-v1, and measures
how calm it is, whether the legs cross, its loop boundary and root drift.
--build converts both holds into a copy of female_chair.blend; --capture
renders them. Earlier intakes, masters and Drive files are never changed.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
from audit_body_downloads import read_fbx, bind_check
from audit_sources import scene_report
from convert_received_candidates import convert
from prepare_masters import digest_rig
from build_garments import skin_digest
from review_female_chair_intake import compare

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/local-blender-kit-v1'
OUT = BASE / 'animation-requests-v1/female-hold-intake-v1'
CHAIR = BASE / 'animation-requests-v1/female-chair-intake-v1'
HIPS = 'mixamorig:Hips'
LEGS = ['LeftUpLeg', 'LeftLeg', 'LeftFoot', 'RightUpLeg', 'RightLeg', 'RightFoot']
STEP = 10


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pose(rig):
    return {b.name: rig.matrix_world @ b.matrix for b in rig.pose.bones}


def local(p, name):
    """A joint's matrix in hips space, so whole-body placement doesn't count."""
    return p[HIPS].inverted() @ p[name]


def angle(a, b):
    d = math.degrees(a.to_quaternion().rotation_difference(b.to_quaternion()).angle)
    return min(d, 360 - d)


def legs_crossed(p):
    """True when the feet have swapped sides relative to the hips."""
    left = local(p, 'mixamorig:LeftFoot').translation.x
    right = local(p, 'mixamorig:RightFoot').translation.x
    return (left - right) * (local(p, 'mixamorig:LeftUpLeg').translation.x
                             - local(p, 'mixamorig:RightUpLeg').translation.x) < 0


def sample(path):
    report = read_fbx(path)
    rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
    first, last = map(round, rig.animation_data.action.frame_range)
    frames = list(range(first, last + 1, STEP)) + ([last] if (last - first) % STEP else [])
    poses = {}
    for f in frames:
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        poses[f] = pose(rig)
    return report, first, last, poses


def jsonable(p):
    return {n: [list(r) for r in m] for n, m in p.items()}


def audit():
    sources = json.loads((OUT / 'source-manifest.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(BASE / 'female_base.blend'),
                             load_ui=False, use_scripts=False)
    target = next(o for o in scene_report()['objects'] if o['type'] == 'ARMATURE')
    _, _, down_last, down = sample(CHAIR / 'Stand To Sit.fbx')
    up_report, up_first, _, up = sample(CHAIR / 'Sit To Stand.fbx')
    down_end, up_start = down[down_last], up[up_first]
    rows = []
    for entry in sources['files']:
        path = Path(entry['destination'])
        assert sha(path) == entry['sha256']
        report, first, last, poses = sample(path)
        metrics = bind_check(report, target)
        assert metrics['shared_bones'] == 65 and not metrics['parent_mismatches']
        assert not metrics['missing_target_bones'] and not metrics['source_only_bones']
        assert metrics['max_relative_bone_length_error'] < .0001 and metrics['fps'] == 60
        start, end = poses[first], poses[last]
        names = [n for n in start if n != HIPS]
        # Largest change of any joint, in hips space, from the clip's own first frame.
        movement = max(angle(local(start, n), local(p, n)) for p in poses.values() for n in names)
        # Leg pose versus the sit-down's final frame, every sampled frame.
        leg_vs_down = {leg: max(angle(local(down_end, 'mixamorig:' + leg),
                                      local(p, 'mixamorig:' + leg)) for p in poses.values())
                       for leg in LEGS}
        hips = [p[HIPS].translation for p in poses.values()]
        drift = max((a - b).length for a in hips for b in hips)
        feet = [min(p['mixamorig:LeftToeBase'].translation.z, p['mixamorig:RightToeBase'].translation.z)
                for p in poses.values()]
        down_feet = min(down_end['mixamorig:LeftToeBase'].translation.z,
                        down_end['mixamorig:RightToeBase'].translation.z)
        trimmed = lambda c: {k: v for k, v in c.items() if k != 'joint_rotation_degrees'}
        rows.append({
            'name': entry['name'], 'sha256': entry['sha256'], 'frames': [first, last],
            'seconds': (last - first) / 60, 'compatibility': metrics,
            'sampled_every_frames': STEP,
            'max_joint_movement_degrees': movement,
            'legs_crossed_any_sample': any(legs_crossed(p) for p in poses.values()),
            'max_leg_difference_from_sit_down_end_degrees': leg_vs_down,
            'max_hips_drift_source_units': drift,
            'hips_height_minus_sit_down_end': hips[0].z - down_end[HIPS].translation.z,
            'lowest_toe_height_minus_sit_down_end': min(feet) - down_feet,
            'sit_down_end_to_hold_start': trimmed(compare(jsonable(down_end), jsonable(start))),
            'hold_end_to_stand_up_start': trimmed(compare(jsonable(end), jsonable(up_start))),
            'loop_end_to_start': trimmed(compare(jsonable(end), jsonable(start))),
        })
        print('HOLD_AUDIT', entry['name'], [first, last], round(movement, 2),
              rows[-1]['legs_crossed_any_sample'], flush=True)
    result = {'files': rows, 'sit_down_end_frame': down_last, 'stand_up_start_frame': up_first,
              'final_sequence_approved': False, 'owner_approved': False}
    (OUT / 'audit.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def build():
    source = CHAIR / 'female_chair.blend'
    before = sha(source)
    master = OUT / 'female_hold.blend'
    if master.exists():
        old = json.loads((OUT / 'female-manifest.json').read_text(encoding='utf-8'))
        assert sha(master) == old['sha256'], 'Preserve manually edited candidate'
    bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects['rig.female.v1'], bpy.data.objects['body.female.v1']
    rig_hash, body_hash = digest_rig(rig), skin_digest(body, rig)
    entries = json.loads((OUT / 'source-manifest.json').read_text(encoding='utf-8'))['files']
    motions = []
    for key, name in [('hold_sitting', 'Sitting.fbx'), ('hold_sitting_idle', 'Sitting Idle.fbx')]:
        motions.append(convert(rig, 'female', key, next(e for e in entries if e['name'] == name)))
    assert digest_rig(rig) == rig_hash and skin_digest(body, rig) == body_hash
    rig.data.pose_position = 'REST'
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    record = {'master': master.name, 'sha256': sha(master), 'motions': motions,
              'source_master': source.relative_to(BASE).as_posix(), 'source_master_sha256': before,
              'final_animation_approval': False}
    (OUT / 'female-manifest.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    assert sha(source) == before
    print('HOLD_BUILD', [(m['id'], m['frames'], round(m['max_world_position_error'], 6)) for m in motions],
          flush=True)


def capture():
    from capture_garments import setup, frame_camera
    record = json.loads((OUT / 'female-manifest.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(OUT / record['master']), load_ui=False, use_scripts=False)
    rig = bpy.data.objects['rig.female.v1']
    camera = setup()
    review = OUT / 'review'
    review.mkdir(exist_ok=True)
    shots = [(m['action'], m['id'], m['frames']) for m in record['motions']]
    for action in bpy.data.actions:
        if action.name.endswith(('.sit_down', '.stand_up')):
            first, last = map(round, action.frame_range)
            shots.append((action.name, action.name.rsplit('.', 1)[1], [first, last]))
    captures = []
    for action_name, clip, (first, last) in shots:
        action = bpy.data.actions[action_name]
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        rig.data.pose_position = 'POSE'
        if clip == 'sit_down':
            samples = [('end', last)]
        elif clip == 'stand_up':
            samples = [('start', first)]
        else:
            samples = [('start', first), ('middle', round((first + last) / 2)), ('end', last)]
        for label, frame in samples:
            bpy.context.scene.frame_set(frame)
            bpy.context.view_layer.update()
            for view in ['front', 'side']:
                frame_camera(camera, view)
                name = f'{clip}-{label}-{view}.png'
                bpy.context.scene.render.filepath = str(review / name)
                bpy.ops.render.render(write_still=True)
                captures.append({'file': name, 'motion': clip, 'sample': label,
                                 'angle': view, 'frame': frame})
    assert sha(OUT / record['master']) == record['sha256']
    (review / 'captures.json').write_text(json.dumps(captures, indent=2) + '\n', encoding='utf-8')
    print('HOLD_CAPTURES', len(captures), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--build', action='store_true')
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    audit()
    if args.build:
        build()
    if args.capture:
        capture()
