"""Register campaign raster masters; generation originals remain untouched."""
from pathlib import Path
from PIL import Image, ImageOps
import hashlib, json, re, sys
from build_treasure_art import mask, palette, quantize, verify, fit_icon

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/campaign-v1'
REVIEW=ROOT/'art/concepts/campaign-v1'
REPORT={'issues':[99,103,105,96,50,89],'assets':{},'registration':{},'failures':[]}

def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def load(name):return Image.open(SOURCE/(name+'.png')).convert('RGBA')
def cells(name,cols=2,rows=2):
    im=load(name)
    return [im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows))) for y in range(rows) for x in range(cols)]
def save(im,p,limit=32,pal=None):
    p.parent.mkdir(parents=True,exist_ok=True)
    im=quantize(im,pal if pal is not None else palette([im],limit));im.save(p)
    REPORT['assets'][p.relative_to(ROOT).as_posix()]=verify(im,im.size,limit)
    return im
def registered(images):
    raw=[im.resize((128,128),Image.Resampling.NEAREST) for im in images]
    boxes=[mask(im).getbbox() for im in raw]
    union=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
    scale=min(112/(union[2]-union[0]),112/(union[3]-union[1]))
    side=round(128*scale);dx=64-round((union[0]+union[2])*scale/2)
    result=[];offsets=[]
    for im,b in zip(raw,boxes):
        dy=121-round(b[3]*scale);target=Image.new('RGBA',(128,128))
        target.paste(im.resize((side,side),Image.Resampling.NEAREST),(dx,dy));result.append(target);offsets.append([dx,dy])
    return result,{'common_scale':scale,'common_dx':dx,'pose_offsets':offsets,'contact_y':120}

def clean_enemy_alpha(im):
    # Remove detached sub-12px export specks, never paint anatomy or equipment.
    alpha=mask(im);seen=set();removed=0
    for y in range(128):
        for x in range(128):
            if (x,y) in seen or not alpha.getpixel((x,y)):continue
            component=[(x,y)];seen.add((x,y));index=0
            while index<len(component):
                px,py=component[index];index+=1
                for dy in [-1,0,1]:
                    for dx in [-1,0,1]:
                        n=(px+dx,py+dy)
                        if 0<=n[0]<128 and 0<=n[1]<128 and n not in seen and alpha.getpixel(n):seen.add(n);component.append(n)
            if len(component)<12:
                for p in component:alpha.putpixel(p,0)
                removed+=len(component)
    im=im.copy();im.putalpha(alpha)
    return im,removed

