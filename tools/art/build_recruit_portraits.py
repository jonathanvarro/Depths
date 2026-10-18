"""Register generated portrait atlases into a shared full-canvas 192px kit."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageOps
import hashlib
import json
import zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/recruit-kit-v1'
OUT=ROOT/'art/portraits/recruit-kit-v1'
DATA=ROOT/'data/portraits/recruits-v1'
REVIEW=ROOT/'art/concepts/recruit-kit-v1'
SIZE=(192,192)
EYES=(78,53,135,80)
MOUTH=(89,91,125,108)
CONDITIONS=['blood','dirt','bandage','pallor']

def pixels(im):
    return im.get_flattened_data() if hasattr(im,'get_flattened_data') else im.getdata()

def blank(): return Image.new('RGBA',SIZE)
def load(name): return Image.open(SOURCE/(name+'.png')).convert('RGBA')
def alpha(im): return im.getchannel('A').point(lambda a:255 if a>=96 else 0)

def register(im):
    # All full source cells use ONE common transform, never per-feature fitting.
    result=blank()
    result.paste(im.resize((184,184),Image.Resampling.NEAREST),(4,4))
    return result

def cells(name,cols,rows):
    im=load(name)
    return [register(im.crop((round(x*im.width/cols),round(y*im.height/rows),
        round((x+1)*im.width/cols),round((y+1)*im.height/rows))))
        for y in range(rows) for x in range(cols)]

def make_palette(images,count):
    samples=[p[:3] for im in images for p in pixels(im) if p[3]>=96]
    strip=Image.new('RGB',(len(samples),1));strip.putdata(samples)
    return strip.quantize(colors=count,dither=Image.Dither.NONE)

def quantize(im,pal,keep_alpha=False):
    result=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(im.getchannel('A') if keep_alpha else alpha(im))
    return result

def patch(im,box):
    result=blank();result.paste(im.crop(box),box[:2]);return result

def align_cell(im,base):
    # Fit unchanged nose/ear/chin regions, excluding edited eyes and lips.
    anchors=[(101,80,116,93),(55,73,64,87),(97,111,114,117)]
    best=None
    for dy in range(-3,4):
        for dx in range(-3,4):
            moved=blank();moved.paste(im,(dx,dy))
            score=0
            for box in anchors:
                a=list(pixels(base.crop(box).convert('L')))
                b=list(pixels(moved.crop(box).convert('L')))
                am=sum(a)/len(a);bm=sum(b)/len(b)
                score+=sum(abs((x-am)-(y-bm)) for x,y in zip(a,b))/len(a)
            candidate=(score,abs(dx)+abs(dy),dx,dy,moved)
            if best is None or candidate[:2]<best[:2]:best=candidate
    return best[4],list(best[2:4])

def composite(layers):
    result=blank()
    for layer in layers:result.alpha_composite(layer)
    return result

def font(size):
    result=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),size)
    try:result.set_variation_by_axes([400 if a['name']==b'Weight' else a['default'] for a in result.get_variation_axes()])
    except OSError:pass
    return result

def save_ora(name,layers,merged):
    # OpenRaster lists the TOP layer first; every layer retains the full canvas.
    image=ET.Element('image',{'version':'0.0.3','w':'192','h':'192','name':name})
    stack=ET.SubElement(image,'stack')
    with zipfile.ZipFile(SOURCE/(name+'.ora'),'w',zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(label,path,visible) in enumerate(reversed(layers)):
            dest='data/layer-'+str(i)+'.png'
            archive.write(path,dest)
            ET.SubElement(stack,'layer',{'name':label,'src':dest,'opacity':'1.0',
                'visibility':'visible' if visible else 'hidden','composite-op':'svg:src-over','x':'0','y':'0'})
        archive.writestr('stack.xml',ET.tostring(image,encoding='utf-8',xml_declaration=True))
        archive.write(merged,'mergedimage.png')

def add_lighting(lines,directory):
    declarations=['[ext_resource type="Texture2D" path="'+directory+'/'+name+'-left.png" id="light_'+name+'"]' for name in ['shadow','highlight']]
    index=lines.index('[resource]')
    lines[index:index]=declarations+['']
    lines += ['light_shadow = ExtResource("light_shadow")','light_highlight = ExtResource("light_highlight")']

def make_resource(character,expression):
    names=['shared/body.png',character+'/head.png',character+'/eyes-'+expression+'.png',
        character+'/mouth-'+expression+'.png','shared/jerkin.png']
    if expression=='neutral':
        names += [character+'/'+n+'.png' for n in ['eyes-half','eyes-closed','mouth-small','mouth-open']]
    names += [character+'/'+n+'.png' for n in CONDITIONS]
    lines=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','',
        '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]']
    for i,n in enumerate(names):lines.append('[ext_resource type="Texture2D" path="res://art/portraits/recruit-kit-v1/'+n+'" id="'+str(i)+'"]')
    lines += ['','[resource]','script = ExtResource("script")','body = ExtResource("0")','head = ExtResource("1")',
        'eyes = ExtResource("2")','mouth = ExtResource("3")','clothing = Array[Texture2D]([ExtResource("4")])']
    condition_start=9 if expression=='neutral' else 5
    lines.append('conditions = {'+', '.join('"'+n+'": ExtResource("'+str(i+condition_start)+'")' for i,n in enumerate(CONDITIONS))+'}')
    if expression=='neutral':
        lines+=['blink_frames = Array[Texture2D]([ExtResource("5"), ExtResource("6")])',
            'talk_frames = Array[Texture2D]([ExtResource("7"), ExtResource("8")])']
    add_lighting(lines,'res://art/portraits/recruit-kit-v1/'+character)
    (DATA/(character+('' if expression=='neutral' else '-'+expression)+'.tres')).write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')

def main():
    for folder in [OUT/'shared',DATA,REVIEW]:folder.mkdir(parents=True,exist_ok=True)
    masters=[register(load('master-a')),register(load('master-b'))]
    outfit=register(load('outfit'))
    frames={role:cells(role+'-faces',3,2) for role in ['warden','scout']}
    pal=make_palette(masters+[outfit],48)
    masters=[quantize(im,pal) for im in masters];outfit=quantize(outfit,pal)
    # Linen is a complete modest body template beneath the removable outer jerkin.
    cloth_mask=Image.new('L',SIZE)
    cloth_mask.putdata([255 if p[3] and y>=113 and (y>=144 or (min(p[:3])>70 and p[0]-p[2]<62 and p[1]-p[2]<38)) else 0
        for y in range(192) for p in [masters[0].getpixel((x,y)) for x in range(192)]])
    body=masters[0].copy();body.putalpha(ImageChops.multiply(alpha(body),cloth_mask))
    body.save(OUT/'shared/body.png')
    outfit.putalpha(ImageChops.multiply(alpha(outfit),alpha(masters[0])))
    outfit.save(OUT/'shared/jerkin.png')
    report={'issue':84,'canvas':[192,192],'master_transform':{'resize_full_square':[184,184],'offset':[4,4]},
        'eye_region':EYES,'mouth_region':MOUTH,'shared_body':'shared/body.png','shared_clothing':'shared/jerkin.png',
        'assets':{},'frame_translations':{},'failures':[]}
    previews=[]
    catalog={'canvas':[192,192],'body_template':'average-covered-adult-v1','portraits':[]}
    for index,(role,character) in enumerate([('warden','warden-a'),('scout','scout-a')]):
        dest=OUT/character;dest.mkdir(parents=True,exist_ok=True)
        base=masters[index]
        head=base.copy()
        head_mask=alpha(head)
        for y in range(113,192):
            for x in range(192):
                # One shared neck/collar socket; no second body hidden in a head.
                head_mask.putpixel((x,y),255 if alpha(masters[0]).getpixel((x,y)) and not cloth_mask.getpixel((x,y)) else 0)
        head.putalpha(head_mask)
        head.save(dest/'head.png')
        eyes=patch(base,EYES);mouth=patch(base,MOUTH)
        eyes.save(dest/'eyes-neutral.png');mouth.save(dest/'mouth-neutral.png')
        aligned=[];shifts=[]
        for frame in frames[role]:
            registered,shift=align_cell(frame,base)
            aligned.append(quantize(registered,pal));shifts.append(shift)
        report['frame_translations'][character]=shifts
        exports={'eyes-half':patch(aligned[0],EYES),'eyes-closed':patch(aligned[1],EYES),
            'mouth-small':patch(aligned[2],MOUTH),'mouth-open':patch(aligned[3],MOUTH),
            'eyes-worried':patch(aligned[4],EYES),'mouth-worried':patch(aligned[4],MOUTH),
            'eyes-exhausted':patch(aligned[5],EYES),'mouth-exhausted':patch(aligned[5],MOUTH)}
        for name,im in exports.items():im.save(dest/(name+'.png'))
        merged=composite([body,head,eyes,mouth,outfit]);merged.save(dest/'preview.png')
        previews.append((character,merged))
        clip=alpha(merged)
        overlays=cells(role+'-conditions',2,2)
        for condition,im in zip(CONDITIONS,overlays):
            if condition=='bandage':
                b=alpha(im).getbbox();assert b
                cloth=im.crop(b);cloth.thumbnail((72,14),Image.Resampling.NEAREST)
                im=blank();im.paste(cloth,(101-cloth.width//2,45))
                report['assets'][character+'/bandage-registration']={'source_bounds':b,'target_top':45,'max_size':[72,14]}
            im=quantize(im,make_palette([im],8))
            channel=ImageChops.multiply(im.getchannel('A'),clip)
            if condition in ['dirt','pallor']:
                strength=0.4 if condition=='dirt' else 0.42
                channel=channel.point(lambda a:round(a*strength))
            if condition=='dirt':
                # Keep the generated mark shapes; remove guide-coloured linen
                # fragments by normalizing the material to one mud pigment.
                im=Image.new('RGBA',SIZE,(79,59,39,0))
            if condition=='pallor':
                keep=Image.new('L',SIZE)
                keep.putdata([255 if p[3] and y<144 and p[0]-p[2]>48 and p[1]-p[2]>18 and p[0]>85 and p[0]/max(1,p[1])<1.6 else 0
                    for y in range(192) for p in [base.getpixel((x,y)) for x in range(192)]])
                channel=ImageChops.multiply(channel,keep)
            im.putalpha(channel);assert im.getchannel('A').getbbox(),(character,condition)
            im.save(dest/(condition+'.png'))
        lights=cells(role+'-lighting',2,2)
        # Only the top pair is used: the raw mirrored-right studies are not registered.
        for i,name in enumerate(['shadow-left','highlight-left']):
            source=lights[i]
            gray=source.convert('L')
            coverage=gray.point((lambda v:min(255,round(v*3.2))) if i==0 else (lambda v:max(0,min(255,round((v-110)*255/145)))))
            coverage=ImageChops.multiply(coverage,source.getchannel('A'))
            coverage=coverage.resize((32,32),Image.Resampling.BOX).resize(SIZE,Image.Resampling.NEAREST)
            coverage=ImageChops.multiply(coverage,clip)
            light=Image.new('RGBA',SIZE,(0,0,0,0) if i==0 else (255,255,255,0));light.putalpha(coverage)
            light.save(dest/(name+'.png'))
        for expression in ['neutral','worried','exhausted']:make_resource(character,expression)
        ora_layers=[('Body – shared linen',OUT/'shared/body.png',True),('Head – neutral',dest/'head.png',True),
            ('Eyes – neutral',dest/'eyes-neutral.png',True),('Mouth – neutral',dest/'mouth-neutral.png',True),
            ('Clothing – shared jerkin',OUT/'shared/jerkin.png',True)]
        ora_layers += [(name,dest/(name+'.png'),False) for name in exports]
        ora_layers += [(name,dest/(name+'.png'),False) for name in CONDITIONS+['shadow-left','highlight-left']]
        save_ora(character,ora_layers,dest/'preview.png')
        catalog['portraits'].append({'id':character,'role':role.title(),'portrait':'res://art/portraits/recruit-kit-v1/'+character+'/preview.png',
            'portrait_set':'res://data/portraits/recruits-v1/'+character+'.tres','expressions':['neutral','worried','exhausted'],
            'shadow':'res://art/portraits/recruit-kit-v1/'+character+'/shadow-left.png',
            'highlight':'res://art/portraits/recruit-kit-v1/'+character+'/highlight-left.png'})
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    board=Image.new('RGBA',(768,272),'#202624');draw=ImageDraw.Draw(board)
    for i,(name,im) in enumerate(previews):
        x=i*384;draw.text((x+192,4),name.title(),font=font(20),fill='#e5d9bf',anchor='mt')
        board.alpha_composite(im,(x+24,38))
        board.alpha_composite(im.resize((96,96),Image.Resampling.NEAREST),(x+248,87))
    board.convert('RGB').save(REVIEW/'overview.png')
    sequence=[('neutral',600),('half',40),('closed',50),('half',50),('neutral',500),
        ('small',90),('open',90),('neutral',90),('small',90),('open',90),('neutral',700)]
    movie=[]
    for state,duration in sequence:
        board=Image.new('RGBA',(432,232),'#202624');draw=ImageDraw.Draw(board)
        for i,(name,_) in enumerate(previews):
            dest=OUT/name
            eye='eyes-'+state if state in ['half','closed'] else 'eyes-neutral'
            mouth='mouth-'+state if state in ['small','open'] else 'mouth-neutral'
            portrait=composite([body,Image.open(dest/'head.png').convert('RGBA'),
                Image.open(dest/(eye+'.png')).convert('RGBA'),Image.open(dest/(mouth+'.png')).convert('RGBA'),outfit])
            board.alpha_composite(portrait,(12+i*216,32))
            draw.text((108+i*216,4),name.title(),font=font(18),fill='#e5d9bf',anchor='mt')
        movie.append(board.convert('RGB'))
    movie[0].save(REVIEW/'animation-preview.gif',save_all=True,append_images=movie[1:],duration=[s[1] for s in sequence],loop=0,disposal=2)
    condition_board=Image.new('RGBA',(960,448),'#202624');draw=ImageDraw.Draw(condition_board)
    for row,(name,im) in enumerate(previews):
        for col,state in enumerate(['neutral']+CONDITIONS):
            frame=im.copy()
            if state!='neutral':frame.alpha_composite(Image.open(OUT/name/(state+'.png')).convert('RGBA'))
            condition_board.alpha_composite(frame,(col*192,row*224+28))
            draw.text((col*192+96,row*224+3),state,font=font(18),fill='#e5d9bf',anchor='mt')
    condition_board.convert('RGB').save(REVIEW/'conditions.png')
    paths=list(OUT.rglob('*.png'))
    for path in paths:
        im=Image.open(path).convert('RGBA');assert im.size==SIZE,path
        assert im.getpixel((0,0))[3]==0,path
        visible={p[:3] for p in pixels(im) if p[3]}
        report['assets'][path.relative_to(OUT).as_posix()]={'visible_bounds':im.getchannel('A').getbbox(),'colours':len(visible)}
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths+list(SOURCE.glob('*.png'))+list(DATA.glob('*.tres'))}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Shared body/outfit, two heads, expressions, animation, conditions, separate light masks, six resources and two OpenRaster masters exported.')

if __name__=='__main__':main()
