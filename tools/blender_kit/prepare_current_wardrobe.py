"""#214/#215: assemble a new wardrobe review from the received per-body clips.

Keeps assembly-v1, intake candidates and original base/garment masters intact.
Female seated talking is an explicit fit stress test, not a quiet chair idle.
"""
import hashlib
import json
from pathlib import Path
import sys

import bpy

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
from convert_received_candidates import convert
from prepare_masters import digest_rig
from build_garments import skin_digest
import prepare_wardrobe as wardrobe

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/local-blender-kit-v1'
OUT = BASE / 'assembly-v2'
SOURCES = OUT / 'editable-inputs'
INTAKE = BASE / 'animation-requests-v1/received-v1'
CHAIR = BASE / 'animation-requests-v1/female-chair-intake-v1'
# Optional per-fit seated override (#218): fit -> intake folder whose
# source-manifest.json names the hold. Unset keeps assembly-v2's selection.
SEATED = {}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare_fit(fit):
    library = json.loads((INTAKE / 'library-audit.json').read_text(encoding='utf-8'))['files']
    chair = json.loads((CHAIR / 'source-manifest.json').read_text(encoding='utf-8'))['files']
    selection = {}
    for key, collection, name in [('idle', 'locomotion', 'idle.fbx'),
                                   ('walk', 'locomotion', 'walking.fbx'),
                                   ('sit_down', 'individual', 'Stand To Sit.fbx'),
                                   ('seated', 'individual', 'Sitting Talking.fbx' if fit == 'female' else 'Sitting Idle.fbx'),
                                   ('stand_up', 'individual', 'Sit To Stand.fbx')]:
        if key == 'seated' and fit in SEATED:
            folder, name = SEATED[fit]
            hold = json.loads((folder / 'source-manifest.json').read_text(encoding='utf-8'))['files']
            entry = next(e for e in hold if e['name'] == name)
        elif fit == 'female' and key in ['sit_down', 'stand_up']:
            entry = next(e for e in chair if e['name'] == name) | {'collection': 'chair-follow-up'}
        else:
            entry = next(e for e in library if e['fit'] == fit and e['collection'] == collection and e['name'] == name)
            metrics = entry['compatibility'][fit]
            assert metrics['shared_bones'] == (65 if fit == 'female' else 49)
            assert not metrics['parent_mismatches'] and metrics['max_relative_bone_length_error'] < .0001
        selection[key] = entry
    original_path = BASE / 'garments-v1' / (fit + '_garments.blend')
    original_hash = sha(original_path)
    record = json.loads((original_path.parent / (fit + '-manifest.json')).read_text(encoding='utf-8'))
    master = SOURCES / (fit + '_current.blend')
    if master.exists():
        old = json.loads((SOURCES / (fit + '-manifest.json')).read_text(encoding='utf-8'))
        assert sha(master) == old['sha256'], 'Preserve manual edits; use another output version'
    bpy.ops.wm.open_mainfile(filepath=str(original_path), load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects['rig.' + fit + '.v1'], bpy.data.objects['body.' + fit + '.v1']
    original = rig.animation_data.action
    rig_hash, body_hash = digest_rig(rig), skin_digest(body, rig)
    for action in list(bpy.data.actions):
        if action != original:
            bpy.data.actions.remove(action, do_unlink=True)
    motions = []
    for key, entry in selection.items():
        # Reuse the exact already-verified Actions rather than rebaking the
        # 45-second conversation on every assembly. Rig/skin and source hashes
        # must match; the new assembly is independently exported/reimported.
        cache = CHAIR if fit == 'female' and key in ['sit_down', 'stand_up'] else INTAKE / 'candidates-v1'
        cache_record = json.loads((cache / (fit + '-manifest.json')).read_text(encoding='utf-8'))
        cached = next((m for m in cache_record['motions'] if m['id'] == key and m['source_sha256'] == entry['sha256']), None)
        if cached:
            assert sha(Path(entry['destination'])) == entry['sha256']
            assert cache_record['source_rig_digest'] == rig_hash
            assert cache_record['source_skin_digest'] == body_hash
            assert sha(cache / cache_record['master']) == cache_record['sha256']
            with bpy.data.libraries.load(str(cache / cache_record['master']), link=False) as (_, loaded):
                loaded.actions = [cached['action']]
            action = loaded.actions[0]
            assert action and action.name == cached['action'] and action.slots[0].identifier == cached['slot']
            action.use_fake_user = True
            motions.append(dict(cached))
        else:
            motions.append(convert(rig, fit, key, entry))
        print('CURRENT_WARDROBE_MOTION', fit, key, flush=True)
    if fit == 'male':
        from refine_review_fit import refine_male
        refine_male(record)
    assert digest_rig(rig) == rig_hash and skin_digest(body, rig) == body_hash
    rig.data.pose_position = 'REST'
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(master), check_existing=False)
    record.update({'master': master.name, 'sha256': sha(master), 'motions': motions,
                   'received_profile': True, 'garment_source_master': original_path.relative_to(BASE).as_posix(),
                   'garment_source_sha256': original_hash})
    (SOURCES / (fit + '-manifest.json')).write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    assert sha(original_path) == original_hash


def main():
    SOURCES.mkdir(parents=True, exist_ok=True)
    (SOURCES / '.gdignore').touch()
    for fit in ['female', 'male']:
        prepare_fit(fit)
    wardrobe.SOURCE = SOURCES
    wardrobe.OUT = OUT
    wardrobe.main()
    manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    manifest.update({
        'version': 2,
        'motion_order': ['rest', 'idle', 'walk', 'sit_down', 'seated', 'stand_up', 'dying'],
        'motion_labels': ['Neutral fit', 'Idle · body pack', 'Walk · body pack', 'Sit down · chair',
                          'Seated · talk / idle', 'Stand up · chair', 'Dying · original'],
        'review_footer': 'Per-body motions · female seated = talking · source faces unchanged',
        'animation_limits': '#215 received per-body motions preserve all source frames, fingers and traveling roots on the unchanged rest rigs. Female seated is Sitting Talking (crossed-leg conversation), male seated is chair Sitting Idle. A calm female chair hold remains follow-up polish; neither clip proves a continuous sit/hold/stand sequence. Raw placement differences and floor/seat/finger contacts are exposed, with no IK, root alignment, crossfade or in-place derivative. Playback uses original seconds and stops at each real endpoint; looping is not approved. Matrix captures sample each fit at its own relative clip time.',
        'quiet_female_chair_hold_available': False,
        'final_animation_acceptance_pending': 218,
        'animation_polish_issue': 218,
        'source_manifests': ['animation-requests-v1/received-v1/source-manifest.json',
                             'animation-requests-v1/female-chair-intake-v1/source-manifest.json'],
        'delivery_scope': 'Editable wardrobe and received-animation verification candidate; owner style acceptance separate',
    })
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('CURRENT_WARDROBE_READY', wardrobe.checks, 'independent checks', flush=True)


if __name__ == '__main__':
    main()
