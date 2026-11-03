"""#218: assembly-v3, the current wardrobe review with the female chair hold.

Same clips as assembly-v2 except the female seated motion, which is the
owner's chosen calm hold (Sitting.fbx from female-hold-intake-v1) instead of
Sitting Talking. Adds a "chair sequence" that plays sit-down, seated and
stand-up back to back; the Godot actor aligns each clip's hips horizontally
at the joins. assembly-v2, intakes and masters are not changed.
"""
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
import prepare_current_wardrobe as current
import prepare_wardrobe as wardrobe

OUT = current.BASE / 'assembly-v3'
HOLD = current.BASE / 'animation-requests-v1/female-hold-intake-v1'


def main():
    current.OUT = OUT
    current.SOURCES = OUT / 'editable-inputs'
    current.SEATED = {'female': (HOLD, 'Sitting.fbx')}
    current.SOURCES.mkdir(parents=True, exist_ok=True)
    (current.SOURCES / '.gdignore').touch()
    for fit in ['female', 'male']:
        current.prepare_fit(fit)
    # Name the female seated clip for what it now is.
    record_path = current.SOURCES / 'female-manifest.json'
    record = json.loads(record_path.read_text(encoding='utf-8'))
    for motion in record['motions']:
        if motion['id'] == 'seated':
            motion['role'] = 'Calm chair hold chosen by the owner (2026-11-02, #218)'
    record_path.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    wardrobe.SOURCE = current.SOURCES
    wardrobe.OUT = OUT
    wardrobe.main()
    manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    manifest.update({
        'version': 3,
        'motion_order': ['rest', 'idle', 'walk', 'sit_down', 'seated', 'stand_up', 'chair_sequence', 'dying'],
        'motion_labels': ['Neutral fit', 'Idle · body pack', 'Walk · body pack', 'Sit down · chair',
                          'Seated · chair hold', 'Stand up · chair', 'Chair sequence · aligned', 'Dying · original'],
        'sequences': {'chair_sequence': ['sit_down', 'seated', 'stand_up']},
        'review_footer': 'Per-body motions · female seated = calm chair hold · source faces unchanged',
        'animation_limits': '#218: female seated is now the owner-chosen calm chair hold (Sitting.fbx); male seated is chair Sitting Idle. "Chair sequence" plays sit-down, seated and stand-up back to back. At each join the reviewer moves the whole model sideways so the hips line up; height is never changed, so the fixed floor stays put and any seat-height difference stays visible. Source curves are untouched and there is no crossfade, so small pose differences at joins (mostly hands) show as a snap. Walk/idle loops, IK and in-place derivatives are still not approved; playback stops at the real end.',
        'quiet_female_chair_hold_available': True,
        'final_animation_acceptance_pending': 218,
        'animation_polish_issue': 218,
        'source_manifests': ['animation-requests-v1/received-v1/source-manifest.json',
                             'animation-requests-v1/female-chair-intake-v1/source-manifest.json',
                             'animation-requests-v1/female-hold-intake-v1/source-manifest.json'],
        'delivery_scope': 'Wardrobe review with calm female chair hold and aligned chair sequence; owner style acceptance separate',
    })
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('WARDROBE_V3_READY', wardrobe.checks, 'independent checks', flush=True)


if __name__ == '__main__':
    main()
