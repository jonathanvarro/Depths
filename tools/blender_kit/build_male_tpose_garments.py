"""Rebuild the male's tunic, belt, trousers and boots on his T-pose master.

Uses #211-#213's builder unchanged, pointed at male-tpose-v1 (from
rebind_male_tpose.py). The builder shapes and weights every garment from the
body at rest, so it now fits the T-pose bind. The older male garments and
masters are not touched. Legacy fitting clips are not retargeted here; the
per-body downloads are converted in the assembly.
"""
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
import build_garments

FOLDER = build_garments.BASE / 'male-tpose-v1'

if __name__ == '__main__':
    build_garments.BASE = FOLDER
    build_garments.OUT = FOLDER / 'garments'
    build_garments.OUT.mkdir(exist_ok=True)
    if (build_garments.OUT / 'male_garments.blend').exists() and '--rebuild' not in sys.argv:
        raise RuntimeError('T-pose garment master exists; pass -- --rebuild to replace it.')
    result = build_garments.build('male', with_motion=False)
    result['rest_pose'] = 'T-pose (owner request 2026-11-03)'
    (build_garments.OUT / 'male-manifest.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('MALE_TPOSE_GARMENTS', [g['name'] for g in result['garments']], flush=True)
