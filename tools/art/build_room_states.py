"""Register #46 used-state art without altering the original prop textures."""
from pathlib import Path
import hashlib,json,re,sys
from PIL import Image,ImageDraw
from build_treasure_art import mask,palette,quantize,verify,font

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/room-states-v1'
OUT=ROOT/'art/props/room-states-v1'
STAIRS=ROOT/'art/features/stone-stairs-v1'
REVIEW=ROOT/'art/concepts/room-states-v1'
SPECS=[
 ('old-workings','cave-events-v1','chest_old_workings',False),
 ('idol-niche','cave-events-v1','object_pale_idol',False),
 ('still-pool','cave-room-props-v1','object_still_pool',True),
 ('dry-alcove','cave-events-v1','rest_dry_alcove',False),
 ('cold-camp','cave-room-props-v1','rest_old_camp',False),
 ('tripwire','cave-events-v1','trap_tripwire',False),
 ('hollow-floor','cave-events-v1','trap_hollow_floor',True)]
REPORT={'issue':46,'assets':{},'registration':{},'original_sha256':{},'source_sha256':{}}

def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(text,encoding='utf-8',newline='\n')
def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()
def load(name):return Image.open(SOURCE/(name+'.png')).convert('RGBA')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def save(im,path,pal=None):
    im=quantize(im,pal if pal is not None else palette([im],32))
    path.parent.mkdir(parents=True,exist_ok=True);im.save(path)
    REPORT['assets'][path.relative_to(ROOT).as_posix()]=verify(im,(128,128),32)
    return im

def used_prop(name,folder,event,flat):
    reference=ROOT/'art/props'/folder/(name+'.png')
    original=Image.open(reference).convert('RGBA')
    REPORT['original_sha256'][reference.relative_to(ROOT).as_posix()]=sha(reference)
    raw=load(name+'-used')
    im=raw.resize((128,128),Image.Resampling.NEAREST)
    assert im.getchannel('A').getextrema()[0]==0, name+' must have true transparency'
    # Preserve the full reference canvas. Grounded sprites get only a y shift,
    # never independent silhouette fitting; flat props retain their centre.
    offset_y=0 if flat else mask(original).getbbox()[3]-mask(im).getbbox()[3]
    registered=Image.new('RGBA',(128,128));registered.paste(im,(0,offset_y))
    output=OUT/(name+'-used.png');used=save(registered,output)
    REPORT['registration'][name]={'reference':reference.relative_to(ROOT).as_posix(),
      'full_canvas_resize':[128,128],'offset':[0,offset_y],
      'original_bounds':mask(original).getbbox(),'used_bounds':mask(used).getbbox(),
      'flat':flat,'scene_transform':'unchanged from reference scene'}
    old_scene=(ROOT/'art/props'/folder/(name+'.tscn')).read_text(encoding='utf-8')
    sprite=old_scene[old_scene.index('[node name="Sprite"'):]
    sprite=re.sub(r'texture = ExtResource\("[^"]+"\)', 'texture = ExtResource("texture")',sprite)
    scene='[gd_scene load_steps=4 format=3]\n\n'
    scene+='[ext_resource type="Texture2D" path="'+uri(reference)+'" id="texture"]\n'
    scene+='[ext_resource type="Texture2D" path="'+uri(output)+'" id="empty"]\n'
    scene+='[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="script"]\n\n'
    scene+='[node name="'+name+'" type="Node3D"]\nscript = ExtResource("script")\nclosed_texture = ExtResource("texture")\nempty_texture = ExtResource("empty")\n\n'+sprite
    path=OUT/(name+'.tscn');write(path,scene)
    return {'event':event,'scene':uri(path),'original':uri(reference),'used':uri(output),'flat':flat}