def frames(folder,names,attack=None,file='frames.tres'):
    ext='\n'.join('[ext_resource type="Texture2D" path="'+uri(folder/(n+'.png'))+'" id="'+n+'"]' for n in names)
    animations=[]
    for name in names:
        sequence=attack if name=='attack' and attack else [name]
        animations.append('{"frames":['+','.join('{"duration":1.0,"texture":ExtResource("'+n+'")} ' for n in sequence)+'],"loop":'+('true' if name in ['idle','brace'] else 'false')+',"name":&"'+name+'","speed":8.0}')
    write(folder/file,'[gd_resource type="SpriteFrames" load_steps='+str(len(names)+1)+' format=3]\n'+ext+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\n')

def enemy(name,height,poses,indices,source=None,enraged=False):
    folder=ROOT/'art/enemies/campaign-v1'/name
    raw=[cells(source or name+'-poses')[i] for i in indices]
    if enraged:raw+=[cells('queen-enraged')[i] for i in [0,1,2]]
    ims,registration=registered(raw);REPORT['registration'][name]=registration
    pal=palette(ims,32)
    names=poses+(['enraged-idle','enraged-attack','enraged-hurt'] if enraged else [])
    for n,im in zip(names,ims):
        im,removed=clean_enemy_alpha(im)
        if removed:REPORT['registration'][name].setdefault('isolated_export_pixels_removed',{})[n]=removed
        save(im,folder/(n+'.png'),pal=pal)
    frames(folder,poses,['draw','release'] if name=='archer' else None)
    if enraged:
        names2=['idle','attack','hurt']
        ext='\n'.join('[ext_resource type="Texture2D" path="'+uri(folder/('enraged-'+n+'.png'))+'" id="'+n+'"]' for n in names2)
        anim=',\n'.join('{"frames":[{"duration":1.0,"texture":ExtResource("'+n+'")}],"loop":'+('true' if n=='idle' else 'false')+',"name":&"'+n+'","speed":8.0}' for n in names2)
        write(folder/'enraged-frames.tres','[gd_resource type="SpriteFrames" load_steps=4 format=3]\n'+ext+'\n[resource]\nanimations = ['+anim+']\n')
    bounds=mask(ims[0]).getbbox();pixel=height/(bounds[3]-bounds[1])
    extra='[ext_resource type="Script" path="res://art/enemies/campaign-v1/actor.gd" id="script"]\n'
    if enraged:extra+='[ext_resource type="SpriteFrames" path="'+uri(folder/'enraged-frames.tres')+'" id="rage"]\n'
    scene='[gd_scene load_steps='+str(4 if enraged else 3)+' format=3]\n[ext_resource type="SpriteFrames" path="'+uri(folder/'frames.tres')+'" id="frames"]\n'+extra
    scene+='\n[node name="'+name+'" type="Node3D"]\nscript = ExtResource("script")\nmetadata/visual_height = '+str(height)+'\n'
    if enraged:scene+='enraged_frames = ExtResource("rage")\n'
    scene+='\n[node name="Sprite" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0, '+str(56*pixel)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\nsprite_frames = ExtResource("frames")\nanimation = &"idle"\n'
    write(folder/'scene.tscn',scene)
    return uri(folder/'scene.tscn')

def prop(name,image,height,feature=False):
    folder=ROOT/('art/features/fortress-v1' if feature else 'art/props/fortress-v1')
    im=save(image,folder/(name+'.png'));bounds=mask(im).getbbox();pixel=height/(bounds[3]-bounds[1])
    scene='[gd_scene load_steps=2 format=3]\n[ext_resource type="Texture2D" path="'+uri(folder/(name+'.png'))+'" id="texture"]\n\n[node name="'+name+'" type="Node3D"]\n\n[node name="Sprite" type="Sprite3D" parent="."]\nposition = Vector3(0, '+str(56*pixel)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = '+('0' if feature else '2')+'\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ntexture = ExtResource("texture")\n'
    write(folder/(name+'.tscn'),scene)
    return uri(folder/(name+'.tscn'))

def wire_icon(resource,path):
    p=ROOT/resource;s=p.read_text(encoding='utf-8')
    if re.search(r'^icon = ',s,flags=re.M):
        raise ValueError('Icon already assigned; inspect before replacing '+resource)
    index=s.index('[resource]')
    s=s[:index]+'[ext_resource type="Texture2D" path="'+path+'" id="campaign_art"]\n\n'+s[index:]
    s=s.replace('script = ExtResource("1")','script = ExtResource("1")\nicon = ExtResource("campaign_art")',1)
    write(p,s)

def main():
    catalog={'enemies':{},'props':{},'features':{},'items':{}}
    for name,h,poses,indices,source,rage in [
        ('queen',1.42,['idle','attack','hurt'],[0,1,2],'queen-poses',True),
        ('archer',.92,['idle','draw','release','hurt','attack'],[0,1,2,3,1],'archer-poses',False),
        ('guard',1.08,['idle','attack','hurt','brace'],[0,1,2,3],'guard-poses',False),
        ('great-rat',.62,['idle','attack','hurt'],[0,1,2],None,False),
        ('webspinner',.68,['idle','attack','hurt'],[0,1,2],None,False),
        ('drummer',.94,['idle','attack','hurt'],[0,1,2],'drummer-poses',False)]:
        catalog['enemies'][name]=enemy(name,h,poses,indices,source,rage)
    states,reg=registered(cells('fortress-doors'));REPORT['registration']['doors']=reg
    for n,im in zip(['gate-barred','gate-broken','hall-closed','hall-open'],states):catalog['features'][n]=prop(n,im,2.35,True)
    for n,h,im in zip(['palisade','watch-post','goblin-mark','trophies'],[1.22,1.65,.72,.88],cells('outskirts-props')):
        imgs,reg=registered([im]);REPORT['registration'][n]=reg;catalog['props'][n]=prop(n,imgs[0],h)
    imgs,reg=registered([load('throne')]);REPORT['registration']['throne']=reg;catalog['props']['throne']=prop('throne',imgs[0],1.25)
    textures=cells('fortress-textures');textures=[im.resize((128,128),Image.Resampling.NEAREST) for im in textures]
    pal=palette(textures,32)
    for n,im in zip(['wall','wall-timber','floor','ceiling'],textures):
        folder=ROOT/'art/textures/fortress-v1';folder.mkdir(parents=True,exist_ok=True)
        im=quantize(im,pal);im.putalpha(255);im.save(folder/(n+'.png'))
        write(folder/(n+'.tres'),'[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n[ext_resource type="Texture2D" path="'+uri(folder/(n+'.png'))+'" id="texture"]\n[resource]\nresource_name = "Fortress v1 - '+n+'"\ntexture_filter = 0\nalbedo_texture = ExtResource("texture")\nroughness = 1.0\n')
        REPORT['assets'][(folder/(n+'.png')).relative_to(ROOT).as_posix()]={'canvas':[128,128],'opaque':True,'shared_palette_limit':32}
    for n in ['broken-short-sword','cracked-staff']:
        p=ROOT/'art/items/campaign-v1'/(n+'.png');save(fit_icon(load(n)),p);catalog['items'][n]=uri(p)
    p=ROOT/'art/illustrations/fortress-v1/victory.png';p.parent.mkdir(parents=True,exist_ok=True)
    im=ImageOps.fit(load('victory'),(640,360),Image.Resampling.NEAREST);im=quantize(im,palette([im],64));im.putalpha(255);im.save(p)
    REPORT['assets'][p.relative_to(ROOT).as_posix()]={'canvas':[640,360],'opaque':True,'palette_limit':64}
    if (SOURCE/'camp-occupancy.png').exists():
        for n,im in zip(['seated-a','seated-b','meal','drying-cloth'],cells('camp-occupancy')):
            crop=im.crop(mask(im).getbbox());crop.thumbnail((42,48) if n.startswith('seated') else (48,40),Image.Resampling.NEAREST)
            target=Image.new('RGBA',(64,64));target.paste(crop,((64-crop.width)//2,57-crop.height))
            save(target,ROOT/'art/camp/occupancy-v1'/(n+'.png'))
    if '--wire-icons' in sys.argv:
        for resource,path in [('data/gear/broken_short_sword.tres',catalog['items']['broken-short-sword']),('data/gear/cracked_staff.tres',catalog['items']['cracked-staff']),('data/gear/padded_coat.tres','res://art/items/inventory-64-v1/padded-coat.png'),('data/gear/leather_jerkin.tres','res://art/items/armour-v1/leather-jerkin.png')]:
            s=(ROOT/resource).read_text(encoding='utf-8')
            if not re.search(r'^icon = ',s,flags=re.M):wire_icon(resource,path)
    REPORT['source_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.png')}
    REPORT['sha256']={n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in REPORT['assets']}
    write(REVIEW/'asset-validation.json',json.dumps(REPORT,indent=2)+'\n')
    write(ROOT/'art/enemies/campaign-v1/catalog.json',json.dumps(catalog,indent=2)+'\n')
    print('Exported '+str(len(REPORT['assets']))+' campaign textures and six enemy scene families.')

if __name__=='__main__':main()
