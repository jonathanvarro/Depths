"""#220: gallery from real renderer captures; checks local artifact integrity."""
import argparse
import hashlib
import html
import json
from pathlib import Path
from PIL import Image


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True);args=p.parse_args()
    out=args.workspace/'build/local-padded-jacket-v2';review=out/'review'
    manifest=json.loads((out/'manifest.json').read_text());construction=json.loads((out/'construction.json').read_text())
    native=json.loads((review/'validation.json').read_text());headless=json.loads((review/'headless-validation.json').read_text())
    lineage=json.loads((out/'lineage-validation.json').read_text())
    assert all(not r['failures'] for r in [manifest,native,headless,lineage])
    assert native['display']=='Windows' and native['renderer']=='mobile'
    checks=5
    for fit,r in manifest['fits'].items():
        assert sha(out/r['master'])==r['master_sha256'];checks+=1
        assert sha(out/r['export'])==r['export_sha256'];checks+=1
        assert sha(Path(r['source_master']))==r['source_master_sha256'];checks+=1
        c=construction['fits'][fit]
        assert sha(Path(c['master']))==c['master_sha256'];checks+=1
        assert sha(out/'assets'/(fit+'-jacket-only.glb'))==lineage['fits'][fit]['sha256'];checks+=1
    for capture in native['captures']:
        path=review/capture['file']
        with Image.open(path) as im:
            assert list(im.size)==capture['size'] and im.width>0
            assert im.getextrema()[0][0]!=im.getextrema()[0][1]
        checks+=2
    cards=''
    for fit,r in manifest['fits'].items():
        stat=native['counts'][fit]
        cards+=f'''<article data-fit="{fit}"><h2>{fit.title()} fit</h2><img class="model" src="{fit}-detail-jacket-1.png" alt="Actual {fit} jacket in Godot"><p class="stats">{stat['triangles']:,} visible triangles · {stat['surfaces']} surfaces · {stat['bones']} bones</p><p><a href="../{html.escape(r['master'])}">Editable Blender</a> · <a href="../assets/{fit}-jacket-only.glb">Jacket only</a> · <a href="../{r['export']}">Full wardrobe GLB</a></p></article>'''
    template=Path(__file__).with_name('review.html').read_text(encoding='utf-8')
    template=template.replace('@@CARDS@@',cards).replace('@@NATIVE@@',str(native['checks'])).replace('@@HEADLESS@@',str(headless['checks'])).replace('@@EXPORT@@',str(manifest['checks'])).replace('@@LINEAGE@@',str(lineage['checks'])).replace('@@CAPTURES@@',str(len(native['captures'])))
    (review/'inspector.html').write_text(template,encoding='utf-8')
    artifacts={'checks':checks,'failures':[],'native_capture_count':len(native['captures']),
               'inputs':{name:sha(out/name) for name in ['manifest.json','construction.json','lineage-validation.json','review/validation.json','review/headless-validation.json']}}
    (out/'artifact-validation.json').write_text(json.dumps(artifacts,indent=2)+'\n')
    print('JACKET_ARTIFACTS',checks,'checks; real native captures',len(native['captures']))


if __name__=='__main__':main()
