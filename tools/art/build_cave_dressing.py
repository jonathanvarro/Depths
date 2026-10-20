"""Mechanical 128px exports, mount/pivot metadata and standalone dressing scenes.

No live floor placement. Original ImageGen masters stay untouched. The web is
an explicit source crop; chalk is authored SVG; the mine frame has registered
component exports in addition to its whole support scene.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/cave-dressing-v1'
OUT = ROOT / 'art/dressing/cave-v1'
REVIEW = ROOT / 'art/concepts/cave-dressing-v1'
# id, mount, measured axis, real size, floor range, opacity
SPECS = [
    ('stalactite-single','ceiling','height',.55,[1,3],1),
    ('stalactite-pair','ceiling','height',.65,[1,3],1),
    ('stalactite-cluster','ceiling','height',.8,[1,3],1),
    ('stalagmite-stub','floor-edge','height',.3,[1,3],1),
    ('stalagmite-tall','floor-edge','height',1.0,[1,3],1),
    ('stalagmite-broken','floor-edge','height',.45,[1,3],1),
    ('flowstone','wall','height',1.05,[1,2],1),
    ('cracks-rubble','wall','height',1.0,[1,4],1),
    ('web-strand','ceiling','width',.85,[1,2],1),
    ('mine-support','floor-edge','height',2.4,[1,1],1),
    ('burnt-sconce','wall','height',.5,[1,2],1),
    ('goblin-torch-base','wall','height',.6,[3,4],1),
    ('goblin-daubs','wall','width',.7,[3,4],.8),
    ('hanging-trophies','ceiling','height',.7,[3,4],1),
    ('puddle-small','floor-decal','width',.65,[1,2],.45),
    ('puddle-wide','floor-decal','width',1.1,[1,2],.45),
    ('floor-gravel','floor-decal','width',.9,[1,4],1),
    ('mine-rails','floor-decal','width',1.4,[1,1],1),
    ('tracks-drag','floor-decal','width',1.0,[1,3],.65),
    ('floor-crack','floor-decal','height',1.2,[1,4],.7),
    ('goblin-litter','floor-decal','width',.7,[3,4],1),
    ('old-scorch','floor-decal','width',.8,[1,3],.55),
    ('pale-mushrooms','floor-edge','height',.3,[2,3],1),
    ('rat-nest','floor-edge','width',.5,[1,2],1),
    ('wall-fungus','wall','width',.45,[2,3],1),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def texture(raw, size=128):
    raw = raw.convert('RGBA')
    bounds = raw.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    assert bounds, 'No opaque artwork'
    art = raw.crop(bounds)
    ratio = min((size-16)/art.width, (size-16)/art.height)
    assert ratio <= 1, 'Never upscale source masters'
    art = art.resize((round(art.width*ratio),round(art.height*ratio)),Image.Resampling.LANCZOS)
    image = Image.new('RGBA',(size,size))
    offset = ((size-art.width)//2,(size-art.height)//2)
    image.alpha_composite(art,offset)
    alpha = image.getchannel('A').point(lambda a:255 if a>=128 else 0)
    image = image.convert('RGB').quantize(64,dither=Image.Dither.NONE).convert('RGBA')
    image.putalpha(alpha)
    return image, {'source_bounds':list(bounds),'scale':ratio,'offset':list(offset)}


def scene(entry, image):
    ident=entry['id'];mount=entry['mount'];pivot=entry['pivot'];px=entry['pixel_size']
    # Sprite3D's positive texture Y is downward; its world Y is upward.
    x=(64-pivot[0])*px;y=(pivot[1]-64)*px
    rotation='rotation_degrees = Vector3(-90, 0, 0)\n' if mount=='floor-decal' else ''
    z=.012 if mount=='wall' else 0
    position=f'position = Vector3({x}, {y}, {z})\n'
    if mount=='floor-decal':
        position='position = Vector3(0, 0.012, 0)\n'
    billboard = 2 if mount in ('ceiling','floor-edge') else 0
    if ident.startswith(('mine-support','mine-post','mine-crossbeam')):
        billboard = 0
    text=f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://art/dressing/cave-v1/{ident}.png" id="texture"]

[node name="{ident}" type="Node3D"]
metadata/dressing_id = "{ident}"

[node name="Sprite" type="Sprite3D" parent="."]
{position}{rotation}pixel_size = {px}
billboard = {billboard}
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
modulate = Color(1, 1, 1, {entry['opacity']})
texture = ExtResource("texture")
'''
    # Soft floor opacity must use alpha blending, not an alpha-test cutoff.
    if entry['opacity']<1:
        text=text.replace('alpha_cut = 1','alpha_cut = 0')
    (OUT/(ident+'.tscn')).write_text(text,encoding='utf-8')


def entry_for(ident,mount,axis,metres,floors,opacity,image,origin,transform):
    bounds=image.getchannel('A').getbbox()
    length=bounds[3]-bounds[1] if axis=='height' else bounds[2]-bounds[0]
    pivot=[64,bounds[1]] if mount=='ceiling' else [64,bounds[3]] if mount=='floor-edge' else [64,64]
    entry={'id':ident,'mount':mount,'pivot':pivot,'canvas':[128,128],
           'texture':'res://art/dressing/cave-v1/'+ident+'.png','scene':'res://art/dressing/cave-v1/'+ident+'.tscn',
           'pixel_size':metres/length,'measured_axis':axis,'metres':metres,'floors':floors,'opacity':opacity,
           'source':origin,'source_sha256':sha(ROOT/origin.removeprefix('res://')),
           'edge_only':mount in ('ceiling','floor-edge'),'collision':False,**transform}
    if ident=='cracks-rubble':entry['suggested_wall_height']=metres/2
    if ident=='mine-support':entry['full_height_support']=True
    image.save(OUT/(ident+'.png'));scene(entry,image)
    entry['export_sha256']=sha(OUT/(ident+'.png'))
    return entry


def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').write_text('',encoding='utf-8')
    meta=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'))
    for source in meta['assets']:
        actual=sha(ROOT/source['source'])
        assert 'sha256' not in source or source['sha256']==actual,source['id']
        source['sha256']=actual
    (SOURCE/'generation.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8')
    entries=[]
    for ident,mount,axis,metres,floors,opacity in SPECS:
        selected={'puddle-small':'puddle-small-refined','old-scorch':'old-scorch-refined'}.get(ident,ident)
        path=SOURCE/(selected+'-master.png')
        image,transform=texture(Image.open(path))
        entries.append(entry_for(ident,mount,axis,metres,floors,opacity,image,'res://'+path.relative_to(ROOT).as_posix(),transform))
    web=ROOT/'art/source/expedition-v1/web-intact.png'
    raw=Image.open(web).convert('RGBA')
    crop=(0,0,raw.width//2,raw.height//2)
    image,transform=texture(raw.crop(crop));transform['source_crop']=list(crop)
    e=entry_for('corner-web','wall','width',.7,[1,2],1,image,'res://'+web.relative_to(ROOT).as_posix(),transform)
    # This source's top/left attachment is retained; offset corner at the root.
    e['mount']='corner';e['pivot']=[image.getchannel('A').getbbox()[0],image.getchannel('A').getbbox()[1]]
    scene(e,image);entries.append(e)
    frame=Image.open(OUT/'mine-support.png').convert('RGBA')
    family=next(e for e in entries if e['id']=='mine-support')
    for name,box,pivot,mount in [('mine-post-left',(0,31,64,128),(25,120),'floor-edge'),('mine-post-right',(64,31,128,128),(103,120),'floor-edge'),('mine-crossbeam',(0,0,128,31),(64,8),'ceiling')]:
        part=Image.new('RGBA',(128,128));part.paste(frame.crop(box),(box[0],box[1]))
        e={**family,'id':name,'mount':mount,'pivot':list(pivot),'family':'mine-support',
           'family_component_crop':list(box),'texture':'res://art/dressing/cave-v1/'+name+'.png',
           'scene':'res://art/dressing/cave-v1/'+name+'.tscn'}
        bounds=part.getchannel('A').getbbox()
        e['metres']=(bounds[3]-bounds[1])*family['pixel_size']
        e['family_origin_offset']=[(pivot[0]-64)*family['pixel_size'],(120-pivot[1])*family['pixel_size'],0]
        part.save(OUT/(name+'.png'));scene(e,part);e['export_sha256']=sha(OUT/(name+'.png'));entries.append(e)
    for name in ('chalk-arrow','chalk-cross','chalk-tally'):
        # Rastered natively by build_ambient_atlases.gd at its authored 64px.
        path=SOURCE/'native'/(name+'.png')
        if path.exists():
            small=Image.open(path).convert('RGBA')
            image=Image.new('RGBA',(128,128));image.alpha_composite(small,(32,32))
            alpha=image.getchannel('A')
            image=image.convert('RGB').quantize(64,dither=Image.Dither.NONE).convert('RGBA')
            image.putalpha(alpha)
            origin='res://art/source/cave-dressing-v1/'+name+'.svg'
            entries.append(entry_for(name,'wall','width',.4,[1,2],.8,image,origin,{'processing':'Native SVG raster placed at 1:1, no resize.'}))
    for entry in entries:
        entry['native_rgba_bytes']=128*128*4
        if entry['id']=='goblin-torch-base':
            entry['lit_scene']='res://art/dressing/cave-v1/goblin-torch-lit.tscn'
            entry['flame_seat']=[64,14]
            entry['light_rules']='Mood only: no effect on carried light, nerves, inventory or encounter rules.'
        if entry['id']=='wall-fungus':
            entry['glow_frames']='res://art/effects/ambient-v1/fungus-pulse.tres'
    data={'issues':[128,129],'cell_metres':2.0,'wall_metres':2.4,'colour_limit':64,
          'placement':'Library only. Claude owns sparse seeded placement and exclusions; scenes add no colliders or inventory hooks.',
          'assets':entries}
    (OUT/'catalog.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    board(entries)
    print(f'Exported {len(entries)} dressing textures/scenes with mounts and source hashes.')


def board(entries):
    font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),15)
    rows=(len(entries)+5)//6
    board=Image.new('RGB',(1152,40+rows*170),'#242b29');d=ImageDraw.Draw(board)
    d.text((16,8),'Depths / cave dressing / native 128px exports',font=font,fill='#e6dac1')
    for i,entry in enumerate(entries):
        x=12+(i%6)*192;y=40+(i//6)*170
        image=Image.open(OUT/(entry['id']+'.png')).convert('RGBA')
        board.paste(image,(x+25,y),image)
        d.text((x,y+130),entry['id'],font=font,fill='#e6dac1')
        d.text((x,y+149),entry['mount'],font=font,fill='#a9b2aa')
    board.save(REVIEW/'dressing-overview.png')


if __name__=='__main__':
    main()