def fit_frames(images):
    raw=[im.resize((128,128),Image.Resampling.NEAREST) for im in images]
    bounds=[mask(im).getbbox() for im in raw]
    left=min(b[0] for b in bounds);right=max(b[2] for b in bounds)
    top=min(b[1] for b in bounds);bottom=max(b[3] for b in bounds)
    scale=min(112/(right-left),112/(bottom-top))
    dx=64-round((left+right)*scale/2);side=round(128*scale)
    result=[];offsets=[]
    for im,b in zip(raw,bounds):
        dy=121-round(b[3]*scale)
        target=Image.new('RGBA',(128,128))
        target.paste(im.resize((side,side),Image.Resampling.NEAREST),(dx,dy))
        result.append(target);offsets.append([dx,dy])
    return result,{'shared_scale':scale,'shared_x':dx,'offsets':offsets,'floor_contact_y':120}

def strongbox():
    master=load('strongbox-states');w,h=master.size
    frames=[master.crop((0,0,w//2,h//2)),master.crop((w//2,0,w,h//2))]
    frames,registration=fit_frames(frames);pal=palette(frames,32)
    for state,im in zip(['closed','used'],frames):save(im,OUT/('strongbox-'+state+'.png'),pal)
    REPORT['registration']['strongbox']=registration
    write(OUT/'strongbox.tscn','''[gd_scene load_steps=4 format=3]
[ext_resource type="Texture2D" path="res://art/props/room-states-v1/strongbox-closed.png" id="texture"]
[ext_resource type="Texture2D" path="res://art/props/room-states-v1/strongbox-used.png" id="empty"]
[ext_resource type="Script" path="res://art/props/cave-events-v1/container.gd" id="script"]
[node name="Strongbox" type="Node3D"]
script = ExtResource("script")
closed_texture = ExtResource("texture")
empty_texture = ExtResource("empty")
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0, 0.504, 0)
pixel_size = 0.009
billboard = 2
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
texture = ExtResource("texture")
''')
    return {'event':'chest_strongbox','scene':uri(OUT/'strongbox.tscn'),
      'original':uri(OUT/'strongbox-closed.png'),'used':uri(OUT/'strongbox-used.png'),'flat':False}

def stairs():
    for direction in ['up','down']:
        frames,registration=fit_frames([load('stairs-'+direction)])
        im=save(frames[0],STAIRS/('stairs-'+direction+'.png'))
        REPORT['registration']['stairs-'+direction]=registration
        for theme in ['stone','fortress']:
            material='art/textures/stone-v1/floor.tres' if theme=='stone' else 'art/textures/fortress-v1/floor.tres'
            # The down cell has no floor supplied by LevelBuilder. Its own
            # ground mesh fills the cell; the art remains a presentation prop.
            ground='''[node name="Ground" type="MeshInstance3D" parent="."]
position = Vector3(0, -0.015, 0)
mesh = SubResource("ground")
'''
            prefix='[gd_scene load_steps=4 format=3]\n'
            prefix+='[ext_resource type="Texture2D" path="'+uri(STAIRS/('stairs-'+direction+'.png'))+'" id="texture"]\n'
            prefix+='[ext_resource type="Material" path="res://'+material+'" id="floor"]\n'
            prefix+='[sub_resource type="PlaneMesh" id="ground"]\nmaterial = ExtResource("floor")\nsize = Vector2(2, 2)\n'
            prefix+='[node name="Stairs'+direction.title()+'" type="Node3D"]\n'
            prefix+='metadata/direction = "'+direction+'"\n'
            if direction=='down':
                # This master already contains front-facing perspective.
                # Match other world props rather than projecting it twice.
                pixel=.95/(mask(im).getbbox()[3]-mask(im).getbbox()[1])
                sprite='position = Vector3(0, '+str(56*pixel)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = 2\n'
                prefix+=ground
            else:
                pixel=1.7/(mask(im).getbbox()[3]-mask(im).getbbox()[1])
                sprite='position = Vector3(0, '+str(56*pixel)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = 2\n'
            write(STAIRS/(theme+'-'+direction+'.tscn'),prefix+'[node name="Sprite" type="Sprite3D" parent="."]\n'+sprite+'shaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ntexture = ExtResource("texture")\n')

def wire(catalog):
    for entry in catalog['props'].values():
        path=ROOT/'data/events'/(entry['event']+'.tres')
        text=path.read_text(encoding='utf-8')
        text,count=re.subn(r'(\[ext_resource type="PackedScene" path=")[^"]+(" id="prop"\])',lambda m:m[1]+entry['scene']+m[2],text)
        assert count==1,path
        write(path,text)
    for theme in ['stone','fortress']:
        path=ROOT/'themes'/(theme+'.tres');text=path.read_text(encoding='utf-8')
        if 'id="stairs_up"' not in text:
            ext=''.join('[ext_resource type="PackedScene" path="'+uri(STAIRS/(theme+'-'+direction+'.tscn'))+'" id="stairs_'+direction+'"]\n' for direction in ['up','down'])
            text=text.replace('[resource]',ext+'\n[resource]',1)
            text+='\nascent_scene = ExtResource("stairs_up")\ndescent_scene = ExtResource("stairs_down")\n'
        write(path,text)

def review(catalog):
    pairs=[]
    for name,entry in catalog['props'].items():pairs.append((name,entry['original'],entry['used']))
    pairs.append(('stairs','res://art/features/stone-stairs-v1/stairs-up.png','res://art/features/stone-stairs-v1/stairs-down.png'))
    for theme,bg,ink in [('dark','#1b2420','#e6dac1'),('light','#d6cbb4','#282b25')]:
        board=Image.new('RGBA',(416,180*len(pairs)),bg);draw=ImageDraw.Draw(board)
        for i,(name,before,after) in enumerate(pairs):
            y=i*180
            draw.text((8,y+3),name,font=font(16),fill=ink)
            for x,path in [(0,before),(208,after)]:
                im=Image.open(ROOT/path.removeprefix('res://')).convert('RGBA')
                board.alpha_composite(im,(x+64,y+25))
                small=im.resize((48,48),Image.Resampling.NEAREST);board.alpha_composite(small,(x+8,y+100))
                draw.text((x+64,y+153),'before / up' if x==0 else 'used / down',font=font(13),fill=ink)
        board.convert('RGB').save(REVIEW/('states-'+theme+'.png'))
        overview=Image.new('RGBA',(864,552),bg);draw=ImageDraw.Draw(overview)
        for i,(name,before,after) in enumerate(pairs):
            x=(i%3)*288;y=(i//3)*184
            draw.text((x+8,y+2),name,font=font(16),fill=ink)
            for dx,path in [(8,before),(152,after)]:
                im=Image.open(ROOT/path.removeprefix('res://')).convert('RGBA')
                overview.alpha_composite(im,(x+dx,y+25))
                label=('up' if dx==8 else 'down') if name=='stairs' else ('before' if dx==8 else 'used')
                draw.text((x+dx+4,y+157),label,font=font(13),fill=ink)
        overview.convert('RGB').save(REVIEW/('overview-'+theme+'.png'))

def main():
    for folder in [SOURCE,REVIEW]:write(folder/'.gdignore','')
    catalog={'issue':46,'canvas':[128,128],'props':{}}
    for spec in SPECS:catalog['props'][spec[0]]=used_prop(*spec)
    catalog['props']['strongbox']=strongbox();stairs()
    if '--wire' in sys.argv:wire(catalog)
    review(catalog)
    REPORT['source_sha256']={p.name:sha(p) for p in SOURCE.glob('*.png')}
    REPORT['sha256']={name:sha(ROOT/name) for name in REPORT['assets']}
    write(OUT/'catalog.json',json.dumps(catalog,indent=2)+'\n')
    write(REVIEW/'export-validation.json',json.dumps(REPORT,indent=2)+'\n')
    print('Exported seven used variants, two strongbox states and two stairs; originals preserved.')

if __name__=='__main__':main()
