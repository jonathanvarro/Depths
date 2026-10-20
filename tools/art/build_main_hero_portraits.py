"""Full-canvas, neutral Corin/Alwen components from preserved ImageGen masters."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import hashlib, json, sys
import build_recruit_portraits as kit

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/campaign-v1'
OUT=ROOT/'art/portraits/main-heroes-v1'
REVIEW=ROOT/'art/concepts/campaign-v1'
CONFIG={
    'corin':{'eyes':(82,57,136,77),'mouth':(93,84,125,101),'anchors':[(105,76,118,84),(58,66,67,79),(98,104,116,111)],'bandage':(108,44,40,10),
             'skin':[(72,38),(122,37),(134,68),(122,108),(120,125),(104,136),(78,121),(65,97),(59,62)]},
    'alwen':{'eyes':(84,56,140,78),'mouth':(98,87,129,104),'anchors':[(109,76,122,86),(71,80,79,90),(108,107,121,113)],'bandage':(121,47,27,8),
             'skin':[(93,47),(132,49),(136,85),(123,111),(116,132),(87,126),(90,107),(75,85),(82,64)]}}

def load(n):return Image.open(SOURCE/(n+'.png')).convert('RGBA')
def uri(p):return 'res://'+p.relative_to(ROOT).as_posix()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def cells(name,cols,rows):
    im=load(name)
    return [im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows))).resize(kit.SIZE,Image.Resampling.NEAREST) for y in range(rows) for x in range(cols)]
def align(im,base,anchors):
    best=None
    for dy in range(-4,5):
        for dx in range(-4,5):
            moved=kit.blank();moved.paste(im,(dx,dy));score=0
            for region in anchors:
                a=list(kit.pixels(moved.convert('L').crop(region)));b=list(kit.pixels(base.convert('L').crop(region)))
                am=sum(a)/len(a);bm=sum(b)/len(b)
                score+=sum(abs((x-am)-(y-bm)) for x,y in zip(a,b))/len(a)
            candidate=(score,abs(dx)+abs(dy),dx,dy,moved)
            if best is None or candidate[:2]<best[:2]:best=candidate
    return best[4],list(best[2:4])

def main():
    report={'issues':[103,96],'canvas':[192,192],'reference_transform':'full master -> 184px with (4,4) padding; derived cells remain full 192px','characters':{},'failures':[]}
    for name,cfg in CONFIG.items():
        folder=OUT/name;folder.mkdir(parents=True,exist_ok=True)
        base=kit.register(load(name+'-base'));pal=kit.make_palette([base],48);base=kit.quantize(base,pal)
        assert base.tobytes()==load(name+'-reference').tobytes()
        clip=kit.alpha(base)
        base.paste((0,0,0,0),(0,0,192,192),ImageChops.invert(clip))
        # Lossless registered component split: head/neck and coordinated body.
        head_mask=Image.new('L',kit.SIZE);d=ImageDraw.Draw(head_mask);d.rectangle((0,0,191,111),fill=255)
        d.polygon([(68,106),(127,106),(124,127),(105,142),(80,128)],fill=255)
        head=base.copy();head.putalpha(ImageChops.multiply(clip,head_mask))
        body=base.copy();body.putalpha(ImageChops.multiply(clip,ImageChops.invert(head_mask)))
        head.save(folder/'head.png');body.save(folder/'body.png')
        neutral=kit.composite([body,head]);assert neutral.tobytes()==base.tobytes()
        neutral.save(folder/'preview.png')
        kit.patch(base,cfg['eyes']).save(folder/'eyes-neutral.png');kit.patch(base,cfg['mouth']).save(folder/'mouth-neutral.png')
        record={'eyes_region':cfg['eyes'],'mouth_region':cfg['mouth'],'expression_registration':{},'base_visible_colours':len({p[:3] for p in kit.pixels(base) if p[3]}),'head_body_compose_exactly':True}
        for frame,im in zip(['eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round'],cells(name+'-faces',3,2)):
            im,offset=align(im,base,cfg['anchors']);im=kit.quantize(im,pal)
            patch=kit.patch(im,cfg['eyes'] if frame.startswith('eyes') else cfg['mouth'])
            patch.putalpha(ImageChops.multiply(patch.getchannel('A'),clip));patch.save(folder/(frame+'.png'))
            record['expression_registration'][frame]={'anchor_translation':offset,'only_replaces':cfg['eyes'] if frame.startswith('eyes') else cfg['mouth']}
        skin=Image.new('L',kit.SIZE);ImageDraw.Draw(skin).polygon(cfg['skin'],fill=255)
        material=Image.new('L',kit.SIZE);material.putdata([255 if p[3] and p[0]>80 and p[1]>50 and p[2]>25 and p[0]-p[2]>22 and 1.12<p[0]/max(1,p[1])<1.65 and p[1]/max(1,p[2])>1.10 else 0 for p in kit.pixels(base)])
        skin=ImageChops.multiply(skin,material)
        for condition,im in zip(kit.CONDITIONS,cells(name+'-conditions',2,2)):
            if condition=='bandage':
                bounds=kit.alpha(im).getbbox();mark=im.crop(bounds)
                cx,top,w,h=cfg['bandage'];mark.thumbnail((w,h),Image.Resampling.NEAREST)
                im=kit.blank();im.paste(mark,(cx-mark.width//2,top));record['bandage_registration']={'source_bounds':bounds,'centre_x':cx,'top':top,'max_size':[w,h]}
            if condition=='pallor':
                coverage=ImageChops.multiply(im.getchannel('A'),skin).point(lambda a:round(a*.25))
                im=Image.new('RGBA',kit.SIZE,(183,188,155,0));im.putalpha(coverage)
            else:
                im=kit.quantize(im,kit.make_palette([im],8))
                channel=ImageChops.multiply(im.getchannel('A'),clip)
                if condition=='dirt':channel=channel.point(lambda a:round(a*.36))
                im.putalpha(channel)
            assert im.getchannel('A').getbbox(),(name,condition)
            assert ImageChops.multiply(im.getchannel('A'),ImageChops.invert(clip)).getbbox() is None
            im.save(folder/(condition+'.png'))
        masks=cells(name+'-lighting',2,2)
        for i,kind in enumerate(['shadow','highlight']):
            raw=masks[i];gray=raw.convert('L')
            coverage=gray.point((lambda v:255-v) if i==0 else (lambda v:max(0,min(255,round((v-110)*255/145)))))
            coverage=ImageChops.multiply(coverage,raw.getchannel('A'))
            coverage=coverage.resize((32,32),Image.Resampling.BOX).resize(kit.SIZE,Image.Resampling.NEAREST)
            coverage=ImageChops.multiply(coverage,clip)
            im=Image.new('RGBA',kit.SIZE,(0,0,0,0) if i==0 else (255,255,255,0));im.putalpha(coverage);im.save(folder/(kind+'.png'))
            assert coverage.getbbox()
        names=['body','head','eyes-neutral','mouth-neutral','eyes-half','eyes-closed','mouth-small','mouth-open','mouth-round']+kit.CONDITIONS+['shadow','highlight']
        ext=['[gd_resource type="Resource" script_class="PortraitSet" format=3]','', '[ext_resource type="Script" path="res://scripts/portrait_set.gd" id="script"]','[ext_resource type="Texture2D" path="res://art/concepts/portraits/mara-layered-v1/background.png" id="background"]']
        ext+=['[ext_resource type="Texture2D" path="'+uri(folder/(n+'.png'))+'" id="'+str(i)+'"]' for i,n in enumerate(names)]
        ext+=['','[resource]','script = ExtResource("script")','rig_kind = "Unique"','rig_family = &"unique-'+name+'-v1"','face_id = &"'+name+'"','background = ExtResource("background")','body = ExtResource("0")','head = ExtResource("1")','eyes = ExtResource("2")','mouth = ExtResource("3")',
              'blink_frames = Array[Texture2D]([ExtResource("4"),ExtResource("5")])','talk_frames = Array[Texture2D]([ExtResource("6"),ExtResource("7"),ExtResource("8")])',
              'conditions = {'+', '.join('"'+n+'": ExtResource("'+str(i+9)+'")' for i,n in enumerate(kit.CONDITIONS))+'}', 'light_shadow = ExtResource("13")','light_highlight = ExtResource("14")']
        write(ROOT/'data/portraits'/(name+'.tres'),'\n'.join(ext)+'\n')
        layers=[('Neutral coordinated body',folder/'body.png',True),('Neutral head and neck',folder/'head.png',True),('Eyes - neutral',folder/'eyes-neutral.png',True),('Mouth - neutral',folder/'mouth-neutral.png',True)]
        layers += [(n,folder/(n+'.png'),False) for n in names[4:]]
        kit.SOURCE=SOURCE;kit.save_ora(name,layers,folder/'preview.png')
        if '--wire' in sys.argv:
            p=ROOT/'data/companions'/(name+'.tres');s=p.read_text(encoding='utf-8')
            import re
            s=re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="2"\])',lambda m:m[1]+uri(folder/'preview.png')+m[2],s)
            s=re.sub(r'(\[ext_resource type="Resource" path=")[^"]+(" id="3"\])',lambda m:m[1]+'res://data/portraits/'+name+'.tres'+m[2],s)
            write(p,s)
        frames=[]
        for eye,mouth in [('eyes-neutral','mouth-neutral'),('eyes-half','mouth-neutral'),('eyes-closed','mouth-neutral'),('eyes-neutral','mouth-small'),('eyes-neutral','mouth-open'),('eyes-neutral','mouth-round')]:
            frames.append(kit.composite([body,head,Image.open(folder/(eye+'.png')).convert('RGBA'),Image.open(folder/(mouth+'.png')).convert('RGBA')]))
        board=Image.new('RGBA',(192*6,192),'#1b2420')
        for i,frame in enumerate(frames):board.alpha_composite(frame,(i*192,0))
        board.convert('RGB').save(REVIEW/(name+'-expressions.png'))
        record['sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in folder.glob('*.png')}
        report['characters'][name]=record
    write(REVIEW/'portrait-validation.json',json.dumps(report,indent=2)+'\n')
    print('Exported two registered main-hero portrait sets, expressions, conditions, light masks and ORA sources.')

if __name__=='__main__':main()
