"""Export registered Mara art; retain generated masters and the original live art."""
from pathlib import Path
from PIL import Image,ImageChops,ImageDraw
import hashlib,importlib.util,json,sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('portrait_export',ROOT/'tools/art/build_recruit_portraits.py')
kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
SOURCE=ROOT/'art/source/mara-neutral-v1'
OUT=ROOT/'art/portraits/mara-neutral-v1'
REVIEW=ROOT/'art/concepts/mara-neutral-v1'
EYES=(80,55,141,85);MOUTH=(92,93,128,112)

def load(name):return Image.open(SOURCE/(name+'.png')).convert('RGBA')
def registered(im):return im.resize((192,192),Image.Resampling.NEAREST)
def cells(name,cols,rows):
    im=load(name)
    return [registered(im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))) for y in range(rows) for x in range(cols)]
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()

def resource(underlayer=False):
    names=['base','eyes-neutral','mouth-neutral','tunic','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round']+kit.CONDITIONS
    names+=['shadow-underlayer' if underlayer else 'shadow-tunic','highlight-underlayer' if underlayer else 'highlight-tunic']
    lines=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','',
        '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]',
        '[ext_resource type="Texture2D" path="res://art/concepts/portraits/mara-layered-v1/background.png" id="background"]']
    lines+=['[ext_resource type="Texture2D" path="'+uri(OUT/(n+'.png'))+'" id="'+str(i)+'"]' for i,n in enumerate(names)]
    lines+=['','[resource]','script = ExtResource("script")','background = ExtResource("background")','body = ExtResource("0")','eyes = ExtResource("1")','mouth = ExtResource("2")']
    if not underlayer:lines+=['clothing = Array[Texture2D]([ExtResource("3")])']
    lines+=['conditions = {'+', '.join('"'+n+'": ExtResource("'+str(i+9)+'")' for i,n in enumerate(kit.CONDITIONS))+'}',
        'blink_frames = Array[Texture2D]([ExtResource("4"), ExtResource("5")])',
        'talk_frames = Array[Texture2D]([ExtResource("6"), ExtResource("7"), ExtResource("8")])',
        'light_shadow = ExtResource("13")','light_highlight = ExtResource("14")']
    p=OUT/'underlayer.tres' if underlayer else ROOT/'data/portraits/mara.tres'
    p.write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')

