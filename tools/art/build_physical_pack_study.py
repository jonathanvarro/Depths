"""Build the #109 visual review from #61's existing interaction study.

Only crop/scale/palette export and existing UI assembly; no painted edits.
"""
from pathlib import Path
from PIL import Image
import hashlib,json,os

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/interface/pack-heroes-v3'
SOURCE=ROOT/'art/source/pack-heroes-v3'

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    (OUT/'assets').mkdir(parents=True,exist_ok=True)
    (OUT/'.gdignore').touch()
    exports=[]
    for name in ['bag','roll']:
        src=SOURCE/(name+'.png')
        im=Image.open(src).convert('RGBA')
        assert im.size==(1536,1024) and im.getchannel('A').getextrema()[0]==0
        im=im.resize((768,512),Image.Resampling.NEAREST)
        # Preserve generated alpha, including the soft edges. No new cutout.
        dest=OUT/'assets'/(name+'.png');im.save(dest)
        exports.append({'source':src.relative_to(ROOT).as_posix(),'source_sha256':sha(src),
            'output':dest.relative_to(ROOT).as_posix(),'output_sha256':sha(dest),
            'size':list(im.size),'operation':'2x nearest-neighbour reduction; original generated alpha retained'})
    old=ROOT/'art/concepts/interface/pack-heroes-v2'
    html=(old/'source.fragment.html').read_text(encoding='utf-8')
    html=html.replace("const roles=[['head','Head'],['body','Body'],['accessory','Accessory'],['main','Main hand'],['off','Off hand'],['feet','Feet']];", "const roles=[['main','Weapon'],['body','Body']];")
    html=html.replace("role:'Guide'","role:'Rogue'")
    html=html.replace("const gear=['knife','club','spear','staff','shield','coat']", "const gear=['knife','club','spear','staff','coat']")
    html=html.replace("name:'Plain knife',type:'Main hand'", "name:'Plain knife',type:'Weapon'")
    html=html.replace("<h3>Combat</h3><dl><dt>Base attack</dt><dd class=\"number\">2–4</dd><dt>Base accuracy</dt><dd class=\"number\">75%</dd><dt>Initiative</dt><dd class=\"number\">10</dd></dl><p class=\"small muted\">Current strain reduces effectiveness.</p>","<h3>Trait</h3><p>Keen eyes</p><p class=\"small muted\">Traps show before you step on them.</p>")
    html=html.replace("feedback:'Browsing costs no time.'", "feedback:'Visual study · Sample inventory · Browsing costs no time.'")
    html=html.replace("state.feedback='Browsing costs no time.'", "state.feedback='Visual study · Sample inventory · Browsing costs no time.'")
    # Readouts in this isolated demonstration remain explicit fixtures.
    html=html.replace('<div class="bag" aria-label="Inventory slots"></div>', '<div class="physical-bag"><div class="bag" aria-label="Inventory slots"></div></div>')
    css=(OUT/'physical.css').read_text(encoding='utf-8')
    html=html.replace('</style>',css+'\n</style>',1)
    mapping={entry['id']:ROOT/entry['output'] for entry in json.loads((old/'manifest.json').read_text())['assets']}
    mapping['mara']=ROOT/'art/portraits/mara-neutral-v1/preview.png'
    for key,path in mapping.items():html=html.replace('@@'+key+'@@',Path(os.path.relpath(path,OUT)).as_posix())
    assert '@@' not in html
    html='<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Pack and Equipment study</title><style>html,body{margin:0;background:#11130f}body{min-width:320px}</style></head><body>\n'+html+'\n</body></html>\n'
    (OUT/'pack-heroes.html').write_text(html,encoding='utf-8',newline='\n')
    (OUT/'manifest.json').write_text(json.dumps({'issue':109,'kind':'Isolated browser visual review; live game unchanged',
        'source_interactions':(old/'source.fragment.html').relative_to(ROOT).as_posix(),
        'source_interactions_sha256':sha(old/'source.fragment.html'),'exports':exports,
        'existing_art':{key:path.relative_to(ROOT).as_posix() for key,path in mapping.items()},
        'source_of_truth':'Existing game rules; sample gear/health/light in review are fixtures, not starting grants.'},indent=2)+'\n',encoding='utf-8')
    print('Built physical Pack/Equipment review with two generated surfaces and existing project art/fonts.')

if __name__=='__main__':main()
