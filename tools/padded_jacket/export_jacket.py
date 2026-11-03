"""#220: reuse the checked reversible-body exporter with local jacket inputs.

Run in Blender after build_jacket.py. Reuses existing geometry/export checks;
adds outfit metadata and a native reviewer without touching existing tools.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender_kit'))
import prepare_wardrobe as exporter


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    out=args.workspace/'build/local-padded-jacket-v2';inputs=out/'export-inputs';inputs.mkdir(exist_ok=True)
    (inputs/'.gdignore').touch()
    construction=json.loads((out/'construction.json').read_text())
    source_root=Path(construction['source_assembly'])
    assert sha(source_root/'manifest.json')==construction['source_manifest_sha256'],'Source snapshot changed'
    baseline=json.loads((source_root/'manifest.json').read_text())
    for fit,r in construction['fits'].items():
        record={'master':r['master'],'garments':r['garments'],'received_profile':True,
                'motions':[m for m in r['motions'] if m['id']!='dying'],
                'parameters':{'boot.'+s:{'sole_bottom':r['floor_y']+.002} for s in ['left','right']}}
        (inputs/(fit+'-manifest.json')).write_text(json.dumps(record,indent=2)+'\n')
    exporter.SOURCE=inputs;exporter.OUT=out;exporter.BASE=args.workspace/'build'
    fits={fit:exporter.build(fit) for fit in ['female','male']}
    for fit,r in fits.items():
        r['fit_id']=construction['fits'][fit]['fit_id'];r['garments']=construction['fits'][fit]['garments']
        r['source_master']=construction['fits'][fit]['source_master']
        r['source_master_sha256']=construction['fits'][fit]['source_master_sha256']
    manifest=dict(baseline,version='padded-jacket-v2',fits=fits,checks=exporter.checks,failures=[],
                  outfits=['jacket','tunic'],default_outfit='jacket',
                  review_footer='Padded expedition jacket · same body and motions · reversible Tunic/Jacket swap',
                  all_assets_local=True)
    templates=ROOT/'tools/blender_kit';here=Path(__file__).parent
    for source,target in [('wardrobe_actor.gd','actor_base.gd'),('wardrobe_review.gd','review_base.gd')]:shutil.copy2(templates/source,out/target)
    for name in ['actor.gd','review.gd']:shutil.copy2(here/name,out/name)
    check=(templates/'check_wardrobe.gd').read_text(encoding='utf-8')
    marker='\tvar totals:={}'
    assert check.count(marker)==1,'Native suite changed; review hook first'
    check=check.replace(marker,'\tawait jacket_checks()\n'+marker)
    check+='\n'+(here/'jacket_checks.gd').read_text(encoding='utf-8')
    (out/'check.gd').write_text(check,encoding='utf-8')
    manifest['reused_tool_hashes']={p.name:sha(p) for p in [templates/'prepare_wardrobe.py',templates/'check_wardrobe.gd',templates/'wardrobe_actor.gd',templates/'wardrobe_review.gd']}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    for name in ['project.godot','review.tscn','display_normalization.json']:shutil.copy2(source_root/name,out/name)
    exe=args.workspace/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    (out/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n')
    print('JACKET_EXPORT_READY',exporter.checks,'independent checks',flush=True)


if __name__=='__main__':main()
