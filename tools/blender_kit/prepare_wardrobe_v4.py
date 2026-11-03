"""#218: assembly-v4, assembly-v3 plus the female left-hand lift in sit-down.

The owner saw her left hand pass into her left knee while sitting down (front
view, clothes on and off). Renders placed it at about frames 57-77. This
copy replaces the female sit-down with `received.female.sit_down.handlift`:
the left hand eases out from the thigh from frame 42, is fully lifted 58-90
and back to the source pose by 110, so the end of sit-down and the chair
sequence join are unchanged. The source Action stays in the editable input.
assembly-v3 and everything earlier are not changed.
"""
import hashlib
import json
from pathlib import Path
import sys

import bpy

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
import prepare_wardrobe_v3 as v3
import hand_lift

OUT = v3.current.BASE / 'assembly-v4'
LIFT = {'side': 'Left', 'window': (42, 58, 90, 110), 'amount': .11}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def lift_female():
    sources = OUT / 'editable-inputs'
    record_path = sources / 'female-manifest.json'
    record = json.loads(record_path.read_text(encoding='utf-8'))
    master = sources / record['master']
    bpy.ops.wm.open_mainfile(filepath=str(master), load_ui=False, use_scripts=False)
    rig = bpy.data.objects['rig.female.v1']
    original = rig.animation_data.action
    motion = next(m for m in record['motions'] if m['id'] == 'sit_down')
    rig.data.pose_position = 'POSE'
    fixed, report = hand_lift.lift_window(rig, bpy.data.actions[motion['action']],
                                          LIFT['side'], LIFT['window'], LIFT['amount'])
    rig.animation_data.action = original
    rig.data.pose_position = 'REST'
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    motion.update({'action': fixed.name, 'slot': fixed.slots[0].identifier, 'hand_lift': report,
                   'role': 'Uploaded sit-down with the left hand lifted out of the knee (#218)'})
    record['sha256'] = sha(master)
    record_path.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    print('HAND_LIFT', report, flush=True)


def main():
    v3.OUT = OUT
    v3.AFTER_FIT = {'female': lift_female}
    v3.main()
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    manifest.update({
        'version': 4,
        'motion_labels': ['Neutral fit', 'Idle · body pack', 'Walk · body pack', 'Sit down · chair (hand lifted)',
                          'Seated · chair hold', 'Stand up · chair', 'Chair sequence · aligned', 'Dying · original'],
        'review_footer': 'Per-body motions · female sit-down left hand lifted out of the knee · source faces unchanged',
        'animation_limits': manifest['animation_limits'] + ' assembly-v4: the female sit-down uses a corrected copy in which the left hand eases out of the left knee (frames 42–110, up to 0.11 source units); the source clip is unchanged and kept in the editable input.',
    })
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('WARDROBE_V4_READY', flush=True)


if __name__ == '__main__':
    main()
