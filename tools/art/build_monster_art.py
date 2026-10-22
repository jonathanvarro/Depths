"""#141 mechanical pose extraction/registration; never redraw generated anatomy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/monsters-v1'
OUT=ROOT/'art/enemies/monsters-v1'
REVIEW=ROOT/'art/concepts/monsters-v1'

def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def font(n):return ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),n)

def components(alpha):
    """8-connected scanline components; avoid an extra scipy dependency."""
    runs=[];parent=[];previous=[]
    def find(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for y,row in enumerate(alpha):
        changes=np.diff(np.pad(row.astype(np.int8),(1,1)))
        current=[]
        for left,right in zip(np.flatnonzero(changes==1),np.flatnonzero(changes==-1)):
            i=len(runs);parent.append(i);runs.append((y,int(left),int(right)));current.append((int(left),int(right),i))
            for pl,pr,pi in previous:
                if pl<=right and pr>=left:parent[find(i)]=find(pi)
        previous=current
    groups={}
    for i,run in enumerate(runs):groups.setdefault(find(i),[]).append(run)
    return list(groups.values())

def extract(entry):
    raw=Image.open(ROOT/entry['source']).convert('RGBA');a=np.array(raw)
    cols,rows=entry['layout'];cw=raw.width/cols;ch=raw.height/rows
    masks=[np.zeros(a.shape[:2],dtype=np.uint8) for _ in range(cols*rows)]
    details=[]
    for group in components(a[:,:,3]>=128):
        count=sum(r-l for y,l,r in group)
        if count<32:continue # Subpixel export specks, never painted anatomy.
        left=min(l for y,l,r in group);right=max(r for y,l,r in group);top=group[0][0];bottom=group[-1][0]+1
        col=min(cols-1,max(0,int((left+right)/2/cw)));row=min(rows-1,max(0,int((top+bottom)/2/ch)))
        target=masks[row*cols+col]
        for y,l,r in group:target[y,l:r]=255
        details.append({'bounds':[left,top,right,bottom],'pixels':count,'cell':row*cols+col})
    poses=[]
    for i,name in enumerate(entry['poses']):
        alpha=Image.fromarray(masks[i]);im=raw.copy();im.putalpha(alpha);b=alpha.getbbox()
        assert b is not None,(entry['id'],name)
        poses.append({'name':name,'image':im.crop(b),'source_bounds':list(b),
                      'anchor_x':(i%cols+.5)*cw-b[0], 'source':entry['source']})
    return poses,details

def palette(images):
    samples=np.concatenate([a[:,:,:3][a[:,:,3]>0] for a in [np.array(im) for im in images]])
    return Image.fromarray(samples.reshape(1,-1,3)).quantize(32,dither=Image.Dither.NONE)

def frames(folder,names,aliases):
    ext='\n'.join('[ext_resource type="Texture2D" path="'+uri(folder/(n+'.png'))+'" id="'+n+'"]' for n in names)
    animations=[]
    sequences={n:[n] for n in names if not n.startswith('burst-')}
    if 'burst-1' in names:sequences['burst']=['burst-1','burst-2']
    sequences.update({a:[target] for a,target in aliases.items()})
    for name,sequence in sequences.items():
        animations.append('{"frames":['+','.join('{"duration":1.0,"texture":ExtResource("'+n+'")}' for n in sequence)+'],"loop":'+('true' if name in ['idle','landed','curled','wind-up','recover','swell','grab','set-snare','rally','call','drain','enraged'] else 'false')+',"name":&"'+name+'","speed":8.0}')
    write(folder/'frames.tres','[gd_resource type="SpriteFrames" load_steps='+str(len(names)+1)+' format=3]\n'+ext+'\n\n[resource]\nanimations = ['+',\n'.join(animations)+']\n')
    return sequences

def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True);write(REVIEW/'.gdignore','')
    manifest=read(SOURCE/'generation.json');records={a['id']:a for a in manifest['assets']}
    for entry in manifest['assets']:assert sha(ROOT/entry['source'])==entry['sha256'],entry['id']
    catalog={'issue':141,'placement':'Art library. No enemy stats, behaviour, encounter tables or save changes. New state poses must be chosen by combat code.','enemies':{},'assets':[]}
    overview=Image.new('RGB',(1056,710),'#202720');d=ImageDraw.Draw(overview)
    for i,spec in enumerate(read(SOURCE/'designs.json')):
        id=spec['id'];entry=records[id+'-poses'];poses,parts=extract(entry)
        if id=='gate-captain':
            fixed,_=extract(records['gate-captain-rally-fix']);poses[1]=fixed[1]
        size=192 if id=='broodmother' else 128;pivot=[size//2,round(size*.9375)]
        airborne=id in ['gas-bloat','lamp-eater'];bottom=pivot[1]-14 if airborne else pivot[1]
        max_up=bottom-8;max_down=size-9-bottom
        # One raw-pixel scale per family, including raised weapons and widest wings.
        half=max(max(p['anchor_x'],p['image'].width-p['anchor_x']) for p in poses)
        scale=min((size-16)/(half*2),max_up/max(p['image'].height for p in poses))
        exports=[];registration=[]
        for p in poses:
            image=p['image'];new=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.BOX)
            dx=round(pivot[0]-p['anchor_x']*scale);dy=bottom+1-new.height
            target=Image.new('RGBA',(size,size));target.alpha_composite(new,(dx,dy))
            a=np.array(target);a[:,:,3]=np.where(a[:,:,3]>=128,255,0);a[a[:,:,3]==0]=0
            exports.append(Image.fromarray(a));registration.append({k:v for k,v in p.items() if k!='image'}|{'scale':scale,'offset':[dx,dy],'contact_y':bottom})
        pal=palette(exports);folder=OUT/id;folder.mkdir(exist_ok=True);hashes={}
        for p,im in zip(poses,exports):
            alpha=im.getchannel('A');im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');im.putalpha(alpha)
            a=np.array(im);a[a[:,:,3]==0]=0;im=Image.fromarray(a);im.save(folder/(p['name']+'.png'));hashes[p['name']]=sha(folder/(p['name']+'.png'))
        aliases={'attack':'swoop'} if id=='cave-bat' else {'attack':'drain'} if id=='lamp-eater' else {}
        sequence=frames(folder,[p['name'] for p in poses],aliases)
        idle=Image.open(folder/'idle.png');bounds=idle.getbbox();pixel=spec['height']/(bounds[3]-bounds[1])
        hover=.18 if airborne else 0.0
        tops={n:[Image.open(folder/(frame+'.png')).getbbox()[1] for frame in names] for n,names in sequence.items()}
        script='[ext_resource type="Script" path="res://art/enemies/monsters-v1/'+('bat_mount.gd' if id=='cave-bat' else 'pose_bounds.gd')+'" id="mount"]\n'
        scene='[gd_scene load_steps=3 format=3]\n[ext_resource type="SpriteFrames" path="'+uri(folder/'frames.tres')+'" id="frames"]\n'+script+'\n[node name="'+id+'" type="Node3D"]\nscript = ExtResource("mount")\npose_tops = '+json.dumps(tops)+'\n'
        if id=='cave-bat':scene+='hanging_top_pixel = '+str(bounds[1])+'\n'
        scene+='metadata/visual_height = '+str((pivot[1]-bounds[1])*pixel+hover)+'\nmetadata/pivot = Vector2('+str(pivot[0])+', '+str(pivot[1])+')\nmetadata/hover_metres = '+str(hover)+'\n\n[node name="Sprite" type="AnimatedSprite3D" parent="."]\nposition = Vector3(0, '+str((pivot[1]-size/2)*pixel+hover)+', 0)\npixel_size = '+str(pixel)+'\nbillboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\ncast_shadow = 0\nsprite_frames = ExtResource("frames")\nanimation = &"idle"\n'
        write(folder/'scene.tscn',scene)
        asset={'id':id,'scene':uri(folder/'scene.tscn'),'frames':uri(folder/'frames.tres'),'canvas':[size,size],'pivot':pivot,'visual_height_metres':spec['height'],'pixel_size':pixel,'hover_metres':hover,'poses':{n:uri(folder/(n+'.png')) for n in hashes},'animations':sequence,'animation_tops':tops,'aliases':aliases,'palette':sorted([list(c) for c in set(c[:3] for im in [Image.open(folder/(n+'.png')).convert('RGBA') for n in hashes] for c in im.get_flattened_data() if c[3]>0)]),'registration':registration,'pose_sha256':hashes,'source_components':parts}
        catalog['enemies'][id]=asset['scene'];catalog['assets'].append(asset)
        # Each complete pose family is shown untrimmed on the same native canvas.
        sheet=Image.new('RGB',(max(size*len(poses),640),size+58),'#202720');pen=ImageDraw.Draw(sheet)
        for j,p in enumerate(poses):
            im=Image.open(folder/(p['name']+'.png')).convert('RGBA');sheet.paste(im,(size*j,22),im);pen.text((size*j+8,size+28),p['name'],fill='#dfd7bd',font=font(14))
        sheet.save(REVIEW/(id+'-poses.png'))
        x=i%4*264;y=i//4*232;small=idle.convert('RGBA')
        if size!=128:small=small.resize((128,128),Image.Resampling.NEAREST)
        overview.paste(small,(x+68,y+12),small);d.text((x+12,y+152),id,font=font(18),fill='#e3d7b7');d.text((x+12,y+180),str(len(poses))+' drawings / '+str(size)+'px',font=font(15),fill='#b0b99d')
    overview.save(REVIEW/'overview.png');write(OUT/'catalog.json',json.dumps(catalog,indent=2)+'\n')
    # Existing art and reused symbols are immutable; gameplay code is not an input.
    preserved=[p for p in (ROOT/'art/enemies').rglob('*') if p.is_file() and OUT not in p.parents and p.suffix in ['.png','.tres','.tscn','.gd']]
    preserved+=[ROOT/'art/ui/backlog96-v1/intent/heavy.png']
    p=SOURCE/'preserved-art.json';baseline=read(p) if p.exists() else {uri(f):sha(f) for f in preserved}
    for name,h in baseline.items():assert sha(ROOT/name.removeprefix('res://'))==h,'Preserved art changed: '+name
    write(p,json.dumps(baseline,indent=2)+'\n')
    print('MONSTER_EXPORT: %d families / %d native drawings / one common scale and <=32 colours per family'%(len(catalog['assets']),sum(len(e['poses']) for e in catalog['assets'])))
if __name__=='__main__':main()