def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    base=registered(load('base-master'));tunic=registered(load('tunic-master'))
    pal=kit.make_palette([base,tunic],48)
    base=kit.quantize(base,pal);tunic=kit.quantize(tunic,pal)
    # Original artwork is fixed to the full canvas. No independent trimming.
    base.save(OUT/'base.png');tunic.save(OUT/'tunic.png')
    kit.patch(base,EYES).save(OUT/'eyes-neutral.png');kit.patch(base,MOUTH).save(OUT/'mouth-neutral.png')
    report={'issue':36,'canvas':[192,192],'master_transform':'full canvas nearest to 192; origin 0,0',
        'eyes_region':EYES,'mouth_region':MOUTH,'registration':{},'failures':[]}
    for name,im in zip(['eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round'],cells('faces',3,2)):
        im,shift=kit.align_cell(im,base)
        report['registration'][name]={'unchanged_nose_ear_chin_translation':shift}
        patch=kit.patch(kit.quantize(im,pal),EYES if name.startswith('eyes') else MOUTH)
        patch.putalpha(ImageChops.multiply(patch.getchannel('A'),kit.alpha(base)))
        patch.save(OUT/(name+'.png'))
    merged=kit.composite([base,tunic]);merged.save(OUT/'preview.png')
    clip=kit.alpha(merged)
    for name,im in zip(kit.CONDITIONS,cells('conditions',2,2)):
        if name=='pallor':im=registered(load('pallor'))
        if name=='bandage':
            b=kit.alpha(im).getbbox();mark=im.crop(b);mark.thumbnail((66,12),Image.Resampling.NEAREST)
            im=kit.blank();im.paste(mark,(108-mark.width//2,46))
            report['registration']['bandage']={'source_bounds':b,'top':46,'max_size':[66,12]}
        authored_alpha=im.getchannel('A')
        im=kit.quantize(im,kit.make_palette([im],8))
        channel=ImageChops.multiply(authored_alpha if name=='pallor' else im.getchannel('A'),clip)
        if name in ['dirt','pallor']:channel=channel.point(lambda a:round(a*(0.4 if name=='dirt' else 0.28)))
        if name=='dirt':im=Image.new('RGBA',kit.SIZE,(79,59,39,0))
        if name=='pallor':
            skin=Image.new('L',kit.SIZE)
            skin.putdata([255 if p[3] and 36<y<145 and p[0]>35 and 18<p[0]-p[2] and 1.12<p[0]/max(1,p[1])<1.9 and p[1]/max(1,p[2])>1.12 else 0 for y in range(192) for p in [base.getpixel((x,y)) for x in range(192)]])
            channel=ImageChops.multiply(channel,skin)
            im=Image.new('RGBA',kit.SIZE,(187,192,155,0))
        im.putalpha(channel);assert channel.getbbox(),name;im.save(OUT/(name+'.png'))
    for j,source in enumerate(cells('lighting',2,2)):
        highlight=j%2==1;outfit=j>=2
        gray=source.convert('L')
        coverage=gray.point((lambda v:max(0,min(255,round((v-110)*255/145)))) if highlight else (lambda v:255-v))
        coverage=ImageChops.multiply(coverage,source.getchannel('A'))
        coverage=coverage.resize((32,32),Image.Resampling.BOX).resize(kit.SIZE,Image.Resampling.NEAREST)
        coverage=ImageChops.multiply(coverage,clip if outfit else kit.alpha(base))
        im=Image.new('RGBA',kit.SIZE,(255,255,255,0) if highlight else (0,0,0,0));im.putalpha(coverage)
        im.save(OUT/(('highlight' if highlight else 'shadow')+('-tunic' if outfit else '-underlayer')+'.png'))
    resource();resource(True)
    kit.SOURCE=SOURCE
    ora_layers=[('Character - neutral underlayer',OUT/'base.png',True),('Eyes - neutral',OUT/'eyes-neutral.png',True),
        ('Mouth - neutral',OUT/'mouth-neutral.png',True),('Clothing - neutral tunic',OUT/'tunic.png',True)]
    ora_layers += [(n,OUT/(n+'.png'),False) for n in ['eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round']+kit.CONDITIONS+['shadow-underlayer','highlight-underlayer','shadow-tunic','highlight-tunic']]
    kit.save_ora('mara-neutral',ora_layers,OUT/'preview.png')
    # Preview fallback follows the new neutral composition, without changing hero stats.
    p=ROOT/'data/companions/mara.tres'
    p.write_text(p.read_text().replace('res://art/concepts/portraits/mara-base-192-v2.png',uri(OUT/'preview.png')),encoding='utf-8',newline='\n')
    frames=[]
    for eyes,mouth in [('eyes-neutral','mouth-neutral'),('eyes-half','mouth-neutral'),('eyes-closed','mouth-neutral'),('eyes-neutral','mouth-small'),('eyes-neutral','mouth-open'),('eyes-neutral','mouth-round')]:
        frames.append(kit.composite([base,Image.open(OUT/(eyes+'.png')).convert('RGBA'),Image.open(OUT/(mouth+'.png')).convert('RGBA'),tunic]))
    for bg,colour in [('dark','#1b2420'),('light','#d6cbb4')]:
        board=Image.new('RGBA',(1152,344),colour)
        for i,im in enumerate(frames):board.alpha_composite(im,(i*192,0));board.alpha_composite(im.resize((96,96),Image.Resampling.NEAREST),(i*192+48,226))
        board.convert('RGB').save(REVIEW/('frames-'+bg+'.png'))
    preview=[]
    for condition in kit.CONDITIONS:preview.append(kit.composite([merged,Image.open(OUT/(condition+'.png')).convert('RGBA')]))
    board=Image.new('RGBA',(768,288),'#1b2420')
    for i,im in enumerate(preview):board.alpha_composite(im,(i*192,0));board.alpha_composite(im.resize((96,96),Image.Resampling.NEAREST),(i*192+48,192))
    board.convert('RGB').save(REVIEW/'conditions.png')
    report['assets']={}
    for p in OUT.glob('*.png'):
        im=Image.open(p).convert('RGBA');assert im.size==(192,192),p
        report['assets'][p.name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'alpha_bounds':im.getchannel('A').getbbox(),'rgb_colours':len({c[:3] for c in kit.pixels(im) if c[3]})}
    report['source_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.png')}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Mara neutral, five frames, four conditions and four light passes exported and connected.')

if __name__=='__main__':main()
