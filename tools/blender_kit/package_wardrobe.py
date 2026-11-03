"""#214 local gallery: actual Godot captures, native cards and real-frame GIFs."""
from pathlib import Path
import json,hashlib,html
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/assembly-v1';REVIEW=OUT/'review'

def main():
    manifest=json.loads((OUT/'manifest.json').read_text());report=json.loads((REVIEW/'validation.json').read_text())
    assert not report['failures'] and report['display']!='headless','Run the native Mobile check first'
    for fit,data in manifest['fits'].items():
        assert hashlib.sha256((OUT/data['master']).read_bytes()).hexdigest()==data['master_sha256']
        frames=[Image.open(REVIEW/(fit+'-walk-frame-%02d.png'%i)).convert('RGB') for i in range(12)]
        elapsed=next(m for m in data['motions'] if m['id']=='walk')['frames'][1]-1
        duration=elapsed/60*1000;timings=[round(duration*(i+1)/120)*10-round(duration*i/120)*10 for i in range(12)]
        frames[0].save(REVIEW/(fit+'-walk.gif'),save_all=True,append_images=frames[1:],duration=timings,loop=0,optimize=False)
    for motion in manifest.get('motion_order',['rest','idle','walk','sit_down','seated','dying']):
        samples=[0] if motion=='rest' else [0,1,2];columns=3*len(samples)
        sheet=Image.new('RGB',(columns*180,2*185),'#151c1c');draw=ImageDraw.Draw(sheet)
        for row,fit in enumerate(['female','male']):
            for col,(sample,angle) in enumerate((s,a) for s in samples for a in [0,2,3]):
                image=Image.open(REVIEW/(f'{fit}-{motion}-{sample}-{angle}.png')).convert('RGB');image.thumbnail((180,160),Image.Resampling.LANCZOS)
                sheet.paste(image,(col*180+(180-image.width)//2,row*185+25));draw.text((col*180+4,row*185+4),f'{fit} {sample} '+{0:'front',2:'side',3:'back'}[angle],fill='#ddd4bb')
        sheet.save(REVIEW/('sheet-'+motion+'.png'))
    cards=''
    for fit,data in manifest['fits'].items():
        stats=report['counts'][fit]
        cards+=f'''<article data-fit="{fit}"><h2>{fit.title()} fit</h2><img class="model" src="{fit}-rest-0-0.png" alt="Actual {fit} native render"><p>{stats['triangles']:,} triangles · {stats['surfaces']} visible surfaces · {stats['bones']} joints</p><p><a href="../{data['master']}">Editable Blender master</a> · <a href="../{data['export']}">Reversible review GLB</a></p></article>'''
    template=Path(__file__).with_name('wardrobe.template.html').read_text(encoding='utf-8')
    template=template.replace('@@CARDS@@',cards).replace('@@CAPTURES@@',str(len(report['captures']))).replace('@@CHECKS@@',str(report['checks']))
    if manifest.get('version',1)>=2:
        template=template.replace('<strong>Final animation acceptance is pending #215.</strong> These are the existing temporary fitting clips. Chair-height sit-down and reclined ground idle are separate poses.',
            '<strong>Current per-body animation review.</strong> Each body uses its own uploaded clips. Female seated is a crossed-leg talking stress test; male seated is a chair idle. Calm female sitting, source contacts and seamless transitions remain visible follow-up limits.')
        template=template.replace('Idle · fitting','Idle · body pack').replace('Walk · fitting','Walk · body pack')
        template=template.replace('Ground sit · separate clip','Seated · talk / idle').replace('Ground seated','Seated stress test')
        template=template.replace('<option value="dying">','<option value="stand_up">Stand-up · chair</option><option value="dying">')
        template=template.replace('<a href="sheet-dying.png">','<a href="sheet-stand_up.png">Chair stand-up</a><a href="sheet-dying.png">')
        template=template.replace('The source clip\'s loop/in-place status is unapproved;',
            'Matrix samples use each body\'s own start/middle/end. Interactive playback retains original seconds. Both walks travel, and loop status is unapproved;')
    if manifest.get('version',1)>=3:
        template=template.replace('Female seated is a crossed-leg talking stress test; male seated is a chair idle. Calm female sitting, source contacts and seamless transitions remain visible follow-up limits.',
            'Both bodies now sit in a calm chair hold (#218). <em>Chair sequence</em> plays sit-down, hold and stand-up back to back with the hips aligned sideways at each join; hand snaps at joins and source contacts remain visible limits.')
        template=template.replace('Seated · talk / idle','Seated · chair hold').replace('Seated stress test','Seated chair hold')
        template=template.replace('<option value="dying">','<option value="chair_sequence">Chair sequence · aligned</option><option value="dying">')
        template=template.replace('<a href="sheet-dying.png">','<a href="sheet-chair_sequence.png">Chair sequence</a><a href="chair-sequence-joins-sheet.png">Sequence joins</a><a href="sheet-dying.png">')
    (REVIEW/'inspector.html').write_text(template,encoding='utf-8')
    doc=ROOT/('docs/female-chair-hold-review.md' if manifest.get('version',1)>=3 else 'docs/current-wardrobe-review.md' if manifest.get('version',1)>=2 else 'docs/blender-wardrobe-review.md')
    if doc.exists():(OUT/'START_HERE.md').write_text(doc.read_text(encoding='utf-8'),encoding='utf-8')
    print('WARDROBE_GALLERY',len(report['captures']),'actual captures; 24 native cards; two real-frame GIFs')
if __name__=='__main__':main()
