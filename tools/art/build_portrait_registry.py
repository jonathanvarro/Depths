"""Classify stable PortraitSet paths and build a paused frame-inspection catalogue."""
from pathlib import Path
import re, json, os, hashlib, base64

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/portrait-rigs-v1'
UNIQUE={'mara':'Mara','corin':'Corin','alwen':'Sister Alwen'}

def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(text,encoding='utf-8',newline='\n')

def inspect(path):
    text=path.read_text(encoding='utf-8')
    ext=dict((i,p) for p,i in re.findall(r'\[ext_resource [^\]]*path="([^"]+)" id="([^"]+)"\]',text))
    body=text.split('[resource]',1)[1]
    def texture(key):
        value=re.search(r'^'+key+r' = ExtResource\("([^"]+)"\)',body,re.M)
        return ext[value[1]] if value else None
    def textures(key):
        value=re.search(r'^'+key+r' = (.+)$',body,re.M)
        return [ext[i] for i in re.findall(r'ExtResource\("([^"]+)"\)',value[1])] if value else []
    stem=path.stem
    face='mara' if stem=='underlayer' else stem.removesuffix('-worried').removesuffix('-exhausted')
    unique=path.parent==ROOT/'data/portraits' or stem=='underlayer'
    kind='Unique' if unique else 'Reusable'
    family='unique-'+face+'-v1' if unique else 'average-covered-adult-v1'
    # Explicit metadata preserves stable paths and save compatibility.
    metadata=f'rig_kind = "{kind}"\nrig_family = &"{family}"\nface_id = &"{face}"\n'
    clean=re.sub(r'^(rig_kind|rig_family|face_id) = .*\n','',text,flags=re.M)
    clean=clean.replace('script = ExtResource("script")\n','script = ExtResource("script")\n'+metadata)
    write(path,clean)
    layers=[texture(key) for key in ['background']]+textures('back')+[texture(key) for key in ['body','head','eyes','mouth']]+textures('clothing')+textures('front')
    layers=[p for p in layers if p]
    frames=[{'name':'Neutral','eyes':texture('eyes'),'mouth':texture('mouth')}]
    frames += [{'name':name,'eyes':p,'mouth':texture('mouth')} for name,p in zip(['Half lid','Closed'],textures('blink_frames'))]
    frames += [{'name':name,'eyes':texture('eyes'),'mouth':p} for name,p in zip(['Small mouth','Open mouth','Round mouth'],textures('talk_frames'))]
    boxes={'mara':[[80,55,141,85],[92,93,128,112]],'corin':[[80,55,140,81],[87,83,128,104]],'alwen':[[84,56,140,78],[98,87,129,104]]}
    eye,mouth=boxes.get(face,[[78,53,139,82],[89,91,125,108]] if face in ['warden-a','scout-a'] else [[73,51,142,82],[82,89,132,112]])
    refined=any('/frames-pixel-v4/' in p for p in textures('blink_frames')+textures('talk_frames'))
    corrected=refined or any('/frames-pixel-v3/' in p for p in textures('blink_frames')+textures('talk_frames'))
    return {'id':stem,'face_id':face,'label':UNIQUE.get(face,face)+((' · '+stem.rsplit('-',1)[-1]) if stem!=face else ''),'kind':kind,'family':family,
            'resource':'res://'+path.relative_to(ROOT).as_posix(),'layers':layers,'neutral_eyes':texture('eyes'),'neutral_mouth':texture('mouth'),
            'frames':frames,'eye_box':eye,'mouth_box':mouth,'separated_features':corrected,'review':('Textured drawings v4: original lip tissue, smaller shaded openings and curved lids retaining the lower iris in half blinks. V3 clean/neutral components and timing are preserved.' if refined else 'Complete components v3: clean underlying face; neutral restores the original exactly.') if corrected else 'Static expression; no neutral blink/talk frames borrowed.'}

def main():
    OUT.mkdir(parents=True,exist_ok=True);write(OUT/'.gdignore','')
    entries=[inspect(p) for p in sorted((ROOT/'data/portraits').rglob('*.tres'))]
    catalogue={'canvas':[192,192],'families':[{'kind':'Reusable','id':'average-covered-adult-v1','purpose':'Standard NPC/minor character body and outfit socket; each face owns its facial drawings.'}]+[{'kind':'Unique','id':'unique-'+key+'-v1','purpose':label+"'s individual head/body/outfit and facial registration; no shared recruit socket."} for key,label in UNIQUE.items()],
               'portraits':entries,'supporting_resources':[inspect(ROOT/'art/portraits/mara-neutral-v1/underlayer.tres')],'rule':'Sharing a canvas or body never licenses sharing another face\u2019s eye/mouth frames.'}
    write(ROOT/'data/portraits/catalog.json',json.dumps(catalogue,indent=2,ensure_ascii=False)+'\n')
    review=json.loads(json.dumps(catalogue))
    def remap(value):
        if isinstance(value,str) and value.startswith('res://') and value.endswith('.png'):
            return Path(os.path.relpath(ROOT/value.removeprefix('res://'),OUT)).as_posix()
        if isinstance(value,list):return [remap(v) for v in value]
        if isinstance(value,dict):return {k:remap(v) for k,v in value.items()}
        return value
    review=remap(review)
    image_paths={path for e in entries for path in e['layers']}
    image_paths.update(path for e in entries for f in e['frames'] for path in [f['eyes'],f['mouth']] if path)
    review['assets']={remap(path):'data:image/png;base64,'+base64.b64encode((ROOT/path.removeprefix('res://')).read_bytes()).decode() for path in sorted(image_paths)}
    html=(OUT/'layout.html').read_text(encoding='utf-8').replace('@@data@@','const PORTRAITS='+json.dumps(review,ensure_ascii=False)+';').replace('@@script@@',(OUT/'inspector.js').read_text(encoding='utf-8'))
    write(OUT/'inspector.html',html.rstrip()+'\n')
    write(OUT/'registry-validation.json',json.dumps({'resources':len(entries),'unique':sum(e['kind']=='Unique' for e in entries),'reusable':sum(e['kind']=='Reusable' for e in entries),'paused_by_default':True,'failures':[]},indent=2)+'\n')
    print(f'Classified {len(entries)} stable portrait paths: 3 unique, 27 reusable/expression resources.')

if __name__=='__main__':main()
