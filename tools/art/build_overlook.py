"""#190: mechanical exports and registered placements for the selected Overlook.

Paintings/cutouts are built-in ImageGen outputs. No background is painted here.
Source alpha is retained; invisible RGB is cleared before ordinary resampling.
"""
from pathlib import Path
import hashlib, json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/source/overlook-v1'
OUT=ROOT/'art/camp/overlook-v1'
REVIEW=ROOT/'art/concepts/overlook-v1'
CANVAS=(1600,900)
BOUNDS={
    'shelter':[280,142,432,230],
    'stash':[116,326,263,170],
    'survey':[710,305,245,170],
    'firepit':[380,365,270,169],
    'supplies':[151,500,274,143],
    'lantern':[638,213,22,36],
    'flame':[468,375,49,61],
    'corin-equipment':[557,356,112,168],
    'mara-warming':[330,350,168,168],
    'alwen-reading':[699,316,98,155],
    'fixer-planning':[659,245,151,204],
    'mara-relaxing':[424,268,175,119],
}
PEOPLE={'corin-equipment':'corin','mara-warming':'mara','alwen-reading':'alwen','fixer-planning':'fixer-a','mara-relaxing':'mara'}
TARGETS=[
    {'id':'mine','label':'Back to the mine','rect':[24,66,215,174],'requires':[]},
    {'id':'stash','label':'Stash','rect':[110,321,270,180],'requires':['stash']},
    {'id':'fire','label':'Talk by the fire','rect':[389,369,261,167],'requires':['firepit']},
    {'id':'survey','label':'Survey table','rect':[707,301,253,179],'requires':['survey']},
    {'id':'onward','label':'Toward the hold','rect':[1105,465,257,217],'requires':[]},
]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def js(p,v):write(p,json.dumps(v,indent=2)+'\n')

def cutout(raw,rect,dest):
    assert raw.mode=='RGBA' and raw.getchannel('A').getextrema()[0]==0, 'Generated alpha required: '+dest.name
    raw=raw.convert('RGBA')
    # Ignore service fringe below 8/255 when locating bounds, not when drawing.
    box=raw.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox()
    assert box and box[2]>box[0] and box[3]>box[1]
    crop=raw.crop(box)
    native=(round(rect[2]*2),round(rect[3]*2))
    scale=min((native[0]-8)/crop.width,(native[1]-8)/crop.height)
    assert scale<=1, 'Do not upscale '+dest.name
    size=(max(1,round(crop.width*scale)),max(1,round(crop.height*scale)))
    crop=crop.resize(size,Image.Resampling.LANCZOS)
    # Preserve exported alpha; remove hidden RGB to prevent edge-filter colour bleed.
    pixels=crop.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if pixels[x,y][3]==0:pixels[x,y]=(0,0,0,0)
    im=Image.new('RGBA',native)
    offset=((native[0]-size[0])//2,(native[1]-size[1])//2)
    im.paste(crop,offset)
    dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)
    assert not any(im.getchannel('A').crop(b).getbbox() for b in [(0,0,native[0],3),(0,native[1]-3,native[0],native[1]),(0,0,3,native[1]),(native[0]-3,0,native[0],native[1])])
    return {'source_bounds':list(box),'native_canvas':list(native),'content_offset':list(offset),'content_size':list(size),'source_scale':scale,'rect':rect}

def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
    records=[];checks=0
    for e in manifest['assets']:
        if 'source' not in e:continue
        p=ROOT/e['source'];old=e.get('sha256');assert not old or old==sha(p)
        e['sha256']=sha(p);raw=Image.open(p)
        references=[{'path':Path(ref).relative_to(ROOT).as_posix(),'sha256':sha(Path(ref))} for ref in e['refs']]
        assert not e.get('reference_records') or e['reference_records']==references
        e['reference_records']=references
        if e['id']=='terrain-clean':
            dest=OUT/'terrain.png';raw.convert('RGB').resize(CANVAS,Image.Resampling.LANCZOS).save(dest)
            e['registration']={'source_canvas':list(raw.size),'export_canvas':list(CANVAS),'full_frame':True}
        else:
            id=e['id'];folder='companions' if id in PEOPLE else 'fx' if id=='flame' else 'sites'
            dest=OUT/folder/(id+'.png');e['registration']=cutout(raw,BOUNDS[id],dest)
            e['hero_visual_id']=PEOPLE.get(id,'')
        e['export']='res://'+dest.relative_to(ROOT).as_posix();e['export_sha256']=sha(dest)
        checks+=3;records.append(e)
    layers=[]
    for id,rect in BOUNDS.items():
        e=next(e for e in records if e['id']==id)
        z=10 if id=='shelter' else 16 if id=='firepit' else 30 if id=='flame' else 20
        if id in PEOPLE:z=23 if id!='fixer-planning' else 14
        layers.append({'id':id,'texture':e['export'],'rect':rect,'z':z,'hero_visual_id':PEOPLE.get(id,''),'states': ['provisioned','connected'] if id not in ['supplies','lantern'] else ['connected']})
        if id not in PEOPLE and id!='flame':
            scene=f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Texture2D" path="{e['export']}" id="art"]
[node name="{id.title()}" type="Node2D"]
[node name="Art" type="Sprite2D" parent="."]
position = Vector2({rect[0]}, {rect[1]})
scale = Vector2(0.5, 0.5)
centered = false
texture_filter = 2
texture = ExtResource("art")
'''
            write(OUT/'sites'/(id+'.tscn'),scene)
    data={'canvas':list(CANVAS),'selected_reference':'res://art/concepts/descent-completion-v1/overlook-concept.png','terrain':'res://art/camp/overlook-v1/terrain.png','layers':layers,'targets':TARGETS,'states':['discovered','provisioned','connected'],'max_present_companions':3,'still_phase':0,'runtime_bindings_changed':False,'foreground_polygon':[[0,690],[150,600],[291,615],[420,704],[610,628],[689,548],[745,512],[797,502],[868,475],[969,523],[1050,602],[1119,683],[1242,789],[1370,900],[0,900]]}
    js(OUT/'layout.json',data);js(SRC/'generation.json',manifest)
    budget=[]
    for p in OUT.rglob('*.png'):
        im=Image.open(p);budget.append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'size':list(im.size),'rgba_bytes':im.width*im.height*4})
    approved_unchanged=sha(ROOT/'art/concepts/descent-completion-v1/overlook-concept.png')==json.loads((ROOT/'art/concepts/descent-completion-v1/overlook-approval.json').read_text())['export_sha256']
    assert approved_unchanged, 'Selected composition must stay unchanged'
    js(REVIEW/'export-validation.json',{'checks':checks,'failures':[],'imagegen_outputs':len(records),'not_delivered':['corin-tending (service rejection; equipment-checking substitute supplied)'],'textures':budget,'rgba_bytes':sum(e['rgba_bytes'] for e in budget),'approved_reference_unchanged':approved_unchanged})
    js(REVIEW/'catalog.json',{'assets':records,'source_manifest':'../../source/overlook-v1/generation.json'})
    print(f'OVERLOOK_EXPORT: {checks} checks, {len(records)} outputs, {sum(e["rgba_bytes"] for e in budget)/1048576:.2f} MiB RGBA')

if __name__=='__main__':main()
