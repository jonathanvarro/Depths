"""Review/provenance packaging for #220's isolated local jacket draft."""
import argparse
import hashlib
import html
import json
from pathlib import Path

from PIL import Image


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=Path, default=Path(__file__).resolve().parents[2])
    opt = parser.parse_args()
    out = opt.workspace.resolve() / 'build/local-padded-jacket-v1'
    record = json.loads((out/'manifest.json').read_text(encoding='utf-8'))
    checks = 0

    def check(ok, label):
        nonlocal checks
        checks += 1
        assert ok, label

    for fit, data in record['fits'].items():
        check(sha(out/data['master']) == data['master_sha256'], fit+' exact draft master')
        check(sha(Path(data['source_master'])) == data['source_sha256'], fit+' source master unchanged')
    for capture in record['captures']:
        with Image.open(out/'review'/capture['file']) as image:
            check(image.size==(420,560) and image.getextrema()[0][0]!=image.getextrema()[0][1],
                  'Actual nonblank Blender capture '+capture['file'])
    with Image.open(out/'concept-v1.png') as concept:
        check(concept.width>=1024 and concept.height>=1024, 'Saved concept sheet')
    provenance = {'tool':'Built-in ImageGen', 'input_images':[], 'source_models_uploaded':False,
                  'concept_sha256':sha(out/'concept-v1.png'),
                  'prompt_file':'concept-prompt.txt','prompt_sha256':sha(out/'concept-prompt.txt')}
    (out/'concept-provenance.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf-8')
    cards=''
    for fit,data in record['fits'].items():
        cards+=f'<article data-fit="{fit}"><h2>{fit.title()} draft</h2><img class="model" src="{fit}-rest-front.png" alt="Actual Blender {fit} jacket draft" width="420" height="560"><p><a href="../{html.escape(data["master"])}">Editable Blender copy</a></p></article>'
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Padded expedition jacket draft</title>
<style>body{margin:0;background:#1d2220;color:#e2dccb;font:17px/1.55 system-ui}main{max-width:1100px;margin:auto;padding:24px}h1,h2{font-family:Georgia,serif}a{color:#ddbf88}p,a{overflow-wrap:anywhere}.concept{width:100%;height:auto}.models{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}article{min-width:0;padding:12px;background:#27312e}.model{display:block;width:100%;height:auto}.controls{display:flex;gap:14px;flex-wrap:wrap;margin:20px 0}select{min-height:44px;font:inherit;color:inherit;background:#303c35;padding:5px}label{display:flex;gap:8px;align-items:center}.note{padding:12px;border-left:3px solid #b89c67;background:#2b352e}@media(max-width:700px){main{padding:12px}.models{gap:8px}article{padding:6px}}</style>
<main><h1>Padded expedition jacket · first draft</h1><p>Worn canvas, broad quilting, a low padded collar, three leather/wood closures and a repaired elbow. Same practical design for both body fits.</p>
<h2>Construction concept · generated</h2><img class="concept" src="../concept-v1.png" width="1536" height="1024" alt="Original padded jacket concept with front, back, side and closure views">
<p><a href="../concept-v1.png">Full concept</a> · <a href="../concept-prompt.txt">Exact generation prompt</a> · <a href="../concept-provenance.json">Concept provenance</a></p>
<h2>Editable blockouts · actual Blender renders</h2><p class="note">Early silhouette/detail drafts, not the finished textured concept. Collar joins, sleeve bulk, closure construction and motion clearance remain provisional. These use preserved assembly-v2 rigs and clips; Claude's #218 changes and any future T-pose rebind are not adopted. The male keeps his original lowered-arm rest pose. Existing source bodies and all previous masters remain unchanged.</p>
<div class="controls"><label>Pose <select id="pose"><option value="rest">Source rest</option><option value="idle">Provisional idle</option><option value="walk">Provisional walk</option><option value="sit_down">Chair sit-down end</option></select></label><label>Angle <select id="angle"><option value="front">Front</option><option value="side">Side</option><option value="back">Back</option></select></label></div><section class="models">@@CARDS@@</section>
<p>12 actual Blender captures. Draft checks preserve original rig/rest/body/UV/skin and source file hashes, with normalized garment weights. No engine export, full movement/contact acceptance, armour stats or live hookup is claimed.</p><p><a href="../manifest.json">Local draft manifest</a> · <a href="validation.json">Integrity checks</a></p></main>
<script>const pose=document.querySelector('#pose'),angle=document.querySelector('#angle');function update(){angle.disabled=pose.value!=='rest';for(const panel of document.querySelectorAll('[data-fit]'))panel.querySelector('img').src=panel.dataset.fit+'-'+pose.value+'-'+(pose.value==='rest'?angle.value:'quarter')+'.png';}pose.onchange=update;angle.onchange=update;</script></html>'''.replace('@@CARDS@@',cards)
    (out/'review/inspector.html').write_text(page,encoding='utf-8')
    report={'checks':checks,'failures':[],'build_draft_checks':record['checks'],
            'actual_blender_captures':len(record['captures']),'engine_fit_approved':False}
    (out/'review/validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PADDED_JACKET_REVIEW',report)


if __name__=='__main__':
    main()
