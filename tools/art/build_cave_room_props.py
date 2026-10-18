"""Normalize generated room-event props; keep source masters and game rules intact."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'art/source/cave-room-props-v1'
OUT = ROOT/'art/props/cave-room-props-v1'
REVIEW = ROOT/'art/concepts/cave-room-props-v1'


def pixels(image):
    return image.get_flattened_data() if hasattr(image,'get_flattened_data') else image.getdata()


def mask(image):
    return image.getchannel('A').point(lambda a: 255 if a >= 96 else 0)


def palette_for(images, count):
    samples = [p[:3] for image in images for p in pixels(image) if p[3] >= 96]
    strip = Image.new('RGB',(len(samples),1)); strip.putdata(samples)
    return strip.quantize(colors=count,dither=Image.Dither.NONE)


def quantize(image,palette):
    result = image.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(mask(image))
    return result


def load(name):
    return Image.open(SOURCE/(name+'.png')).convert('RGBA')


def main():
    for p in [OUT,REVIEW]: p.mkdir(parents=True,exist_ok=True)
    images, registration = {}, {}
    pack_sources = [load('pack'),load('pack-searched')]
    assert all(p.width == p.height for p in pack_sources)
    pack_sources = [p.resize((1024,1024),Image.Resampling.NEAREST) for p in pack_sources]
    bounds = [mask(p).getbbox() for p in pack_sources]
    common_scale = min(104/max(b[2]-b[0] for b in bounds),104/max(b[3]-b[1] for b in bounds))
    pack_frames = []
    for name,image,b in zip(['abandoned-pack','abandoned-pack-searched'],pack_sources,bounds):
        lower = mask(image).crop((0,round(b[3]-(b[3]-b[1])*.35),1024,1024)).getbbox()
        root_x = (lower[0]+lower[2])/2
        resized = image.resize((round(1024*common_scale),round(1024*common_scale)),Image.Resampling.NEAREST)
        frame = Image.new('RGBA',(128,128))
        offset = (64-round(root_x*common_scale),121-round(b[3]*common_scale))
        frame.paste(resized,offset)
        pack_frames.append(frame)
        registration[name] = {'source_bounds':b,'root_x':root_x,'scale':common_scale,'offset':offset,'pivot':[64,120]}
    palette = palette_for(pack_frames,24)
    for name,frame in zip(['abandoned-pack','abandoned-pack-searched'],pack_frames): images[name]=quantize(frame,palette)
    for source,name,max_size,colours in [('idol','pale-idol',(88,104),16),('cold-camp','cold-camp',(112,64),24)]:
        image = load(source); b=mask(image).getbbox(); assert b
        image=image.crop(b); image.thumbnail(max_size,Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(128,128)); offset=(64-image.width//2,121-image.height); frame.paste(image,offset)
        images[name]=quantize(frame,palette_for([frame],colours))
        registration[name]={'source_bounds':b,'offset':offset,'pivot':[64,120]}
    # A top-down floor texture uses a centre pivot, never a billboard floor contact.
    pool=load('pool'); b=mask(pool).getbbox(); assert b
    pool=pool.crop(b); pool.thumbnail((112,112),Image.Resampling.NEAREST)
    frame=Image.new('RGBA',(128,128)); offset=((128-pool.width)//2,(128-pool.height)//2); frame.paste(pool,offset)
    images['still-pool']=quantize(frame,palette_for([frame],24))
    registration['still-pool']={'source_bounds':b,'offset':offset,'pivot':[64,64],'orientation':'top-down, horizontal world plane'}
    report={'issue':75,'canvas':[128,128],'assets':[],'registration':registration,'failures':[]}
    for name,image in images.items():
        image.save(OUT/(name+'.png'))
        alpha=image.getchannel('A'); b=alpha.getbbox(); colours={p[:3] for p in pixels(image) if p[3]}
        assert b and b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,(name,b)
        assert set(pixels(alpha))=={0,255}
        assert len(colours)<=(16 if name=='pale-idol' else 24)
        if name!='still-pool': assert b[3]==121,(name,b)
        report['assets'].append({'file':name+'.png','bounds':b,'visible_colours':len(colours)})
    assert images['still-pool'].getpixel((64,64))[3]==255,'Pool water must not be a transparent hole'
    assert images['abandoned-pack'].tobytes()!=images['abandoned-pack-searched'].tobytes()
    pack_colours={p[:3] for name in ['abandoned-pack','abandoned-pack-searched'] for p in pixels(images[name]) if p[3]}
    assert len(pack_colours)<=24
    report['pack_shared_colours']=len(pack_colours)
    paths=list(SOURCE.glob('*.png'))+list(OUT.glob('*.png'))
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),19)
    try: font.set_variation_by_axes([400 if a['name']==b'Weight' else a['default'] for a in font.get_variation_axes()])
    except OSError: pass
    order=[('abandoned-pack','Abandoned pack'),('abandoned-pack-searched','Searched pack'),('pale-idol','Pale idol'),('still-pool','Still pool · top-down'),('cold-camp','Cold campsite')]
    for theme,bg in [('dark','#1b201f'),('light','#dfd5be')]:
        board=Image.new('RGBA',(768,560),bg); draw=ImageDraw.Draw(board)
        for i,(name,label) in enumerate(order):
            x=(i%3)*256; y=(i//3)*280
            board.alpha_composite(images[name].resize((256,256),Image.Resampling.NEAREST),(x,y+24))
            draw.text((x+128,y+8),label,fill='#e6dac1' if theme=='dark' else '#28251f',font=font,anchor='mt')
        board.convert('RGB').save(REVIEW/('overview.png' if theme=='dark' else 'light-background.png'))
    print('Five room prop exports pass canvas, alpha, palettes, registration and pool-water checks.')


if __name__=='__main__': main()
