"""#218: assembly-v6, assembly-v5 with the female's hands resting on her knees.

Owner review of v4/v5 (2026-11-03), side view: her hands still sink into her
thighs. Renders showed both hands buried from about frame 90 of the
sit-down, all through the chair hold and into the stand-up, so raising only
the sit-down would make them drop back in at the hold. On top of v4's
sit-down lift, both hands are raised straight up (left 0.25, right 0.22
source units, chosen from side/front renders of 0.15-0.35): easing in over
sit-down frames 76-100 and held to its end, held through the whole hold, and
easing out over stand-up frames 40-70 as she rises. The lift is identical on
both sides of each join, so the chair sequence joins are unchanged. Source
Actions stay in the editable input; earlier assemblies are not touched.
"""
import hashlib
import json
from pathlib import Path
import sys

import bpy

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
import prepare_wardrobe_v5 as v5
import hand_lift

v4 = v5.v4
OUT = v5.current.BASE / 'assembly-v6'
UP = (0, 0, 1)
AMOUNTS = {'Left': .25, 'Right': .22}
# (start, full_from, full_to, end) per clip; a start before frame 1 or an end
# after the last frame keeps the lift full there, so the joins match.
WINDOWS = {'sit_down': (76, 100, 135, 136), 'seated': (0, 1, 421, 422), 'stand_up': (0, 1, 40, 70)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rest_hands():
    sources = OUT / 'editable-inputs'
    record_path = sources / 'female-manifest.json'
    record = json.loads(record_path.read_text(encoding='utf-8'))
    master = sources / record['master']
    bpy.ops.wm.open_mainfile(filepath=str(master), load_ui=False, use_scripts=False)
    rig = bpy.data.objects['rig.female.v1']
    original = rig.animation_data.action
    rig.data.pose_position = 'POSE'
    for motion in record['motions']:
        if motion['id'] not in WINDOWS:
            continue
        source = bpy.data.actions[motion['action']]
        fixed, reports = source, []
        for side, amount in AMOUNTS.items():
            corrected, report = hand_lift.lift_window(rig, fixed, side, WINDOWS[motion['id']], amount, direction=UP)
            if fixed is not source:
                bpy.data.actions.remove(fixed)
            fixed = corrected
            reports.append(report)
        fixed.name = source.name + '.handrest'
        motion.update({'action': fixed.name, 'slot': fixed.slots[0].identifier,
                       'hand_rest': {'lifts': reports, 'corrected_action': fixed.name, 'source_action': source.name,
                                     'source_curves_modified': False}})
        motion['role'] = motion.get('role', '') + ' Hands raised to rest on her knees (#218, assembly-v6).'
        print('HAND_REST', motion['id'], fixed.name, flush=True)
    rig.animation_data.action = original
    rig.data.pose_position = 'REST'
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    record['sha256'] = sha(master)
    record_path.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')


def main():
    v5.OUT = OUT
    lift_sit_down = v4.lift_female

    def female():
        lift_sit_down()
        rest_hands()
    v4.lift_female = female
    v5.main()
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    labels = manifest['motion_labels']
    labels[labels.index('Seated · chair hold')] = 'Seated · chair hold (hands on knees)'
    manifest.update({
        'version': 6,
        'motion_labels': labels,
        'review_footer': 'Female hands rest on her knees through the chair sequence · male in T-pose · source faces unchanged',
        'animation_limits': manifest['animation_limits'] + ' assembly-v6: the female hands are raised straight up (left 0.25, right 0.22 source units) to rest on her knees from late in the sit-down, through the hold and early stand-up; the same lift on both sides of each join.',
    })
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('WARDROBE_V6_READY', flush=True)


if __name__ == '__main__':
    main()
