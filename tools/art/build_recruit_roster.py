"""Expand the validated recruit kit; preserve its original body/outfit and faces."""
from pathlib import Path
from PIL import Image,ImageChops,ImageDraw
import importlib.util
import hashlib,json

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('recruit_kit_export',ROOT/'tools/art/build_recruit_portraits.py')
kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
SOURCE=ROOT/'art/source/recruit-roster-v1'
OUT=ROOT/'art/portraits/recruit-roster-v1'
DATA=ROOT/'data/portraits/recruit-roster-v1'
REVIEW=ROOT/'art/concepts/recruit-roster-v1'
SHARED=ROOT/'art/portraits/recruit-kit-v1/shared'
PEOPLE=['warden-b','warden-c','scout-b','scout-c','brawler-a','brawler-b','brawler-c']
ORDER=['warden-a','scout-a','brawler-a','warden-b','scout-b','brawler-b','warden-c','scout-c','brawler-c']
EYES=(73,51,142,82)
MOUTH=(82,89,132,112)
kit.SOURCE=SOURCE
kit.EYES=EYES;kit.MOUTH=MOUTH

def uri(path):return 'res://'+path.relative_to(ROOT).as_posix()

def register_face(im,base):
    # Some generated atlases enlarge a head inside otherwise fixed cells.
    # Fit its unchanged hair/ear silhouette with a UNIFORM scale/translation,
    # then refine on unchanged nose/ear/chin pixels. Never fit eyes or lips.
    guide=(0,0,192,105)
    reference=kit.alpha(base).crop(guide).getbbox()
    bounds=kit.alpha(im).crop(guide).getbbox()
    scale=(reference[2]-reference[0])/(bounds[2]-bounds[0])
    size=round(192*scale)
    offset=(round(reference[0]-bounds[0]*scale),round(reference[1]-bounds[1]*scale))
    moved=kit.blank();moved.paste(im.resize((size,size),Image.Resampling.NEAREST),offset)
    result,shift=kit.align_cell(moved,base)
    return result,{'uniform_scale':scale,'scaled_canvas':[size,size],
        'offset':offset,'refinement':shift,'source_head_bounds':bounds,'target_head_bounds':reference}

def resources(id):
    for emotion in ['neutral','worried','exhausted']:
        names=[SHARED/'body.png',OUT/id/'head.png',OUT/id/('eyes-'+emotion+'.png'),OUT/id/('mouth-'+emotion+'.png'),SHARED/'jerkin.png']
        if emotion=='neutral':names += [OUT/id/(n+'.png') for n in ['eyes-half','eyes-closed','mouth-small','mouth-open']]
        names += [OUT/id/(n+'.png') for n in kit.CONDITIONS]
        lines=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','',
            '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]']
        lines += ['[ext_resource type="Texture2D" path="'+uri(p)+'" id="'+str(i)+'"]' for i,p in enumerate(names)]
        lines += ['','[resource]','script = ExtResource("script")','body = ExtResource("0")','head = ExtResource("1")',
            'eyes = ExtResource("2")','mouth = ExtResource("3")','clothing = Array[Texture2D]([ExtResource("4")])']
        start=9 if emotion=='neutral' else 5
        lines.append('conditions = {'+', '.join('"'+n+'": ExtResource("'+str(start+i)+'")' for i,n in enumerate(kit.CONDITIONS))+'}')
        if emotion=='neutral':lines += ['blink_frames = Array[Texture2D]([ExtResource("5"), ExtResource("6")])','talk_frames = Array[Texture2D]([ExtResource("7"), ExtResource("8")])']
        kit.add_lighting(lines,uri(OUT/id))
        (DATA/(id+('' if emotion=='neutral' else '-'+emotion)+'.tres')).write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')

