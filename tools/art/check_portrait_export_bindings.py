"""Older exporters must preserve complete components, including the clean face."""
from pathlib import Path
import sys, subprocess, json
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
import build_recruit_portraits as kit

catalog=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
count=0
for entry in catalog['portraits']+catalog['supporting_resources']:
 path=ROOT/entry['resource'].removeprefix('res://')
 original=subprocess.check_output(['git','show','3d1ee08:'+path.relative_to(ROOT).as_posix()],cwd=ROOT,text=True)
 corrected='\n'.join(kit.prefer_pixel_frames(original.splitlines()))+'\n'
 assert corrected==path.read_text(encoding='utf-8'),path
 count+=1
print(f'Exporter compatibility: all {count} resources preserve exact complete-component bindings.')
