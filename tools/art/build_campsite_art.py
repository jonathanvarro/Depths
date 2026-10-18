"""Export the camp artwork without repainting generated masters."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'art/source/campsite-v1'
OUT = ROOT/'art/camp/cave-camp-v1'
REVIEW = ROOT/'art/concepts/campsite-v1'
SITES = ['supplies','treatment','cave','rest','smith','fire']
NPCS = ['merchant','apprentice','nurse']

def pixels(im):
    return im.get_flattened_data() if hasattr(im,'get_flattened_data') else im.getdata()

def reduce(im, count, opaque=False):
    alpha = im.getchannel('A').point(lambda a:255 if a>=96 else 0)
    samples = [p[:3] for p in pixels(im) if p[3]>=96]
    strip=Image.new('RGB',(len(samples),1)); strip.putdata(samples)
    pal=strip.quantize(colors=count,dither=Image.Dither.NONE)
    result=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(255 if opaque else alpha)
    return result

def font(size):
    result=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),size)
    try: result.set_variation_by_axes([400 if a['name']==b'Weight' else a['default'] for a in result.get_variation_axes()])
    except OSError: pass
    return result

def main():
    OUT.mkdir(parents=True,exist_ok=True); REVIEW.mkdir(parents=True,exist_ok=True)
    report={'issue':78,'assets':{},'failures':[]}
    images={}
    for name in SITES+NPCS:
        master=Image.open(SOURCE/(name+'.png')).convert('RGBA')
        alpha=master.getchannel('A').point(lambda a:255 if a>=96 else 0)
        bounds=alpha.getbbox(); assert bounds,name
        crop=master.crop(bounds)
        if name in SITES:
            size=(256,192); limit=(224,164); pivot=(128,184); count=40
        else:
            size=(192,192); limit=(184,184); pivot=(96,188); count=48
        crop.thumbnail(limit,Image.Resampling.NEAREST)
        offset=(pivot[0]-crop.width//2,pivot[1]+1-crop.height)
        frame=Image.new('RGBA',size); frame.paste(crop,offset)
        frame=reduce(frame,count)
        b=frame.getchannel('A').getbbox()
        assert b and b[0]>0 and b[1]>0 and b[2]<size[0] and b[3]==pivot[1]+1,(name,b)
        assert set(pixels(frame.getchannel('A')))=={0,255},name
        used=len({p[:3] for p in pixels(frame) if p[3]})
        assert used<=count
        frame.save(OUT/(name+'.png')); images[name]=frame
        report['assets'][name]={'canvas':size,'source_bounds':bounds,'offset':offset,'pivot':pivot,'visible_bounds':b,'visible_colours':used,'colour_limit':count}
    background=Image.open(SOURCE/'clearing.png').convert('RGBA')
    assert min(pixels(background.getchannel('A')))==255,'Background must be opaque'
    background=ImageOps.fit(background,(640,360),method=Image.Resampling.NEAREST)
    background=reduce(background,48,opaque=True)
    background.save(OUT/'clearing.png')
    report['assets']['clearing']={'canvas':[640,360],'visible_colours':len(set(pixels(background))),'colour_limit':48,'opaque':True}
    assert report['assets']['clearing']['visible_colours']<=48
    for sheet,names,cell,cols in [('sites',SITES,(256,224),3),('npcs',NPCS,(256,232),3)]:
        board=Image.new('RGBA',(cell[0]*cols,cell[1]*((len(names)+cols-1)//cols)),'#202624')
        draw=ImageDraw.Draw(board)
        for i,name in enumerate(names):
            x=(i%cols)*cell[0];y=(i//cols)*cell[1]
            im=images[name]
            board.alpha_composite(im,(x+(cell[0]-im.width)//2,y+28))
            draw.text((x+cell[0]//2,y+4),name.replace('rest','Your tent').replace('supplies','Merchant').title(),font=font(19),fill='#e5d9bf',anchor='mt')
        board.convert('RGB').save(REVIEW/(sheet+'.png'))
    paths=list(SOURCE.glob('*.png'))+list(OUT.glob('*.png'))
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Six site layers, three NPC portraits and clearing pass native size, alpha, palette, bounds and hash checks.')

if __name__=='__main__': main()
