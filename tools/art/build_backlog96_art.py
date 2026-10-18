"""Register generated visual assets; originals and all exact prompts stay in source/."""
from pathlib import Path
from PIL import Image,ImageChops,ImageDraw
import hashlib,importlib.util,json,re,sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/backlog96-v1';REVIEW=ROOT/'art/concepts/backlog96-v1'
spec=importlib.util.spec_from_file_location('export_helpers',ROOT/'tools/art/build_treasure_art.py')
kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
REPORT={'issue':96,'assets':{},'registration':{},'failures':[]}

def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def load(name):
    if name=='hollow-floor':
        if (SOURCE/'hollow-floor-topdown.png').exists():name='hollow-floor-topdown'
        elif (SOURCE/'hollow-floor-clean.png').exists():name='hollow-floor-clean'
    return Image.open(SOURCE/(name+'.png')).convert('RGBA')
def save(im,p,colours=32):
    p.parent.mkdir(parents=True,exist_ok=True)
    im=kit.quantize(im,kit.palette([im],colours));im.save(p)
    REPORT['assets'][p.relative_to(ROOT).as_posix()]=kit.verify(im,im.size,colours)
    return im
def cells(name):
    im=load(name)
    return [im.crop((round(x*im.width/2),round(y*im.height/2),round((x+1)*im.width/2),round((y+1)*im.height/2))) for y in range(2) for x in range(2)]
