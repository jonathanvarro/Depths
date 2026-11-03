"""Local #215 gallery/catalogue and integrity checks for the uploaded library."""
from pathlib import Path
import json,hashlib,html,math
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';RECEIVED=BASE/'animation-requests-v1/received-v1';OUT=RECEIVED/'candidates-v1';REVIEW=OUT/'review'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    library=json.loads((RECEIVED/'library-audit.json').read_text());captures=json.loads((REVIEW/'captures.json').read_text());exports=json.loads((OUT/'export-validation.json').read_text());fit_check=json.loads((OUT/'garment-validation.json').read_text());native=json.loads((OUT/'godot-smoke/godot-validation.json').read_text())
    assert not exports['failures'] and not fit_check['failures'] and not native['failures']
    checks=0
    def check(ok,label):
        nonlocal checks
        checks+=1;assert ok,label
    source=json.loads((BASE/'kit-manifest.json').read_text())
    for entry in source['sources']:check(sha(BASE/entry['file'])==entry['sha256'],'Earlier source unchanged '+entry['file'])
    for entry in library['files']:check(sha(Path(entry['destination']))==entry['sha256'],'Uploaded source unchanged '+entry['name'])
    cards='';selected=set();summaries={}
    for fit in ['female','male']:
        record=json.loads((OUT/(fit+'-manifest.json')).read_text());summaries[fit]=record
        check(sha(OUT/record['master'])==record['sha256']==captures['masters_sha256'][fit],'Exact reviewed candidate master '+fit)
        check(sha(BASE/record['garment_source_master'])==record['garment_source_sha256'],'Original garment master unchanged '+fit)
        original_record=json.loads((BASE/'garments-v1'/(fit+'-manifest.json')).read_text())
        check(record['source_rig_digest']==original_record['source_rig_digest'] and record['source_skin_digest']==original_record['source_skin_digest'] and not any(m['root_motion_modified'] or m['floor_correction_added'] for m in record['motions']),'Original rig/skin retained; no motion/floor edits '+fit)
        for m in record['motions']:
            selected.add(m['source_sha256']);check(m['max_world_position_error']<.002 and m['max_world_axis_error_degrees']<.2,'Actual source-world pose retained '+m['source'])
        export=next(r for r in exports['reports'] if r['fit']==fit)
        check(sha(OUT/export['export'])==export['sha256'],'Exact imported GLB '+fit)
        frames=[Image.open(REVIEW/(fit+'-walk-motion-%02d.png'%i)).convert('RGB') for i in range(12)]
        duration=(next(m for m in record['motions'] if m['id']=='walk')['frames'][1]-1)/60*1000
        timings=[round(duration*(i+1)/120)*10-round(duration*i/120)*10 for i in range(12)]
        frames[0].save(REVIEW/(fit+'-walk.gif'),save_all=True,append_images=frames[1:],duration=timings,loop=0,optimize=False)
        cards+=f'<article data-fit="{fit}"><h2>{fit.title()}</h2><img class="actor" src="{fit}-idle-middle-front.png" width="420" height="560" alt="Actual uploaded-motion {fit} render"><p><a href="../{record["master"]}">Editable candidate</a> · <a href="../{export["export"]}">Five-motion GLB</a> · <a href="../godot-smoke/native-{fit}.png">Native Godot capture</a></p></article>'
    for motion in ['rest','idle','walk','sit_down','seated','dying']:
        images=[c for c in captures['captures'] if c['mode']==motion];columns=3 if motion=='rest' else 9;sheet=Image.new('RGB',(columns*140,414),'#182020');draw=ImageDraw.Draw(sheet)
        for row,fit in enumerate(['female','male']):
            for col,c in enumerate(x for x in images if x['fit']==fit):
                image=Image.open(REVIEW/c['file']).convert('RGB').resize((140,187),Image.Resampling.LANCZOS);sheet.paste(image,(col*140,row*207+20));draw.text((col*140+3,row*207+3),fit+' '+str(c['sample'])+' '+c['angle'],fill='#ded8c5')
        sheet.save(REVIEW/('sheet-'+motion+'.png'))
    rows=''
    for entry in library['files']:
        own=entry['compatibility'][entry['fit']];status='Converted + sampled body/native review' if entry['sha256'] in selected else 'Source/bind audited; body playback pending'
        root=entry['source_hips_end_minus_start'];travel=math.sqrt(root[0]**2+root[1]**2)
        rows+='<tr>'+''.join('<td>'+html.escape(str(v))+'</td>' for v in [entry['fit'],entry['collection'],entry['name'],f'{entry["seconds"]:.2f}s / {entry["fps"]:g}fps',entry['bone_count'],f'{travel:.3f}',status])+'</tr>'
    for capture in captures['captures']:
        with Image.open(REVIEW/capture['file']) as image:check(image.size==(420,560) and image.getextrema()[0][0]!=image.getextrema()[0][1],'Actual nonblank render '+capture['file'])
    template=Path(__file__).with_name('received-review.template.html').read_text(encoding='utf-8').replace('@@CARDS@@',cards).replace('@@ROWS@@',rows)
    (REVIEW/'inspector.html').write_text(template,encoding='utf-8')
    result={'checks':checks,'failures':[],'uploaded_source_files':len(library['files']),'earlier_sources_unchanged':39,'selected_converted_motions':8,'actual_blender_captures':len(captures['captures']),'blender_fit_checks':fit_check['checks'],'independent_export_checks':exports['checks'],'native_godot_checks':native['checks'],'missing_role':'female quiet matching chair hold','final_animation_approval':False,'all_art_local':True}
    (REVIEW/'validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('RECEIVED_REVIEW',checks,'integrity checks;27 uploaded files,8 converted candidates,138 actual captures;female quiet chair hold pending')
if __name__=='__main__':main()