def main():
    for folder in [OUT,DATA,REVIEW]:folder.mkdir(parents=True,exist_ok=True)
    body=Image.open(SHARED/'body.png').convert('RGBA')
    outfit=Image.open(SHARED/'jerkin.png').convert('RGBA')
    original=kit.register(Image.open(ROOT/'art/source/recruit-kit-v1/master-a.png').convert('RGBA'))
    socket=ImageChops.subtract(kit.alpha(original),body.getchannel('A'))
    report={'issue':82,'new_portraits':7,'total_portraits':9,'canvas':[192,192],
        'master_transform':{'resize_full_square':[184,184],'offset':[4,4]},
        'eye_region':EYES,'mouth_region':MOUTH,'registration':{},'assets':{},'failures':[]}
    report['lighting_coverage']={'shadow':'alpha * (255-luminance)/255',
        'highlight':'alpha * clamp((luminance-110)/145,0,1)',
        'cluster_grid':[32,32],'clip':'composited silhouette'}
    catalog=json.loads((ROOT/'art/portraits/recruit-kit-v1/catalog.json').read_text())
    catalog['issue']=82
    for id in PEOPLE:
        dest=OUT/id;dest.mkdir(parents=True,exist_ok=True)
        base=kit.register(kit.load(id+'-master'))
        pal=kit.make_palette([base],48);base=kit.quantize(base,pal)
        head=base.copy();mask=kit.alpha(head)
        for y in range(113,192):
            for x in range(192):mask.putpixel((x,y),socket.getpixel((x,y)))
        head.putalpha(mask);head.save(dest/'head.png')
        assert not mask.crop((0,144,192,192)).getbbox(),id+' hidden torso'
        eyes=kit.patch(base,EYES);mouth=kit.patch(base,MOUTH)
        eyes.save(dest/'eyes-neutral.png');mouth.save(dest/'mouth-neutral.png')
        frames=[];shifts=[]
        for im in kit.cells(id+'-faces',3,2):
            registered,shift=register_face(im,base)
            registered=kit.quantize(registered,pal)
            registered.putalpha(ImageChops.multiply(registered.getchannel('A'),kit.alpha(base)))
            frames.append(registered);shifts.append(shift)
        report['registration'][id]={'frames':shifts}
        exports={'eyes-half':kit.patch(frames[0],EYES),'eyes-closed':kit.patch(frames[1],EYES),
            'mouth-small':kit.patch(frames[2],MOUTH),'mouth-open':kit.patch(frames[3],MOUTH),
            'eyes-worried':kit.patch(frames[4],EYES),'mouth-worried':kit.patch(frames[4],MOUTH),
            'eyes-exhausted':kit.patch(frames[5],EYES),'mouth-exhausted':kit.patch(frames[5],MOUTH)}
        for name,im in exports.items():
            box=EYES if name.startswith('eyes-') else MOUTH
            region=Image.new('L',kit.SIZE);ImageDraw.Draw(region).rectangle((box[0],box[1],box[2]-1,box[3]-1),fill=255)
            assert not ImageChops.subtract(im.getchannel('A'),region).getbbox(),(id,name,'outside feature region')
            assert not ImageChops.subtract(im.getchannel('A'),kit.alpha(base)).getbbox(),(id,name,'outside head silhouette')
            im.save(dest/(name+'.png'))
        merged=kit.composite([body,head,eyes,mouth,outfit]);merged.save(dest/'preview.png')
        clip=kit.alpha(merged)
        for condition,im in zip(kit.CONDITIONS,kit.cells(id+'-conditions',2,2)):
            if condition=='bandage':
                b=kit.alpha(im).getbbox();assert b,id
                mark=im.crop(b);mark.thumbnail((72,14),Image.Resampling.NEAREST)
                im=kit.blank();im.paste(mark,(101-mark.width//2,45))
                report['registration'][id]['bandage']={'source_bounds':b,'top':45,'max_size':[72,14]}
            im=kit.quantize(im,kit.make_palette([im],8))
            channel=ImageChops.multiply(im.getchannel('A'),clip)
            if condition in ['dirt','pallor']:channel=channel.point(lambda a:round(a*(0.4 if condition=='dirt' else 0.42)))
            if condition=='dirt':im=Image.new('RGBA',kit.SIZE,(79,59,39,0))
            if condition=='pallor':
                skin=Image.new('L',kit.SIZE)
                skin.putdata([255 if p[3] and 36<y<144 and p[0]>35 and p[0]-p[2]>18 and p[0]/max(1,p[1])>1.12
                    and p[0]/max(1,p[1])<1.9 and p[1]/max(1,p[2])>1.12 else 0
                    for y in range(192) for p in [base.getpixel((x,y)) for x in range(192)]])
                channel=ImageChops.multiply(channel,skin)
            im.putalpha(channel);assert channel.getbbox(),(id,condition)
            im.save(dest/(condition+'.png'))
        for i,name in enumerate(['shadow-left','highlight-left']):
            source=kit.cells(id+'-lighting',2,2)[i]
            gray=source.convert('L')
            # Black shade carries its strength in alpha; pure black must not
            # disappear merely because its luminance is zero.
            coverage=gray.point((lambda v:255-v) if i==0 else (lambda v:max(0,min(255,round((v-110)*255/145)))))
            coverage=ImageChops.multiply(coverage,source.getchannel('A'))
            coverage=coverage.resize((32,32),Image.Resampling.BOX).resize(kit.SIZE,Image.Resampling.NEAREST)
            coverage=ImageChops.multiply(coverage,clip)
            light=Image.new('RGBA',kit.SIZE,(0,0,0,0) if i==0 else (255,255,255,0));light.putalpha(coverage)
            light.save(dest/(name+'.png'))
        resources(id)
        layers=[('Body – shared linen',SHARED/'body.png',True),('Head',dest/'head.png',True),
            ('Eyes – neutral',dest/'eyes-neutral.png',True),('Mouth – neutral',dest/'mouth-neutral.png',True),
            ('Clothing – shared jerkin',SHARED/'jerkin.png',True)]
        layers += [(name,dest/(name+'.png'),False) for name in list(exports)+kit.CONDITIONS+['shadow-left','highlight-left']]
        kit.save_ora(id,layers,dest/'preview.png')
        catalog['portraits'].append({'id':id,'role':id.split('-')[0].title(),'portrait':uri(dest/'preview.png'),
            'portrait_set':uri(DATA/(id+'.tres')),'expressions':['neutral','worried','exhausted'],
            'shadow':uri(dest/'shadow-left.png'),'highlight':uri(dest/'highlight-left.png')})
    catalog['portraits'].sort(key=lambda e:ORDER.index(e['id']))
    catalog['by_role']={r:[e['id'] for e in catalog['portraits'] if e['role']==r] for r in ['Warden','Scout','Brawler']}
    assert all(len(ids)==3 for ids in catalog['by_role'].values())
    (OUT/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    board=Image.new('RGBA',(648,680),'#202624');draw=ImageDraw.Draw(board)
    card=Image.new('RGBA',(360,368),'#202624');small_draw=ImageDraw.Draw(card)
    for i,e in enumerate(catalog['portraits']):
        im=Image.open(ROOT/e['portrait'].replace('res://','')).convert('RGBA')
        x=(i%3)*216;y=(i//3)*216+28
        board.alpha_composite(im,(x+12,y+20))
        draw.text((x+108,y+2),e['id'].title(),font=kit.font(18),fill='#e5d9bf',anchor='mt')
        x=(i%3)*120;y=(i//3)*120
        card.alpha_composite(im.resize((96,96),Image.Resampling.NEAREST),(x+12,y+22))
        small_draw.text((x+60,y+2),e['id'],font=kit.font(14),fill='#e5d9bf',anchor='mt')
    board.convert('RGB').save(REVIEW/'roster.png');card.convert('RGB').save(REVIEW/'cards-96.png')
    sequence=[('neutral',600),('half',40),('closed',50),('half',50),('neutral',500),('small',90),('open',90),('neutral',90),('small',90),('open',90),('neutral',700)]
    movie=[]
    for state,duration in sequence:
        frame=Image.new('RGBA',(432,480),'#202624');draw=ImageDraw.Draw(frame)
        for i,e in enumerate(catalog['portraits']):
            folder=(ROOT/e['portrait'].replace('res://','')).parent
            eye='eyes-'+state if state in ['half','closed'] else 'eyes-neutral'
            mouth='mouth-'+state if state in ['small','open'] else 'mouth-neutral'
            im=kit.composite([body,Image.open(folder/'head.png').convert('RGBA'),
                Image.open(folder/(eye+'.png')).convert('RGBA'),Image.open(folder/(mouth+'.png')).convert('RGBA'),outfit])
            x=(i%3)*144;y=(i//3)*160
            frame.alpha_composite(im.resize((128,128),Image.Resampling.NEAREST),(x+8,y+24))
            draw.text((x+72,y+3),e['id'],font=kit.font(15),fill='#e5d9bf',anchor='mt')
        movie.append(frame.convert('RGB'))
    movie[0].save(REVIEW/'animation-preview.gif',save_all=True,append_images=movie[1:],duration=[s[1] for s in sequence],loop=0,disposal=2)
    paths=list(OUT.rglob('*.png'))
    for path in paths:
        im=Image.open(path).convert('RGBA')
        assert im.size==kit.SIZE and im.getpixel((0,0))[3]==0,path
        assert im.getchannel('A').getbbox(),path
        report['assets'][path.relative_to(OUT).as_posix()]={'bounds':im.getchannel('A').getbbox(),'colours':len({p[:3] for p in kit.pixels(im) if p[3]})}
    paths+=list(SOURCE.glob('*.png'))+list(DATA.glob('*.tres'))+[SHARED/'body.png',SHARED/'jerkin.png']
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Seven new recruits exported; nine total, three per role. Original body/outfit and two faces preserved.')

if __name__=='__main__':main()
