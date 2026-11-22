"""Prepare the private stool reviewer and gallery, with no public character media."""
import argparse
import html
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True);args=p.parse_args()
    out=args.workspace/'build/local-companion-polish-v1'
    for name in ['editable','masters','export-inputs']:
        (out/name).mkdir(exist_ok=True);(out/name/'.gdignore').touch()
    target=out/'art/dressing/camp-stool-v1';target.mkdir(parents=True,exist_ok=True)
    for name in ['stool.glb','stool.tscn']:shutil.copy2(ROOT/'art/dressing/camp-stool-v1'/name,target/name)
    shutil.copy2(target/'stool.tscn',out/'stool.tscn')
    for name in ['check_contacts.gd','stool_review.gd']:shutil.copy2(Path(__file__).parent/name,out/name)
    scene=out/'review.tscn';scene.write_text(scene.read_text().replace('res://review.gd','res://stool_review.gd'))
    project=out/'project.godot';text=project.read_text()
    if '[filesystem]' not in text:project.write_text(text+'\n[filesystem]\nimport/blender/enabled=false\n')
    # The seat reviewer deliberately opens seated; the inherited height check
    # measures the neutral body, so make its starting pose explicit.
    suite=out/'check.gd';text=suite.read_text()
    text=text.replace('root.add_child(app);await settle()',
                      'root.add_child(app);app.set_motion("rest",0,true);await settle()')
    suite.write_text(text,encoding='utf-8')
    cards=[]
    for image in sorted((out/'review').glob('*.png')):
        if image.name.startswith(('approach','hold-early','hold-late','rise-early','rise-late','rest-fits','jacket-only')):
            cards.append(f'<figure><a href="{image.name}" target="_blank"><img loading="lazy" src="{image.name}" alt="{html.escape(image.stem)}"></a><figcaption>{html.escape(image.stem)}</figcaption></figure>')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Companion seat fit</title><style>body{background:#151b18;color:#ddd4bd;font:16px/1.5 Georgia,serif;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,500px),1fr));gap:18px}figure{margin:0;border:1px solid #806c44}img{width:100%;display:block}figcaption{padding:12px}a{color:#dfbd82}</style><h1>Companion jacket · fixed seat review</h1><p>Both editable fits have a shorter cutaway hem and revised cloth weights. Source body, rigs, Actions, stool and floor remain unchanged. Actual Godot Mobile renders; each body uses its own sit/hold/rise timings. Original source walk/death contact limits remain documented; this is garment polish, not a new animation library.</p><p><a href="../START_REVIEW.cmd">Interactive local reviewer</a> · <a href="../seat-fit-validation.json">Frame-by-frame seat intersection audit</a> · <a href="../contact-native.json">Native control/contact checks</a> · <a href="../construction.json">Editable masters and source lineage</a></p><main>'''+''.join(cards)+'</main></html>'
    (out/'review/inspector.html').write_text(page,encoding='utf-8')
    print('Private companion review prepared',out/'review/inspector.html')
if __name__=='__main__':main()
