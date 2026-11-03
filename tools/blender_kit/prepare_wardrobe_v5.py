"""assembly-v5: assembly-v4 with the male rebound in his T-pose.

Owner request (2026-11-03): the male's T-pose becomes his real rest/bind
pose. The male body, Dying and clothing come from male-tpose-v1
(rebind_male_tpose.py, build_male_tpose_garments.py); every male clip is
converted afresh from his Mixamo downloads onto the new rest. The female
side, including v4's hand lift, is unchanged. Earlier assemblies, masters
and garments are not touched.
"""
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
import prepare_wardrobe_v4 as v4

current = v4.v3.current
OUT = current.BASE / 'assembly-v5'
TPOSE = current.BASE / 'male-tpose-v1'


def main():
    v4.OUT = OUT
    current.GARMENTS = {'male': TPOSE / 'garments'}
    current.NO_CACHE = {'male'}
    v4.main()
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    manifest['fits']['male']['fit_id'] = 'male-tpose-v1'
    manifest['fits']['male']['rest_pose'] = 'T-pose (owner request 2026-11-03)'
    manifest.update({
        'version': 5,
        'review_footer': 'Male rebound in T-pose · female sit-down hands lifted · source faces unchanged',
        'animation_limits': manifest['animation_limits'] + ' assembly-v5: the male is rebound in his T-pose (from his own Mixamo downloads); his clothing is rebuilt on that body and every male clip, including Dying, is converted onto the new rest.',
    })
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('WARDROBE_V5_READY', flush=True)


if __name__ == '__main__':
    main()
