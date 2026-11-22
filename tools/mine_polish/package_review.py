"""Copy only native captures selected by the repository review gallery."""
import argparse
from pathlib import Path
import re
import shutil
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
review=ROOT/'art/concepts/mine-polish-v2'
local=args.workspace/'build/local-mine-polish-v2'
names=re.findall(r"\['([^']+)','",(review/'inspector.html').read_text(encoding='utf-8'))
(review/'captures').mkdir(exist_ok=True)
for name in names:
    source=next((folder/(name+'.png') for folder in [local/'captures',local/'checks'] if (folder/(name+'.png')).is_file()),None)
    assert source is not None,name
    shutil.copy2(source,review/'captures'/(name+'.png'))
shutil.copy2(local/'checks/validation.json',review/'validation.json')
print('Packaged',len(names),'native captures without altering the images.')
