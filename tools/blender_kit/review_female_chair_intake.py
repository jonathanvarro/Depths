"""Audit the follow-up female chair transitions without replacing earlier assets.

Inputs are connector-materialized FBXs in ignored female-chair-intake-v1.
Optional candidate/export/captures also remain there; no live game is loaded.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
from audit_body_downloads import read_fbx, bind_check
from audit_sources import scene_report
from convert_received_candidates import convert
from prepare_masters import digest_rig
from build_garments import skin_digest

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/local-blender-kit-v1'
OUT = BASE / 'animation-requests-v1/female-chair-intake-v1'
PRIOR = BASE / 'animation-requests-v1/received-v1'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pose(rig):
    return {b.name: [list(row) for row in rig.matrix_world @ b.matrix]
            for b in rig.pose.bones}


def compare(a, b):
    root = 'mixamorig:Hips'
    offset = Matrix(b[root]).translation - Matrix(a[root]).translation
    angles = {}
    position = 0.0
    for name in a:
        am, bm = Matrix(a[name]), Matrix(b[name])
        q = am.to_quaternion().rotation_difference(bm.to_quaternion())
        angle = math.degrees(q.angle)
        angles[name] = min(angle, 360 - angle)
        position = max(position, (am.translation + offset - bm.translation).length)
    return {'hips_offset_source_units': list(offset),
            'hips_offset_length': offset.length,
            'max_hips_aligned_joint_position_error': position,
            'max_joint_rotation_degrees': max(angles.values()),
            'joint_rotation_degrees': angles}


def audit():
    sources = json.loads((OUT / 'source-manifest.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(BASE / 'female_base.blend'),
                             load_ui=False, use_scripts=False)
    target = next(o for o in scene_report()['objects'] if o['type'] == 'ARMATURE')
    rows = []
    paths = [(f['name'], Path(f['destination']), f) for f in sources['files']]
    paths += [('Previous Stand To Sit', PRIOR / 'female/individual/Stand To Sit.fbx', None),
              ('Sitting Talking', PRIOR / 'female/individual/Sitting Talking.fbx', None)]
    for name, path, source in paths:
        before = sha(path)
        if source:
            assert before == source['sha256']
        report = read_fbx(path)
        rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
        first, last = map(float, rig.animation_data.action.frame_range)
        samples = {}
        for label, frame in [('start', first), ('middle', (first + last) / 2 + .5), ('end', last)]:
            bpy.context.scene.frame_set(math.floor(frame), subframe=frame % 1)
            bpy.context.view_layer.update()
            samples[label] = pose(rig)
        metrics = bind_check(report, target)
        assert metrics['shared_bones'] == 65 and not metrics['parent_mismatches']
        assert not metrics['missing_target_bones'] and not metrics['source_only_bones']
        assert metrics['max_relative_bone_length_error'] < .0001
        assert metrics['fps'] == 60 and sha(path) == before
        rows.append({'name': name, 'sha256': before, 'frames': [first, last],
                     'seconds': (last - first) / 60, 'compatibility': metrics,
                     'samples': samples})
    down, up, previous, talking = rows
    result = {'files': rows,
              'new_vs_previous_down': {s: compare(previous['samples'][s], down['samples'][s])
                                      for s in ['start', 'middle', 'end']},
              'down_end_vs_up_start': compare(down['samples']['end'], up['samples']['start']),
              'down_end_vs_talking_start': compare(down['samples']['end'], talking['samples']['start']),
              'quiet_seated_hold_received': False, 'final_sequence_approved': False}
    (OUT / 'audit.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('CHAIR_AUDIT', [(r['name'], r['frames']) for r in rows], flush=True)
    print('CHAIR_ENDPOINT', result['down_end_vs_up_start'], flush=True)
    return result


def build():
    source = BASE / 'garments-v1/female_garments.blend'
    before = sha(source)
    master = OUT / 'female_chair.blend'
    if master.exists():
        old = json.loads((OUT / 'female-manifest.json').read_text(encoding='utf-8'))
        assert sha(master) == old['sha256'], 'Preserve manually edited candidate'
    bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects['rig.female.v1'], bpy.data.objects['body.female.v1']
    original = rig.animation_data.action
    rig_hash, body_hash = digest_rig(rig), skin_digest(body, rig)
    for action in list(bpy.data.actions):
        if action != original:
            bpy.data.actions.remove(action, do_unlink=True)
    entries = json.loads((OUT / 'source-manifest.json').read_text(encoding='utf-8'))['files']
    motions = []
    for key, name in [('sit_down', 'Stand To Sit.fbx'), ('stand_up', 'Sit To Stand.fbx')]:
        entry = next(e for e in entries if e['name'] == name) | {'collection': 'follow-up'}
        motions.append(convert(rig, 'female', key, entry))
    assert digest_rig(rig) == rig_hash and skin_digest(body, rig) == body_hash
    rig.data.pose_position = 'REST'
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    record = json.loads((BASE / 'garments-v1/female-manifest.json').read_text(encoding='utf-8'))
    record.update({'master': master.name, 'sha256': sha(master), 'motions': motions,
                   'garment_source_master': source.relative_to(BASE).as_posix(),
                   'garment_source_sha256': before, 'final_animation_approval': False})
    (OUT / 'female-manifest.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    assert sha(source) == before
    import export_check_garments as exporter
    exporter.OUT = OUT
    report = exporter.run_fit('female')
    assert not exporter.fails
    (OUT / 'export-validation.json').write_text(json.dumps({
        'checks': exporter.checks, 'failures': exporter.fails, 'reports': [report]}, indent=2) + '\n', encoding='utf-8')
    print('CHAIR_EXPORT', exporter.checks, 'checks, no failures', flush=True)


def capture():
    from capture_garments import setup, frame_camera
    record = json.loads((OUT / 'female-manifest.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(OUT / record['master']), load_ui=False, use_scripts=False)
    rig = bpy.data.objects['rig.female.v1']
    camera = setup()
    review = OUT / 'review'
    review.mkdir(exist_ok=True)
    captures = []
    for clip in record['motions']:
        action = bpy.data.actions[clip['action']]
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        rig.data.pose_position = 'POSE'
        first, last = clip['frames']
        for label, frame in [('start', first), ('middle', (first + last) / 2 + .5), ('end', last)]:
            bpy.context.scene.frame_set(math.floor(frame), subframe=frame % 1)
            bpy.context.view_layer.update()
            for angle in ['front', 'side', 'back']:
                frame_camera(camera, angle)
                name = f"{clip['id']}-{label}-{angle}.png"
                bpy.context.scene.render.filepath = str(review / name)
                bpy.ops.render.render(write_still=True)
                captures.append({'file': name, 'motion': clip['id'], 'sample': label,
                                 'angle': angle, 'frame': frame})
    assert sha(OUT / record['master']) == record['sha256']
    (review / 'captures.json').write_text(json.dumps(captures, indent=2) + '\n', encoding='utf-8')
    print('CHAIR_CAPTURES', len(captures), flush=True)


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