def fitted(im,size,maxsize,contact=None):
    crop=im.crop(kit.mask(im).getbbox());crop.thumbnail(maxsize,Image.Resampling.NEAREST)
    out=Image.new('RGBA',size)
    at=((size[0]-crop.width)//2,(size[1]-crop.height)//2 if contact is None else contact+1-crop.height)
    out.paste(crop,at);return out
def write(p,text):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8',newline='\n')

def wire_events(catalog):
    for name,id in catalog['events'].items():
        p=ROOT/'data/events'/(name+'.tres');s=p.read_text(encoding='utf-8');scene=catalog['props'][id]['scene']
        pattern=r'(\[ext_resource type="PackedScene" path=")[^"]+(" id="prop"\])'
        if re.search(pattern,s):s=re.sub(pattern,lambda m:m[1]+scene+m[2],s)
        else:
            index=s.index('\n',s.index('[ext_resource'))+1
            s=s[:index]+'[ext_resource type="PackedScene" path="'+scene+'" id="prop"]\n'+s[index:]
            index=s.index('[resource]');head,body=s[:index],s[index:]
            body=re.sub(r'(^script = ExtResource\([^\n]+\)\n)',r'\1prop = ExtResource("prop")\n',body,count=1,flags=re.M)
            s=head+body
        write(p,s)

def prop(name,height=.7,flat=False,container=False):
    folder=ROOT/'art/props/cave-events-v1';p=folder/(name+'.png')
    if container:
        raw=[load(name).resize((128,128),Image.Resampling.NEAREST),load(name+'-empty').resize((128,128),Image.Resampling.NEAREST)]
        boxes=[kit.mask(a).getbbox() for a in raw]
        union=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
        factor=min(112/(union[2]-union[0]),112/(union[3]-union[1]));side=round(128*factor)
        at=(64-round((union[0]+union[2])*factor/2),121-round(union[3]*factor))
        states=[]
        for a in raw:
            target=Image.new('RGBA',(128,128));target.paste(a.resize((side,side),Image.Resampling.NEAREST),at);states.append(target)
        pal=kit.palette(states,32);states=[kit.quantize(a,pal) for a in states]
        im=states[0];im.save(p)
        empty=folder/(name+'-empty.png');states[1].save(empty)
        for dest,a in [(p,im),(empty,states[1])]:REPORT['assets'][dest.relative_to(ROOT).as_posix()]=kit.verify(a,(128,128),32)
        REPORT['registration'][name]={'shared_full_canvas_scale':factor,'shared_offset':at,'state_union':union}
    else:im=save(fitted(load(name),(128,128),(112,112),None if flat else 120),p)
    bounds=kit.mask(im).getbbox();pixel=height/(bounds[3]-bounds[1])
    if flat:
        position='position = Vector3(0, 0.015, 0)\nrotation = Vector3(-1.5707964, 0, 0)\nbillboard = 0\n'
        pixel=1.4/112
    else:position='position = Vector3(0, '+str(56*pixel)+', 0)\nbillboard = 2\n'
    ext='[ext_resource type="Texture2D" path="'+uri(p)+'" id="texture"]\n'
    attrs=''
    if container:
        empty=folder/(name+'-empty.png')
        ext+='[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="script"]\n[ext_resource type="Texture2D" path="'+uri(empty)+'" id="empty"]\n'
        attrs='script = ExtResource("script")\nclosed_texture = ExtResource("texture")\nempty_texture = ExtResource("empty")\n'
    scene='[gd_scene load_steps='+str(4 if container else 2)+' format=3]\n\n'+ext+'\n[node name="'+name+'" type="Node3D"]\n'+attrs+'\n[node name="Sprite" type="Sprite3D" parent="."]\n'+position+'pixel_size = '+str(pixel)+'\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ntexture = ExtResource("texture")\n'
    write(folder/(name+'.tscn'),scene)
    return {'scene':uri(folder/(name+'.tscn')),'texture':uri(p),'flat':flat,'pivot':[64,64] if flat else [64,120],('world_span' if flat else 'world_height'):(1.4 if flat else height)}

def enemy(name,height):
    folder=ROOT/'art/enemies/tutorial-v1'/name;folder.mkdir(parents=True,exist_ok=True)
    raw=[im.resize((128,128),Image.Resampling.NEAREST) for im in cells(name)[:3]]
    bounds=[kit.mask(im).getbbox() for im in raw]
    union=(min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds))
    scale=min(112/(union[2]-union[0]),112/(union[3]-union[1]))
    side=round(128*scale);dx=64-round((union[0]+union[2])*scale/2)
    registered=[];transforms=[]
    for im,b in zip(raw,bounds):
        moved=Image.new('RGBA',(128,128));dy=121-round(b[3]*scale)
        moved.paste(im.resize((side,side),Image.Resampling.NEAREST),(dx,dy));registered.append(moved);transforms.append([dx,dy])
    pal=kit.palette(registered,32)
    for pose,im in zip(['idle','attack','hurt'],registered):
        im=kit.quantize(im,pal);im.save(folder/(pose+'.png'))
        REPORT['assets'][(folder/(pose+'.png')).relative_to(ROOT).as_posix()]=kit.verify(im,(128,128),32)
        assert im.getchannel('A').getbbox()[3]==121,(name,pose)
    REPORT['registration'][name]={'common_canvas_scale':scale,'common_dx':dx,'pose_translations':transforms,'contact_y':120}
    ext='\n'.join('[ext_resource type="Texture2D" path="'+uri(folder/(pose+'.png'))+'" id="'+pose+'"]' for pose in ['idle','attack','hurt'])
    anim=',\n'.join('{"frames":[{"duration":1.0,"texture":ExtResource("'+pose+'")}],"loop":false,"name":&"'+pose+'","speed":6.0}' for pose in ['idle','attack','hurt'])
    write(folder/'frames.tres','[gd_resource type="SpriteFrames" load_steps=4 format=3]\n'+ext+'\n[resource]\nanimations = ['+anim+']\n')
    idle=Image.open(folder/'idle.png');b=idle.getchannel('A').getbbox();pixel=height/(b[3]-b[1])
    write(folder/'scene.tscn','[gd_scene load_steps=2 format=3]\n[ext_resource type="SpriteFrames" path="'+uri(folder/'frames.tres')+'" id="frames"]\n[node name="'+name+'" type="Node3D"]\n[node name="Sprite" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0, '+str(pixel*56)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\nsprite_frames = ExtResource("frames")\nanimation = &"idle"\n')
    return uri(folder/'scene.tscn')

def camp(name,old,patchbox):
    folder=ROOT/'art/camp/cave-camp-variants-v1'
    reference=Image.open(ROOT/'art/camp/cave-camp-v1'/(old+'.png')).convert('RGBA')
    target=reference.getchannel('A').getbbox()
    source=load(name);source=source.crop(kit.mask(source).getbbox()).resize((target[2]-target[0],target[3]-target[1]),Image.Resampling.NEAREST)
    aligned=Image.new('RGBA',reference.size);aligned.paste(source,target[:2])
    # Only the notice or cot region changes; original tent/rocks stay pixel-identical.
    overlay=Image.new('RGBA',reference.size);overlay.paste(aligned.crop(patchbox),patchbox[:2])
    combined=reference.copy();combined.paste(overlay.crop(patchbox),patchbox[:2])
    # Quantize the edited rectangle only, preserving the old pixels elsewhere.
    patch=combined.crop(patchbox);patch=kit.quantize(patch,kit.palette([patch],32));combined.paste(patch,patchbox[:2])
    outside=combined.copy();outside.paste(reference.crop(patchbox),patchbox[:2])
    assert outside.tobytes()==reference.tobytes()
    overlay=Image.new('RGBA',reference.size);overlay.paste(patch,patchbox[:2])
    folder.mkdir(parents=True,exist_ok=True);combined.save(folder/(name+'.png'));overlay.save(folder/(name+'-patch.png'))
    REPORT['assets'][(folder/(name+'.png')).relative_to(ROOT).as_posix()]={'canvas':[256,192],'edited_box':patchbox,'outside_patch_unchanged':True}
    REPORT['registration'][name]={'source_bounds':kit.mask(load(name)).getbbox(),'target_bounds':target,'patch_box':patchbox}
    write(folder/(name+'.tscn'),'[gd_scene load_steps=2 format=3]\n[ext_resource type="Texture2D" path="'+uri(folder/(name+'.png'))+'" id="texture"]\n[node name="'+name+'" type="Node2D"]\ntexture_filter = 1\n[node name="Base" type="Sprite2D" parent="."]\nposition = Vector2(-128,-184)\ncentered = false\ntexture = ExtResource("texture")\n')

def main():
    save(fitted(load('held-lantern'),(128,256),(112,240),247),ROOT/'art/props/lantern-v1/body.png')
    for name,im in zip(['leather-jerkin','boiled-leather-vest','studded-leather'],cells('leather-armour')[:3]):save(kit.fit_icon(im),ROOT/'art/items/armour-v1'/(name+'.png'))
    catalog={'issue':96,'enemies':{n:enemy(n,h) for n,h in [('starved-rat',.42),('small-spider',.35)]},'props':{}}
    for n,h,flat,container in [('goblin-stash',.55,False,True),('old-workings',.9,False,False),('dry-alcove',.65,False,False),('tripwire',.18,False,False),('hollow-floor',.1,True,False),('idol-niche',.85,False,False)]:
        if (SOURCE/(n+'.png')).exists() and (not container or (SOURCE/(n+'-empty.png')).exists()):catalog['props'][n]=prop(n,h,flat,container)
    catalog['props']['abandoned-pack']={'scene':'res://art/props/cave-events-v1/abandoned-pack.tscn','reuses':'res://art/props/cave-room-props-v1/abandoned-pack.tscn','state':'closed/empty adapter to set_searched'}
    catalog['props']['still-pool']={'scene':'res://art/props/cave-room-props-v1/still-pool.tscn','flat':True}
    catalog['props']['cold-camp']={'scene':'res://art/props/cave-room-props-v1/cold-camp.tscn','lit':False}
    catalog['events']={'chest_abandoned_pack':'abandoned-pack','chest_goblin_stash':'goblin-stash','chest_old_workings':'old-workings','object_pale_idol':'idol-niche','object_still_pool':'still-pool','rest_dry_alcove':'dry-alcove','rest_old_camp':'cold-camp','trap_tripwire':'tripwire','trap_hollow_floor':'hollow-floor'}
    catalog['trap_visibility']='Game-owned: hidden unless the current party has the keen_eyes trait (#95).'
    if '--wire' in sys.argv:wire_events(catalog)
    for name,old,box in [('contract-notice','cave',(59,85,93,130)),('nurse-occupied','treatment',(86,106,138,150))]:camp(name,old,box)
    if (SOURCE/'daylight-exit.png').exists():
        p=ROOT/'art/features/daylight-exit-v1/exit.png';im=save(fitted(load('daylight-exit'),(128,256),(112,240),248),p)
        write(p.parent/'scene.tscn','[gd_scene load_steps=2 format=3]\n[ext_resource type="Texture2D" path="'+uri(p)+'" id="texture"]\n[node name="DaylightExit" type="Node3D"]\n[node name="Sprite" type="Sprite3D" parent="."]\nposition = Vector3(0, 1.445, 0)\npixel_size = 0.012\nbillboard = 2\nshaded = false\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ntexture = ExtResource("texture")\n')
    if (SOURCE/'coin-faces.png').exists():
        folder=ROOT/'art/ui/coin-v1';faces=cells('coin-faces')[:2]
        faces=[fitted(im,(128,128),(116,116)) for im in faces]
        pal=kit.palette(faces,32)
        # Identical dimensions and centred origin support the existing squash spin.
        folder.mkdir(parents=True,exist_ok=True)
        for name,im in zip(['heads','tails'],faces):
            im=kit.quantize(im,pal);im.save(folder/(name+'.png'));REPORT['assets'][(folder/(name+'.png')).relative_to(ROOT).as_posix()]=kit.verify(im,(128,128),32)
        edge=cells('coin-faces')[2];save(fitted(edge,(128,128),(14,116)),folder/'edge.png')
    if (SOURCE/'parchment.png').exists():
        p=ROOT/'art/ui/map-v1/parchment.png';save(load('parchment').resize((512,512),Image.Resampling.NEAREST),p,64)
        centre=Image.open(p).crop((128,128,384,384));centre.save(p.parent/'quiet-centre.png')
    write(ROOT/'art/props/cave-events-v1/catalog.json',json.dumps(catalog,indent=2)+'\n')
    armour={'issue':93,'canvas':[64,64],'rules_pending':True,'icons':{n:'res://art/items/armour-v1/'+n+'.png' for n in ['leather-jerkin','boiled-leather-vest','studded-leather']}}
    armour['icons'].update({n:'res://art/items/inventory-64-v1/'+n+'.png' for n in ['wooden-shield','padded-coat']})
    write(ROOT/'art/items/armour-v1/catalog.json',json.dumps(armour,indent=2)+'\n')
    REPORT['source_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.png')}
    REPORT['sha256']={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in REPORT['assets']}
    write(REVIEW/'asset-validation.json',json.dumps(REPORT,indent=2)+'\n')
    print('Backlog art exported: '+str(len(REPORT['assets']))+' registered textures.')

if __name__=='__main__':main()
