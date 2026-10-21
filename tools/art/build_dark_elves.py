"""#131: export the first dark-elf pair and one registered combat pose family.

Generated masters stay immutable. Facial components are fitted at native192,
following #124's complete feature replacement (never borrowed facial frames).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import hashlib, json, sys
import numpy as np
sys.dont_write_bytecode=True
import build_portrait_components as C
import refine_portrait_drawings as D
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/dark-elves-v1'
OUT=ROOT/'art/portraits/dark-elves-v1'
REVIEW=ROOT/'art/concepts/dark-elves-v1'
ENEMY=ROOT/'art/enemies/dark-elves-v1/spearman'

def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(text,encoding='utf-8',newline='\n')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def blank():return Image.new('RGBA',(192,192))
def save(image,path):
    path.parent.mkdir(parents=True,exist_ok=True);image.save(path)
def base(ident):
    raw=Image.open(SOURCE/(ident+'-master.png')).convert('RGBA')
    assert raw.width==raw.height and raw.width>=192
    assert raw.getchannel('A').getextrema()[0]==0
    im=raw.resize((192,192),Image.Resampling.BOX)
    alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
    im=im.convert('RGB').quantize(96,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
    data=np.array(im);data[data[:,:,3]==0]=0
    return Image.fromarray(data)

# Full native feature footprints, including resting lashes and lip corners.
# These are individually fitted to these two new 192px faces, not a shared rig.
FACES={
 'dark-elf-man':{
  'eyes':[
   ([(72,60),(77,58),(87,58),(93,60),(94,63),(90,67),(78,67),(72,64)],[(74,61),(79,63),(84,64),(90,62),(92,61)]),
   ([(99,60),(106,58),(116,58),(121,60),(122,63),(118,67),(105,67),(99,64)],[(101,61),(106,63),(112,64),(118,62),(120,61)])],
  'mouth':[(83,90),(89,87),(96,86),(103,88),(110,91),(109,95),(101,97),(90,96),(83,94)],
  'lip':[(85,91),(90,90),(96,90),(102,91),(108,92)]},
 'dark-elf-woman':{
  'eyes':[
   ([(71,58),(76,58),(87,58),(93,61),(93,65),(87,68),(76,67),(71,63)],[(73,61),(78,64),(84,65),(89,63),(91,62)]),
   ([(99,61),(105,58),(116,58),(122,58),(121,64),(117,67),(105,68),(99,65)],[(101,62),(106,64),(112,65),(118,63),(120,61)])],
  'mouth':[(84,88),(89,85),(96,84),(102,86),(108,88),(107,93),(100,96),(90,95),(84,92)],
  'lip':[(86,89),(91,88),(96,88),(101,89),(106,89)]}
}

def rig(ident,original):
    folder=OUT/ident;source=SOURCE/ident
    spec=FACES[ident];C.FACES[ident]=spec
    palette=sorted({p for p in original.get_flattened_data() if p[3]})
    eye_mask=C.merge(*[C.polygon(points) for points,_ in spec['eyes']])
    mouth_mask=C.polygon(spec['mouth'])
    clean=C.clean_feature(original,eye_mask,'eye',palette)
    clean=C.clean_feature(clean,mouth_mask,'mouth',palette)
    save(clean,folder/'character-clean.png')
    save(C.full_patch(original,eye_mask),folder/'eyes-neutral.png')
    save(C.full_patch(original,mouth_mask),folder/'mouth-neutral.png')
    D.EYES[ident]=[]
    for points,path in spec['eyes']:
        left,right=path[0][0],path[-1][0];cx=(left+right)//2
        D.EYES[ident].append({'half':[(left,61),(cx-4,61),(cx+2,62),(right,61)],
           'lower':[(left,62),(cx-4,64),(cx+2,65),(right,62)],'closed':path})
    for mode in ['half','closed']:
        drawing,visible,lashes=D.eyes(ident,original,clean,eye_mask,mode,palette)
        save(C.full_patch(drawing,eye_mask),folder/('eyes-'+mode+'.png'))
        save(visible,source/('eyes-'+mode+'-iris.png'))
        save(lashes,source/('eyes-'+mode+'-lash.png'))
    for mode in ['small','open','round']:
        drawing,cavity,tissue=D.mouth(ident,original,mouth_mask,mode,palette)
        if mode=='round':
            # Narrow circular speech gesture, with native lip tissue and no
            # resting corners beneath it. Full replacement, not a dark dot.
            drawing=clean.copy();cx=96;cy=91 if ident=='dark-elf-man' else 89
            for y in range(cy-3,cy+5):
                for x in range(cx-5,cx+6):
                    radius=((x-cx)/5)**2+((y-cy)/3.7)**2
                    if radius>1 or not mouth_mask.getpixel((x,y)):continue
                    sx=round(cx+(x-cx)*2)
                    sy=cy-2 if y<cy else cy+2
                    drawing.putpixel((x,y),original.getpixel((sx,sy)))
                    if ((x-cx)/2.8)**2+((y-cy)/2.3)**2<1:
                        drawing.putpixel((x,y),C.nearest(palette,(43,30,44)))
                        cavity.putpixel((x,y),255)
        save(C.full_patch(drawing,mouth_mask),folder/('mouth-'+mode+'.png'))
        save(cavity,source/('mouth-'+mode+'-opening.png'))
    for kind in ['shadow','highlight']:
        layer=blank()
        for y in range(192):
            for x in range(192):
                if not original.getpixel((x,y))[3]:continue
                # Authored broad upper-left light contribution; never illuminates UI.
                if kind=='highlight':
                    alpha=round(180*max(0,1-x/192)*max(.15,1-y/220))
                    layer.putpixel((x,y),(255,255,255,alpha))
                else:
                    alpha=round(190*min(1,.7*x/192+.3*y/192))
                    layer.putpixel((x,y),(0,0,0,alpha))
        save(layer,folder/(kind+'.png'))
    save(eye_mask,source/'eye-mask.png');save(mouth_mask,source/'mouth-mask.png')
    write(source/'contours.json',json.dumps({'features':spec,'drawings':D.EYES[ident]},indent=2)+'\n')
    # Exact reconstruction is an invariant, not a visual style judgement.
    reconstruction=clean.copy()
    reconstruction.alpha_composite(C.full_patch(original,eye_mask))
    reconstruction.alpha_composite(C.full_patch(original,mouth_mask))
    assert reconstruction.tobytes()==original.tobytes(),ident+' neutral reconstruction'
    names=['character-clean','eyes-neutral','mouth-neutral','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round','shadow','highlight']
    resource='[gd_resource type="Resource" script_class="PortraitSet" format=3]\n\n[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]\n'
    for name in names:resource+=f'[ext_resource type="Texture2D" path="res://art/portraits/dark-elves-v1/{ident}/{name}.png" id="{name}"]\n'
    resource+='\n[resource]\nscript = ExtResource("script")\nrig_kind = "Unique"\nrig_family = &"unique-'+ident+'-v1"\nface_id = &"'+ident+'"\nhead = ExtResource("character-clean")\neyes = ExtResource("eyes-neutral")\nmouth = ExtResource("mouth-neutral")\nblink_frames = Array[Texture2D]([ExtResource("eyes-half"),ExtResource("eyes-closed")])\ntalk_frames = Array[Texture2D]([ExtResource("mouth-small"),ExtResource("mouth-open"),ExtResource("mouth-round")])\nlight_shadow = ExtResource("shadow")\nlight_highlight = ExtResource("highlight")\n'
    write(ROOT/'data/portraits/dark-elves-v1'/(ident+'.tres'),resource)
    return {'id':ident,'rig_kind':'Unique','rig_family':'unique-'+ident+'-v1','canvas':[192,192],'resource':'res://data/portraits/dark-elves-v1/'+ident+'.tres','fallback':'res://art/portraits/dark-elves-v1/'+ident+'/resting.png','light':'authored upper-left shadow/highlight masks; neutral base; no world fuel hookup','features':spec}

def enemy():
    ENEMY.mkdir(parents=True,exist_ok=True)
    poses=['idle','attack','hurt'];registered=[];entries=[]
    for pose in poses:
        raw=Image.open(SOURCE/('dark-elf-'+pose+'-master.png')).convert('RGBA')
        assert raw.width==raw.height
        im=raw.resize((112,112),Image.Resampling.BOX)
        a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0
        im=Image.fromarray(a);box=im.getbbox()
        dy=121-box[3];out=Image.new('RGBA',(128,128));out.paste(im,(8,dy))
        assert np.count_nonzero(np.array(out)[:,:,3])==np.count_nonzero(a[:,:,3]),'Clipped pose'
        registered.append(out);entries.append({'pose':pose,'source':str((SOURCE/('dark-elf-'+pose+'-master.png')).relative_to(ROOT)).replace('\\','/'),'reduced_canvas':[112,112],'translation':[8,dy]})
    samples=np.concatenate([np.array(im)[:,:,:3][np.array(im)[:,:,3]>0] for im in registered])
    palette=Image.fromarray(samples.reshape((1,-1,3))).quantize(32,dither=Image.Dither.NONE)
    union=set();board=Image.new('RGB',(768,300),'#202623');draw=ImageDraw.Draw(board)
    for i,(pose,im,entry) in enumerate(zip(poses,registered,entries)):
        alpha=im.getchannel('A');im=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
        data=np.array(im);data[data[:,:,3]==0]=0;im=Image.fromarray(data)
        save(im,ENEMY/(pose+'.png'));union.update(p[:3] for p in im.get_flattened_data() if p[3])
        assert im.getbbox()[3]==121
        entry.update({'bounds':list(im.getbbox()),'sha256':sha(ENEMY/(pose+'.png'))})
        big=im.resize((256,256),Image.Resampling.NEAREST);board.paste(big,(i*256,25),big);draw.text((i*256+8,8),pose,fill='#e3d4ad')
    assert len(union)<=32
    save(board,REVIEW/'combat-poses.png')
    frames='[gd_resource type="SpriteFrames" load_steps=4 format=3]\n'
    for i,pose in enumerate(poses):frames+=f'\n[ext_resource type="Texture2D" path="res://art/enemies/dark-elves-v1/spearman/{pose}.png" id="{i}"]\n'
    frames+='\n[resource]\nanimations = ['+','.join('{"frames":[{"duration":1.0,"texture":ExtResource("%d")}],"loop":false,"name":&"%s","speed":6.0}'%(i,pose) for i,pose in enumerate(poses))+']\n'
    write(ENEMY/'frames.tres',frames)
    # Physical size is an art-fixture proposal, not a new EnemyType/stat block.
    pixel_size=1.95/98
    write(ENEMY/'scene.tscn','[gd_scene load_steps=2 format=3]\n\n[ext_resource type="SpriteFrames" path="res://art/enemies/dark-elves-v1/spearman/frames.tres" id="1"]\n\n[node name="DarkElfSpearman" type="Node3D"]\n\n[node name="Sprite" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0, %.9f, 0)\npixel_size = %.9f\nbillboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\nsprite_frames = ExtResource("1")\nanimation = &"idle"\n'%(56*pixel_size,pixel_size))
    write(ENEMY/'registration.json',json.dumps({'canvas':[128,128],'pivot':[64,120],'common_reduced_canvas':[112,112],'palette':sorted(union),'pixel_size':pixel_size,'poses':entries},indent=2)+'\n')

def main():
    write(REVIEW/'.gdignore','')
    helpers=SOURCE/'authoring-helpers.json'
    dependencies={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [ROOT/'tools/art/build_portrait_components.py',ROOT/'tools/art/refine_portrait_drawings.py']}
    if helpers.exists():assert json.loads(helpers.read_text())==dependencies,'Portrait authoring helper changed; review before rebuilding'
    else:write(helpers,json.dumps(dependencies,indent=2)+'\n')
    manifest=json.loads((SOURCE/'generation.json').read_text())
    for e in manifest['assets']:
        h=sha(ROOT/e['source']);assert e.get('sha256',h)==h,e['id'];e['sha256']=h
    write(SOURCE/'generation.json',json.dumps(manifest,indent=2)+'\n')
    entries=[]
    for ident in ['dark-elf-man','dark-elf-woman']:
        original=base(ident);save(original,OUT/ident/'resting.png')
        entries.append(rig(ident,original))
    write(OUT/'catalog.json',json.dumps({'issue':131,'portraits':entries,'enemy':'res://art/enemies/dark-elves-v1/spearman/scene.tscn','assignment':'Art only; no NPC identity, EnemyType, encounter, stats, dialogue or recruitment changes.'},indent=2)+'\n')
    board=Image.new('RGB',(6*192,2*216),'#202623');bd=ImageDraw.Draw(board)
    feature=Image.new('RGB',(6*320,2*260),'#202623');fd=ImageDraw.Draw(feature)
    for row,entry in enumerate(entries):
        folder=OUT/entry['id']
        for col,state in enumerate(['rest','half','closed','small','open','round']):
            image=Image.open(folder/'character-clean.png').convert('RGBA')
            eye='eyes-'+state if state in ['half','closed'] else 'eyes-neutral'
            mouth='mouth-'+state if state in ['small','open','round'] else 'mouth-neutral'
            image.alpha_composite(Image.open(folder/(eye+'.png')).convert('RGBA'))
            image.alpha_composite(Image.open(folder/(mouth+'.png')).convert('RGBA'))
            board.paste(image,(col*192,row*216+24),image);bd.text((col*192+4,row*216+4),entry['id']+' '+state,fill='#e3d4ad')
            crop=image.crop((64,48,128,100)).resize((320,260),Image.Resampling.NEAREST)
            feature.paste(crop,(col*320,row*260))
    save(board,REVIEW/'held-frames.png');save(feature,REVIEW/'features-held.png')
    enemy()
    print('DARK_ELF_EXPORT: two neutral192 portraits; three128 poses, shared32 colours, pivot64,120.')

if __name__=='__main__':main()
