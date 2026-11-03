"""Isolated #217/#167 engine asset project, without Main or player settings."""
import argparse
import json
from pathlib import Path
import re
import shutil

ROOT=Path(__file__).resolve().parents[2]
TARGET=ROOT/'build/audio-asset-check'


def main():
    p=argparse.ArgumentParser();p.add_argument('--configure-imports',action='store_true');args=p.parse_args()
    entries=[]
    for family in ['field-v1','galleries-v1']:
        data=json.loads((ROOT/'audio'/family/'catalog.json').read_text(encoding='utf-8'))
        entries+=data['assets']
    if not args.configure_imports:
        TARGET.mkdir(parents=True,exist_ok=True)
        for e in entries:
            source=ROOT/e['file'];dest=TARGET/e['file'];dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source,dest)
            if Path(str(source)+'.import').exists():shutil.copy2(str(source)+'.import',str(dest)+'.import')
        shutil.copy2(Path(__file__).with_name('check_field_assets.gd'),TARGET/'check.gd')
        (TARGET/'catalog.json').write_text(json.dumps({'assets':entries},indent=2)+'\n',encoding='utf-8')
        (TARGET/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Depths audio asset check"\n[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.mobile="mobile"\nrendering_device/driver.windows="d3d12"\n',encoding='utf-8')
    else:
        for e in entries:
            sidecar=TARGET/(e['file']+'.import');text=sidecar.read_text(encoding='utf-8')
            for key,value in [('edit/normalize','false'),('edit/trim','false'),('edit/loop_mode','2' if e['loop'] else '1'),('compress/mode','2' if e.get('music',False) else '0')]:
                text=re.sub('^'+re.escape(key)+'=.*$',key+'='+value,text,flags=re.M)
            sidecar.write_text(text,encoding='utf-8')
            shutil.copy2(sidecar,ROOT/(e['file']+'.import'))
    print('AUDIO_ASSET_PROJECT',len(entries),'assets; configured imports',args.configure_imports)


if __name__=='__main__':main()
